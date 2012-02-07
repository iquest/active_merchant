module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module GpWebpay 
        autoload :Helper, File.dirname(__FILE__) + '/gp_webpay/helper.rb'
        autoload :Notification, File.dirname(__FILE__) + '/gp_webpay/notification.rb'

        mattr_accessor :merchant_id, :bank_id
        mattr_accessor :private_key, :public_key, :password, :gp_key
        mattr_accessor :response_url

        def self.setup
          yield(self)
        end

        mattr_accessor :test_url, :production_url

        self.test_url = 'https://test.3dsecure.gpwebpay.com/kb/order.do'
        self.production_url = "https://3dsecure.gpwebpay.com/kb/order.do"

        def self.service_url
          mode = ActiveMerchant::Billing::Base.integration_mode
          case mode
          when :production
            self.production_url
          when :test
            self.test_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
          end
        end

        def self.notification(post, options = {})
          Notification.new(post)
        end  

        def self.return(query_string, options = {})
          Return.new(query_string)
        end

        def self.payment_service_url(order, account, options = {})
          params = []
          Helper.new(order, account, options).form_fields.each do |field, value|
            params << "#{field}=#{CGI::escape(value)}"
          end
          return "#{self.service_url}?#{params.join("&")}"
        end

      end
    end
  end
end
