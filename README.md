# stackify-api-ruby

[![Gem Version](https://badge.fury.io/rb/stackify-api-ruby.svg)](http://badge.fury.io/rb/stackify-api-ruby)

Stackify Logs and Metrics API for Ruby.

Errors and Logs Overview:

http://support.stackify.com/errors-and-logs-overview/

Sign Up for a Trial:

http://www.stackify.com/sign-up/

## Installation and Configuration

Requirements: Ruby 1.9/2.0/2.1, Rails 3.x/4.x (optional)

### Rails

Add the stackify gem to your Gemfile. In Gemfile:

    gem 'stackify-api-ruby'

Run the bundle command to install it:

    $ bundle

or install it manually:

    $ gem install stackify-api-ruby

After you install stackify-api-ruby you need to run the generator:

    $ rails g stackify --api_key=your_api_key

The generator creates a file 'config/initializers/stackify.rb' configuring stackify-api-ruby with your API key. You can change default settings there.

### Non-Rails

For using stackify-api-ruby gem within any Ruby application add to top of your main file:

    require 'stackify-api-ruby'

After that you need to make base configuration:

    Stackify.setup do |config|
      config.api_key = "your_api_key"
      config.env = :development
      config.app_name = "Your app name"
    end

## Optional Configuration

Gem has 3 modes of work - "both", "logging", "metrics". Mode "both" turns on both parts of gem - logging and metrics.
If you need ONLY logging or metrics use "logging" or "metrics" mode accordingly.

    config.mode = :metrics

If you want to use proxy for sending request, you can do it in such way:

    config.proxy = { uri: '127.0.0.1:8118', user: 'user_name', password: 'some_password' }

## Log API Usage

### Rails

stackify-api-ruby starts with start of Rails. Every error, which occurs within your application, will be caught and sent to Stackify automatically. The same situation with logs - you just use the Rails logger as usual:

    Rails.logger.info "Some log message"

If you want to redefine <b>logger</b>, you should add

    config.logger = ::Stackify::LoggerProxy.new(ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log")))

to your config/environments/%environment%. <b>Note:</b> in this case Stackify#config.log_level will affect entire system.

### Non-Rails

After logs configuring you should wrap up your logger:

    logger = Logger.new('mylog.log')
    logger = Stackify::LoggerProxy.new(logger)

And last thing you need to do - call method "run":

    Stackify.run #remember that this call is running in the background of your main script

## Metrics API Usage

There are four different types of metrics:

- **Gauge**: Keeps track of the last value that was set in the current minute

        Stackify::Metrics.set_gauge "MyCategory", "MyGauge", 100

- **Counter**: Calculates the rate per minute

        Stackify::Metrics.count "MyCategory", "MyCounter"

- **Average**: Calculates the average of all values in the current minute

        Stackify::Metrics.average "MyCategory", "AverageSpeed", 200

- **Timer**: Calculates the average elapsed time for an operation in the current minute

        t = Time.now
        Stackify::Metrics.time "MyCategory", "ElapsedTime", t
        # or
        Stackify::Metrics.time_duration "MyCategory", "ElapsedTime", 5.seconds

- **Counter and Timer**: Composite of the Counter and Timer metrics for convenience

        t = Time.now
        Stackify::Metrics.count_and_time "Metric", "CounterWithTime", t

We can configure every metric with settings:

        settings = Stackify::Metrics::MetricSettings.new
        settings.autoreport_zero_if_nothing_reported = true
        # or
        settings.autoreport_last_value_if_nothing_reported = true
        Stackify::Metrics.set_gauge "MyCategory", "MyGauge", 100 , settings

Note, "autoreport_last_value_if_nothing_reported" property has influence only on "average" metric.

### **Real User Monitoring (RUM)**

Real user monitoring injects a script tag containing the [RUM JS](https://stackify.com/retrace-real-user-monitoring/) that is responsible for capturing information about the http requests on the browser. This approach is manual and needs to be configured.

#### RUM - Setup

```ruby
# Configuration - Standard API
Stackify.setup do |config|
  ...
  config.rum_key = "YourRumKey"
end

# Use this to apply on views
Stackify.rum.insert_rum_script
```

## Troubleshooting

If there are problems, you can enable internal logging of the stackify-api-ruby project. Uncomment out the config.logger and config.logger.level lines in the 'config/initializers/stackify.rb' file:

```
config.logger = Logger.new(Rails.root.join("log", "stackify.log"))
config.logger.level = Logger::DEBUG
```

## License

Copyright 2018 Stackify, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
