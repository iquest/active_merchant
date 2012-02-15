require 'builder'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        class WebServices
          include PostsData
          include Common

          ENV_NAMESPACES = {
            "xmlns:xsi"     => "http://www.w3.org/2001/XMLSchema-instance",
            "xmlns:xsd"     => "http://www.w3.org/2001/XMLSchema",
            "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/"
          }

          TEST_URL = "https://test.3dsecure.gpwebpay.com/webservices/services/pgw"
          PRODUCTION_URL = "https://3dsecure.gpwebpay.com/webservices/services/pgw"

          ACTIONS = {
            :approve_reversal => "approveReversal",
            :deposit          => "deposit",
            :deposit_reversal => "depositReversal",
            :credit           => "credit",
            :credit_reversal  => "creditReversal",
            :close            => "orderClose",
            :delete           => "delete",
            :status           => "queryOrderState",
            :batch_close      => "batchClose"
          }

          def url
            ActiveMerchant::Billing::Base.integration_mode == :production ? PRODUCTION_URL : TEST_URL
          end

          [:approve_reversal, :deposit_reversal, :close, :delete, :status].each do |action|
            define_method(action) do |order|
              request = soap_request(action) do |xml|
                add_merchant_number(xml)
                add_order_number(xml, order)
                add_digest(xml, [order])
              end
              return commit(action, request)
            end
          end

          [:deposit, :credit].each do |action|
            define_method(action) do |order, amount|
              request = soap_request(action) do |xml|
                add_merchant_number(xml)
                add_order_number(xml, order)
                add_amount(xml, amount)
                add_digest(xml, [order, amount])
              end
              return commit(action, request)
            end
          end

          def credit_reversal(order, credit)
            request = soap_request(:credit_reversal) do |xml|
              add_merchant_number(xml)
              add_order_number(xml, order)
              add_credit_number(xml, credit)
              add_digest(xml, [order, credit])
            end
            return commit(:credit_reversal, request)
          end

          def batch_close
            request = soap_request(:batch_close) do |xml|
              add_merchant_number(xml)
              add_digest(xml)
            end
            return commit(:batch_close, request)
          end

          private

          def soap_request(action)
            xml = Builder::XmlMarkup.new :indent => 2
            xml.instruct!(:xml, :version => '1.0', :encoding => 'utf-8')
            xml.tag! "soapenv:Envelope", ENV_NAMESPACES do
              xml.tag! "soapenv:Body" do
                xml.tag! "ns1:#{ACTIONS[action]}", { "soapenv:encodingStyle" => "http://schemas.xmlsoap.org/soap/encoding/", "xmlns:ns1" => url } do
                  yield xml
                end
              end
            end
            xml.target!
          end

          def add_merchant_number(xml)
            xml.tag! "merchantNumber", { "xsi:type" => "xsd:string" }, ActiveMerchant::Billing::Integrations::GpWebpay.merchant_id
          end

          def add_order_number(xml, order)
            xml.tag! "orderNumber", { "xsi:type" => "xsd:string" }, order
          end

          def add_amount(xml, amount)
            xml.tag! "amount", { "xsi:type" => "xsd:long" }, amount
          end

          def add_credit_number(xml, credit)
            xml.tag! "creditNumber", { "xsi:type" => "xsd:int" }, credit
          end

          def add_digest(xml, fields = [])
            digest_fields = [ActiveMerchant::Billing::Integrations::GpWebpay.merchant_id] + fields
            data = digest_fields.join("|")
            digest = sign_message(data)
            xml.tag! "digest", { "xsi:type" => "xsd:string" }, digest
          end

          def commit(action, request)
            begin
              headers = {
                'Content-Type' => 'text/xml; charset=utf-8',
                'Content-Length' => request.size.to_s,
                'SOAPAction' => ''
              }

              data = ssl_post(url, request, headers)
              response = parse(action, data)

              verified = verify(action, response)
              raise StandardError, "Unverified response" unless verified

              # result
              result = {:ok => (response["ok"] == "true" ? true : false), :verified => verified,
                :pr_code => response["primaryReturnCode"], :sr_code => response["secondaryReturnCode"],
                :message => response_message(response["primaryReturnCode"], response["secondaryReturnCode"])}
              if action == :status
                result[:status] = result[:ok] ? ORDER_STATUS_CODES[response["state"]] : nil
              end
              if action != :batch_close
                result[:order] = response["orderNumber"]
              end
              return result
            rescue ActiveMerchant::ResponseError, StandardError => e
              return {:ok => false, :message => e.message}
            end
          end

          def parse(action, data)
            xml = REXML::Document.new(data)
            if result_href = xml.elements["//ns1:#{ACTIONS[action]}Response/#{ACTIONS[action]}Return"].attributes["href"]
              result = {}
              xml.elements["//multiRef[@id='#{result_href[1..-1]}']"].each do |e|
                if href = e.attributes["href"]
                  result[e.name] = xml.elements["//multiRef[@id='#{href[1..-1]}']"].text
                else
                  result[e.name] = e.text
                end
              end
              return result
            else
              # TODO: parse error
              return nil
            end
          end

          def verify(action, response)
            case action
              when :status
                verify_response("#{response["orderNumber"]}|#{response["state"]}|#{response["primaryReturnCode"]}|#{response["secondaryReturnCode"]}", response["digest"])
              when :batch_close
                verify_response("#{response["primaryReturnCode"]}|#{response["secondaryReturnCode"]}", response["digest"])
              else
                verify_response("#{response["orderNumber"]}|#{response["primaryReturnCode"]}|#{response["secondaryReturnCode"]}", response["digest"])
            end
          end
        end
      end
    end
  end
end
