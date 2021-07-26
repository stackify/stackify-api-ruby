require 'spec_helper'
require 'stackify-api-ruby'

module Stackify
    RSpec.describe 'Rum - APM not loaded - Normal' do
        it 'returns rum script with complete information from ENV' do
            ENV['RETRACE_RUM_KEY'] = 'test-key'
            ENV['RETRACE_RUM_SCRIPT_URL'] = 'https://test.com/test.js'

            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'

            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://test.com/test.js'

            rum_settings = {
                "ID" => '123-id',
                "Env" => Base64.strict_encode64('test-env'.encode('utf-8')),
                "Name" => Base64.strict_encode64('test'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('test reporting url'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{config.rum_key}\" async></script>"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).not_to be_empty
            expect(rum_script).to eq expected_rum_script

            ENV.delete('RETRACE_RUM_KEY')
            ENV.delete('RETRACE_RUM_SCRIPT_URL')
        end

        it 'returns rum script with complete information from Config' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'
            config.rum_script_url = 'https://test.com/test.js'
            config.rum_key = 'asd'

            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://test.com/test.js'
            rum_key = 'asd'

            rum_settings = {
                "ID" => '123-id',
                "Env" => Base64.strict_encode64('test-env'.encode('utf-8')),
                "Name" => Base64.strict_encode64('test'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('test reporting url'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{rum_key}\" async></script>"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).not_to be_empty
            expect(rum_script).to eq expected_rum_script
        end
    end

    RSpec.describe 'Rum - APM not loaded - Invalid' do
        it 'returns rum script with invalid rum script url from Config' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'
            config.rum_script_url = 'test.js'
            config.rum_key = 'asd'

            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://stckjs.stackify.com/stckjs.js'
            rum_key = 'asd'

            rum_settings = {
                "ID" => '123-id',
                "Env" => Base64.strict_encode64('test-env'.encode('utf-8')),
                "Name" => Base64.strict_encode64('test'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('test reporting url'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{rum_key}\" async></script>"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).not_to be_empty
            expect(rum_script).to eq expected_rum_script
        end

        it 'returns rum script with invalid rum key from Config' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'
            config.rum_script_url = 'test.js'
            config.rum_key = '`asd'

            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://stckjs.stackify.com/stckjs.js'
            rum_key = 'asd'

            rum_settings = {
                "ID" => '123-id',
                "Env" => Base64.strict_encode64('test-env'.encode('utf-8')),
                "Name" => Base64.strict_encode64('test'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('test reporting url'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{rum_key}\" async></script>"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).to be_empty
            expect(rum_script).not_to eq expected_rum_script
            expect(config.rum_key).to be_empty
        end

        it 'returns rum script with no app name' do
            config = Stackify::Configuration.new
            config.app_name = ''
            config.env = 'test-env'
            config.rum_script_url = 'test.js'
            config.rum_key = '`asd'

            rum = Stackify::Rum.new(config)

            reporting_url = "test reporting url"
            transaction_id = "123-id"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).to be_empty
            expect(config.rum_key).to be_empty
            expect(config.app_name).to be_empty
        end

        it 'returns rum script with no env' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.rum_script_url = 'test.js'
            config.rum_key = 'asd'

            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://stckjs.stackify.com/stckjs.js'
            rum_key = 'asd'

            rum_settings = {
                "ID" => '123-id',
                "Env" => Base64.strict_encode64('production'.encode('utf-8')),
                "Name" => Base64.strict_encode64('test'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('test reporting url'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{rum_key}\" async></script>"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).not_to be_empty
            expect(rum_script).to eq expected_rum_script
            expect(config.env).to eq :production
        end

        it 'returns rum script with no transaction id' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'
            config.rum_script_url = 'test.js'
            config.rum_key = 'asd'

            rum = Stackify::Rum.new(config)

            reporting_url = "test reporting url"
            transaction_id = ""

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq reporting_url
            expect(rum.get_transaction_id).to eq ""
            expect(rum_script.to_s).to be_empty
        end

        it 'returns rum script with no reporting url' do
            config = Stackify::Configuration.new
            config.app_name = 'test'
            config.env = 'test-env'
            config.rum_script_url = 'test.js'
            config.rum_key = 'asd'

            rum = Stackify::Rum.new(config)

            reporting_url = ""
            transaction_id = "test-123"

            allow(rum).to receive(:get_reporting_url).and_return(reporting_url)
            allow(rum).to receive(:get_transaction_id).and_return(transaction_id)
            allow(Rum).to receive(:apm_loaded).and_return(false)

            rum_script = rum.insert_rum_script

            expect(rum.get_reporting_url).to eq ""
            expect(rum.get_transaction_id).to eq transaction_id
            expect(rum_script.to_s).to be_empty
        end
    end

    RSpec.describe 'Rum - APM loaded - Normal' do
        it 'returns rum script with complete information from ENV' do
            ENV['RETRACE_RUM_KEY'] = 'test-key'
            ENV['RETRACE_RUM_SCRIPT_URL'] = 'https://test.com/test.js'
            ENV['TZ'] = 'Europe/Paris' # For error

            config = Stackify::Configuration.new
            rum = Stackify::Rum.new(config)
            reporting_url = "test reporting url"
            transaction_id = "123-id"
            rum_script_url = 'https://test.com/test.js'
            rum_script = ""

            StackifyRubyAPM.start
            transaction = StackifyRubyAPM.transaction 'RUM Script Injection test' do
                rum_script = rum.insert_rum_script
            end.submit 200
            StackifyRubyAPM.stop

            rum_settings = {
                "ID" => transaction.id(),
                "Env" => Base64.strict_encode64('test'.encode('utf-8')),
                "Name" => Base64.strict_encode64('Ruby Application'.strip.encode('utf-8')), # TODO: Add helper function
                "Trans" => Base64.strict_encode64('RUM Script Injection test'.encode('utf-8'))
            }

            expected_rum_script = "<script type=\"text/javascript\">(window.StackifySettings || (window.StackifySettings = #{rum_settings.to_json()}))<\/script><script src=\"#{rum_script_url}\" data-key=\"#{config.rum_key}\" async></script>"

            ENV.delete('TZ')
            ENV.delete('RETRACE_RUM_KEY')
            ENV.delete('RETRACE_RUM_SCRIPT_URL')

            expect(rum_script.to_s).not_to be_empty
            expect(rum_script).to eq expected_rum_script
        end
    end
  end
  