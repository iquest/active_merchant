module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          include Common

          CURRENCY_MAPPING = {
            'EUR' => '978',
            'CZK' => '203',
          }

          # Replace with the real mapping
          mapping :account, 'MERCHANTNUMBER'
          mapping :amount, 'AMOUNT'
          mapping :currency, 'CURRENCY'
          mapping :order, 'ORDERNUMBER'

          mapping :operation, 'OPERATION'
          mapping :depositflag, 'DEPOSITFLAG'
          mapping :url, 'URL'
          mapping :digest, 'DIGEST'

          # optional params
          mapping :merordernum, 'MERORDERNUM'
          mapping :description, 'DESCRIPTION'
          mapping :md, 'MD'

          def initialize(order, account, options = {})
            resp_url = options.delete(:url)
            super
            add_field(mappings[:depositflag], '1')
            add_field(mappings[:operation], 'CREATE_ORDER')
            resp_url = ActiveMerchant::Billing::Integrations::GpWebpay.response_url if resp_url.nil?
            add_field(mappings[:url], resp_url)
            add_digest
          end

          def currency=(currency_code)
            code = CURRENCY_MAPPING[currency_code]
            raise StandardError, "Invalid currency code #{currency_code} specified" if code.nil?
            add_field(mappings[:currency], code)
          end

          def amount=(money)
            cents = money.respond_to?(:cents) ? money.cents : money
            if money.is_a?(String) or cents.to_i < 0
              raise ArgumentError, 'Money amount must be either a Money object or a positive integer in cents.'
            end
            add_field(mappings[:amount], cents)
          end

        private
          
          REQUIRED_FIELDS = [:account, :operation, :order, :amount, :currency, :depositflag, :url]
          #DIGEST_FIELDS = [:account, :operation, :order, :amount, :currency, :depositflag, :merordernum, :url, :description, :md]

          def add_digest
            field_values = REQUIRED_FIELDS.collect{ |field| form_fields[mappings[field]] }
            data = field_values.compact.join('|')
            signature = sign_message(data)
            if verify_message(data, signature)
              add_field(mappings[:digest], signature)
            else
              raise StandardError, 'Message sign problem.'
            end
          end


        end
      end
    end
  end
end
