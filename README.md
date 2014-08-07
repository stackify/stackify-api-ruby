# Stackify

Stackify Logs and Metrics API for Ruby


Rails Installation
------------------

### Rails 3.x/4.x

Add the stackify gem to your Gemfile. In Gemfile:

    gem 'stackify-api-ruby'

Run the bundle command to install it:

    $ bundle

Or install it manually:

    $ gem install stackify-api-ruby

After you install stackify-api-ruby you need to run the generator:

    $ rails g stackify --api_key=your_api_key

The generator creates a file under config/initializers/stackify.rb configuring stackify-api-ruby with your API key. You can change default settings there.

Usage: Logging
------------------

### Rails Environment

stackify-api-ruby starts working with start of Rails. Every occured error will be cought and sent to Stackify automatically. The same situation with logs - you just use the Rails logger as usual:

    Rails.logger.info "Some log message"

### Other Environment

For using stackify-api-ruby gem within any Ruby application add to top of your main file:

    require 'stackify-api-ruby'

After that you need to make base configuration:

    Stackify.setup do |config|
      config.api_key = "your_api_key"
      config.env = :development
      config.app_name =  "Your's app name"
      config.app_location =  "/somewhere/public"
    end

"api_key" - it's you key for Stackify. "app-location" - it's location of your application for Nginx/Apache(for Nginx it's value of 'root', for Apache it's value of 'DocumentRoot' at config files).

Gem has 3 modes of work - "both", "logging", "metrics". Mode "both" turns on both parts of gem - logging and metrics.
If you need ONLY logging or metrics use "logging" or "metrics" mode accordingly.

    config.mode = :metrics

You can set minimal level of logs, which should be caught by gem:

    config.log_level = :error

By default, gem sends logs to Stackify every 60 seconds, you can increase this value to higher if need:

    config.send_interval = 60 #value in seconds, could not be less than 60 seconds

All logs, errors, and metrics are queued within the gem and uploaded on a background thread. By default, the maximum amount of logs is 1,000 log items, you can decrease this value:

    config.queue_max_size = 600

To help prevent flooding the system there is a parameter - max amount of the same error per minute:

    config.flood_limit = 100

If you want to use proxy for sendig request, you can do it in such way:

    config.with_proxy = true
    config.proxy_host = "127.0.0.1"
    config.proxy_port = "8118"
    config.proxy_user = nil
    config.proxy_pass = nil

For logging own work stackify-api-rubystackify-api-rubygem uses such logger:

    config.logger = Logger.new(File.join(Rails.root, "log", "stackify.log"))

After set up of logs you should wrap up your logger:

    logger = Logger.new('mylog.log')
    logger = Stackify::LoggerProxy.new(logger)


And last thing you need to do - call method "run":

    Stackify.run #remember that this call is running in the background of your main script

Usage: Metrics
------------------

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

- **Counter and Timer**: Composite of the Counter and Timer metrics for convenience

        t = Time.now
        Stackify::Metrics.count_and_time "Metric", "CounterWithTime", t

We can configure every metric with settings:

        settings  = MetricSettings.new
        settings.autoreport_zero_if_nothing_reported = true
        # or
        settings.autoreport_last_value_if_nothing_reported = true
        Stackify::Metrics.set_gauge "MyCategory", "MyGauge", 100 , settings

Note, "autoreport_last_value_if_nothing_reported" property has influence only on "average" metric.

Also there are two methods for getting last values of metrics:

- get_latest - return last value of certain metric

    ``` Stackify::Metrics.get_latest "MyCategory", "MyCounter" ```

- get_latest_all_metrics - return all values of existed metrics

    ``` Stackify::Metrics.get_latest_all_metrics```

## Requirements
Ruby: 1.9/2.0/2.1

Rails: 3.x/4.x

Contributing
------------------

1. Fork it ( https://github.com/[my-github-username]/stackify/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
