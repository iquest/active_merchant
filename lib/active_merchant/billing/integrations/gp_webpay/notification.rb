module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include PostsData

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

          def complete?
            pr_code == "0" && sr_code == "0"
          end 

          def pr_code
            params['PRCODE']
          end

          def pr_message
            PR_ERROR_CODES[pr_code]
          end

          def sr_code
            params['SRCODE']
          end

          def sr_message
            SR_ERROR_CODES[sr_code]
          end

          def message
            params['RESULTTEXT']
          end

          def full_message
            sr_code == "0" ? pr_message : "#{pr_message} - #{sr_message}"
          end

          def order_id
            params['ORDERNUMBER']
          end

          def operation
            params['OPERATION']
          end

          def digest
            params['DIGEST']
          end
         
          def digest1
            params['DIGEST1']
          end 

          private

          def parse(get_params)
            # TODO: DIGEST & DIGEST1 check
            @params = get_params
          end

        end
      end
    end
  end
end
