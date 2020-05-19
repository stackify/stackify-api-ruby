require 'json'
require 'core_ext/object'

begin
  require 'active_support/time'
rescue LoadError => e
  require 'core_ext/fixnum'
end
