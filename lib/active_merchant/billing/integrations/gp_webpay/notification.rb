module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include Common

          def complete?
            pr_code == "0" && sr_code == "0"
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
