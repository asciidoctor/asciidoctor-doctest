require 'fakefs/spec_helpers'

module FakeFS
  # XXX remove after merging of https://github.com/defunkt/fakefs/pull/270
  module FileTest

    def readable?(file_name)
      File.readable?(file_name)
    end
    module_function :readable?
  end

  # XXX remove after merging of https://github.com/defunkt/fakefs/pull/269
  class Pathname
    def read(*args)
      File.read(@path, *args)
    end
  end
end
