group :test do
    if ENV['STACKIFY_RUBY_TEST']
        gem 'stackify-ruby-apm', '~> 1.16.0.beta1', source: ENV['STACKIFY_RUBY_TEST_REPO']
    else
        gem 'stackify-ruby-apm', '~> 1.16.0.beta1'
    end
end

source 'https://rubygems.org'
# Specify your gem's dependencies in stackify.gemspec
gemspec
