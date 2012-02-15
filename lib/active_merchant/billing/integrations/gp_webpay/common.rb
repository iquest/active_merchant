module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        module Common

          PR_ERROR_CODES = {
            "0"    => "OK",
            "1"    => "Field too long",
            "2"    => "Field too short",
            "3"    => "Incorrect content of field",
            "4"    => "Field is null",
            "5"    => "Missing required field",
            "11"   => "Unknown merchant",
            "14"   => "Duplicate order number",
            "15"   => "Object not found",
            "17"   => "Amount to deposit exceeds approved amount",
            "18"   => "Total sum of credited amounts exceeded deposited amount",
            "20"   => "Object not in valid state for operation",
            "26"   => "Technical problem in connection to authorization centre",
            "27"   => "Incorrect order type",
            "28"   => "Result from 3D reason - SRCODE",
            "30"   => "Declined in AC reason - SRCODE",
            "31"   => "Wrong digest",
            "1000" => "Technical problem"
          }

          SR_ERROR_CODES = {
            "0"    => "-",
            "1"    => "ORDERNUMBER",
            "2"    => "MERCHANTNUMBER",
            "6"    => "AMOUNT",
            "7"    => "CURRENCY",
            "8"    => "DEPOSITFLAG",
            "10"   => "MERORDERNUM",
            "11"   => "CREDITNUMBER",
            "12"   => "OPERATION",
            "18"   => "BATCH",
            "22"   => "ORDER",
            "24"   => "URL",
            "25"   => "MD",
            "26"   => "DESC",
            "34"   => "DIGEST",
            "3000" => "Declined in 3D. Cardholder not authenticated in 3D.Contact your card issuer. Note: Cardholder authentication failed (wrong password, transaction canceled, authentication window was closed...) Transaction Declined.",
            "3001" => "Authenticated Note: Cardholder was successfully authenticated - transaction continue with authorization.",
            "3002" => "Not Authenticated in 3D. Issuer or Cardholder not participating in 3D. Contact your card issuer. Note: Cardholder wasn't authenticated - Issuer or Cardholder not participating in 3D. Transaction can continue.",
            "3004" => "Not Authenticated in 3D. Issuer not participating or Cardholder not enrolled. Contact your card issuer. Note: Cardholder wasn't authenticated - Cardholder not enrolled or Issuer or not participating in 3D. Transaction can continue.",
            "3005" => "Declined in 3D. Technical problem during Cardholder authentication. Contact your card issuer. Note: Cardholder authentication unavailable - issuer not supporting 3D or technical problem in communication between associations and Issuer 3D systems. Transaction cannot continue.",
            "3006" => "Declined in 3D. Technical problem during Cardholder authentication. Note: Technical problem during cardholder authentication - merchant authentication failed or technical problem in communication between association and acquirer. Transaction cannot continue.",
            "3007" => "Declined in 3D. Acquirer technical problem. Contact the merchant. Note: Technical problem during cardholder authentication - 3D systems technical problem. Transaction cannot continue.",
            "3008" => "Declined in 3D. Unsupported card product. Contact your card issuer. Note: Card not supported in 3D. Transaction cannot continue.",
            "1001" => "Declined in AC, Card blocked, Possible reasons: blocked card, lost card, stolen card, pick-up card",
            "1002" => "Declined in AC, Declined, Reason: Card issuer or financial association rejected authorization (\"Don Not Honor\")",
            "1003" => "Declined in AC, Card problem, Possible reasons: Expired card, wrong card number, Internet transaction not permitted to Cardholder, invalid card, invalid card number, amount over card maximum limit, wrong CVC/CVV, invalid card number length, invalid expiry date, PIN control is required for used card.",
            "1004" => "Authorization rejected - technical problem. Technical problem in card issuer systems or financial associations systems (Card issuer unavailable)",
            "1005" => "Declined in AC, Account problem, Possible reasons: finance absence, over account limit, over daily limit"
          }

          ORDER_STATUS_CODES = {
            "1"  => "REQUESTED",
            "2"  => "REQUESTED",
            "3"  => "CREATED",
            "4"  => "APPROVED",
            "5"  => "APPROVE_REVERSED",
            "6"  => "UNAPPROVED",
            "7"  => "DEPOSITED_BATCH_OPENED",
            "8"  => "DEPOSITED_BATCH_CLOSED",
            "9"  => "ORDER_CLOSED",
            "10" => "DELETED",
            "11" => "CREDITED_BATCH_OPENED",
            "12" => "CREDITED_BATCH_CLOSED",
            "13" => "DECLINED",
          }

          MERORDERNUM_MAX_SIZE = {
            "csob"   => nil,
            "kb"     => 16,
            "rb"     => 10,
            "csobsk" => nil
          }

          def response_pr_message(prcode)
            PR_ERROR_CODES[prcode]
          end

          def response_sr_message(srcode)
            SR_ERROR_CODES[srcode]
          end
          
          def response_message(prcode, srcode)
            srcode == "0" ? response_pr_message(prcode) : "#{response_pr_message(prcode)} - #{response_sr_message(srcode)}"
          end


          def sign_message(data)
            private_key_data = File.read(ActiveMerchant::Billing::Integrations::GpWebpay.private_key)
            private_key  = OpenSSL::PKey::RSA.new(private_key_data, ActiveMerchant::Billing::Integrations::GpWebpay.password)
            signature = private_key.sign(OpenSSL::Digest::SHA1.new, data.gsub('\s', ''))
            return ActiveSupport::Base64.encode64(signature).gsub(/\n/, '')
          end

          def verify_message(data, signature)
            cert_file = File.read(ActiveMerchant::Billing::Integrations::GpWebpay.public_key)
            public_key = OpenSSL::X509::Certificate.new(cert_file).public_key
            return public_key.verify(OpenSSL::Digest::SHA1.new, ActiveSupport::Base64.decode64(signature), data)
          end

          def verify_response(data, signature)
            cert_file = File.read(ActiveMerchant::Billing::Integrations::GpWebpay.gp_key)
            public_key = OpenSSL::X509::Certificate.new(cert_file).public_key
            return public_key.verify(OpenSSL::Digest::SHA1.new, ActiveSupport::Base64.decode64(signature), data)
          end
          
        end
      end
    end
  end
end