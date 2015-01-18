module Asciidoctor::DocTest
  module Latex
    module Normalizer

      def normalize(latex)
        latex.lines.map(&:lstrip)
      end
    end
  end
end
