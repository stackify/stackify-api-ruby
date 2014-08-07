require 'rails/generators/base'

class StackifyGenerator < Rails::Generators::Base
  source_root File.expand_path('../../stackify/templates', __FILE__)

  class_option :api_key, type: :string, required: true

  desc 'Creates a Stackify initializer'
  def copy_initializer
    template 'stackify.rb', 'config/initializers/stackify.rb'
  end

end
