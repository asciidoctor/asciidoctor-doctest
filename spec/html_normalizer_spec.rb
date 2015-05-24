describe DocTest::HtmlNormalizer do

  [Nokogiri::HTML::Document, Nokogiri::HTML::DocumentFragment].each do |klass|
    it "HtmlNormalizer should be included in #{klass}" do
      expect(klass).to have_method :normalize!
    end
  end

  describe 'normalize!' do

    it 'sorts attributes by name' do
      output = normalize '<img src="tux.png" width="60" height="100" alt="Tux!">'
      expect(output).to eq '<img alt="Tux!" height="100" src="tux.png" width="60">'
    end

    it 'removes all blank text nodes' do
      output = normalize "  <section>\n  <p>Lorem ipsum</p>\n\t</section>\n\n"
      expect(output).to eq '<section><p>Lorem ipsum</p></section>'
    end

    context 'in "style" attribute' do

      it 'sorts CSS declarations by name' do
        output = normalize %(<div style="width: 100%; color: 'red'; font-style: bold"></div>)
        expect(output).to eq %(<div style="color: 'red'; font-style: bold; width: 100%;"></div>)
      end
    end

    context 'in text node' do

      it 'strips nonsignificant leading and trailing whitespaces' do
        output = normalize "<p> Lorem<b> ipsum</b> dolor\n<br> sit <i>amet</i></p>"
        expect(output).to eq '<p>Lorem<b> ipsum</b> dolor<br>sit <i>amet</i></p>'
      end

      it 'strips nonsignificant repeated whitespaces' do
        output = normalize "<p>Lorem   ipsum\t\tdolor</p>"
        expect(output).to eq "<p>Lorem ipsum\tdolor</p>"
      end

      it 'replaces newlines with spaces' do
        output = normalize "<p>Lorem\nipsum\n\ndolor</p>"
        expect(output).to eq '<p>Lorem ipsum dolor</p>'
      end
    end

    context 'in preformatted node or descendant' do

      it 'does not strip leading and trailing whitespaces' do
        input = "<pre> Lorem<b> ipsum</b> dolor\n<br> sit amet</pre>"
        expect(normalize(input)).to eq input
      end

      it 'does not strip repeated whitespaces' do
        input = "<pre>Lorem   ipsum\t\tdolor\n<code>sit   amet</code></pre>"
        output = normalize input
        expect(output).to eq input
      end

      it 'does not replace newlines with spaces' do
        input = "<pre>Lorem\n<code>\nipsum</code>\n\ndolor</pre>"
        expect(normalize(input)).to eq input
      end
    end
  end

  def normalize(input)
    Nokogiri::HTML.fragment(input).normalize!.to_s
  end
end
