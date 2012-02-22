module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include Common

          def complete?
            digest_ok? && digest1_ok? && pr_code == "0" && sr_code == "0"
          end

          def pr_code
            params['PRCODE']
          end

          def pr_message
            response_pr_message(pr_code)
          end

          def sr_code
            params['SRCODE']
          end

          def sr_message
            response_sr_message(sr_code)
          end

          def message
            params['RESULTTEXT']
          end

          def full_message
            response_message(pr_code, sr_code)
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

          def digest_ok?
            params['DIGEST_OK']
          end

          def digest1_ok?
            params['DIGEST1_OK']
          end

          private

          def parse(get_params)
            @params = get_params
            @params["DIGEST_OK"] = digest_verified?
            @params["DIGEST1_OK"] = digest1_verified?
          end

          def digest_verified?
            verify_params = [operation, order_id, pr_code, sr_code, message].join('|')
            return verify_response(verify_params, digest)
          end

          def digest1_verified?
            verify_params = [operation, order_id, pr_code, sr_code, message, ActiveMerchant::Billing::Integrations::GpWebpay.merchant_id].join('|')
            return verify_response(verify_params, digest1)
          end
        end
      end
    end
  end
end
