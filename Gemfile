group :test do
    if ENV['STACKIFY_RUBY_TEST']
        gem 'stackify-ruby-apm', '~> 1.15', source: ENV['STACKIFY_RUBY_TEST_REPO']
    else
        gem 'stackify-ruby-apm', '~> 1.15'
    end
end

source 'https://rubygems.org'
# Specify your gem's dependencies in stackify.gemspec
gemspec
