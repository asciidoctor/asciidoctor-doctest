require 'asciidoctor/doctest/io/base'
require 'asciidoctor/doctest/io/asciidoc'
require 'asciidoctor/doctest/io/xml'
require 'asciidoctor/doctest/factory'

module Asciidoctor::DocTest
  module IO
    extend Factory

    register :asciidoc, Asciidoc, file_ext: '.adoc'
    register :xml, XML, file_ext: '.xml'
    register :html, XML, file_ext: '.html'
  end
end
