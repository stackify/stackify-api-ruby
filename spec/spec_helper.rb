ENV['RAILS_ENV'] = ENV['RACK_ENV'] = 'test'
require 'bundler/setup'

# auto-require default gems + gems under test
Bundler.require :default, 'test'

require 'logger'
require 'stackify_ruby_apm'

RSpec.configure do |config|

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

end
