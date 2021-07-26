$apmLoaded = false

begin
  require 'stackify-ruby-apm'
  $apmLoaded = true
rescue LoadError
end

module Stackify
  class Rum
    def initialize(config)
      @config = config
    end

    def insert_rum_script()
      return StackifyRubyAPM.inject_rum_script if Rum.apm_loaded && defined?(StackifyRubyAPM)

      return '' unless @config

      config = @config

      return '' if config.rum_script_url.to_s.empty? || config.rum_key.to_s.empty?

      transaction_id = get_transaction_id().to_s
      return '' if transaction_id.empty?

      reporting_url = get_reporting_url().to_s
      return '' if reporting_url.empty?

      environment_name = defined?(config.env) ? config.env.to_s : 'Development'
      return '' if environment_name.empty?

      application_name = defined?(config.app_name) ? config.app_name.to_s : ''
      return '' if application_name.empty?

      rum_settings = {
        "ID" => transaction_id
      }

      if !environment_name.empty?
        rum_settings["Env"] = Base64.strict_encode64(environment_name.encode('utf-8'))
      end

      if !application_name.empty?
        rum_settings["Name"] = Base64.strict_encode64(application_name.strip.encode('utf-8'))
      end

      if !reporting_url.empty?
        rum_settings["Trans"] = Base64.strict_encode64(reporting_url.encode('utf-8'))
      end

      rum_content = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json}))</script><script src=\"#{config.rum_script_url}\" data-key=\"#{config.rum_key}\" async></script>"
      if rum_content.respond_to?(:html_safe)
        rum_content.html_safe
      else
        rum_content
      end
    end

    def self.apm_loaded
      $apmLoaded
    end
    
    def get_reporting_url
      ''
    end
    
    def get_transaction_id
      ''
    end
  end
end