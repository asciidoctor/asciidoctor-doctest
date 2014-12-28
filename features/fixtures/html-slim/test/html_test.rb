require 'test_helper'

class TestHtml < DocTest::Test
  converter_opts template_dirs: 'templates'
  generate_tests! DocTest::HTML::ExamplesSuite
end
