require 'rspec/expectations'

RSpec::Matchers.define :have_method do |*names|
  match do |klass|
    names.all? { |name| klass.method_defined? name }
  end
end
