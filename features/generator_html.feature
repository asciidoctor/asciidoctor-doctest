Feature: Generating output examples for a custom HTML backend

  Background:
    Given I do have a template-based HTML backend with DocTest

  Scenario: Generate missing output examples
    When I run `bundle exec rake doctest:generate`
    Then the output should contain:
      """
      Generating test examples *:* in examples/html
       --> Skipping document:title-with-author
       --> Generating inline_quoted:emphasis
       --> Unchanged quote:with-id-and-role
       --> Generating quote:with-title
       --> Skipping quote:with-attribution
       --> Unknown quote:basic, doesn't exist in input examples!

      """
    And the file "examples/html/quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with-id-and-role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with-attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div>Albert Einstein</div>
      </div>

      <!-- .with-title -->
      <section class="quoteblock">
        <h6>After landing the cloaked Klingon bird of prey in Golden Gate park:</h6>
        <blockquote>Everybody remember where we parked.</blockquote>
      </section>

      """
    And the file "examples/html/document.html" should contain exactly:
      """
      <!-- .title-with-author
      :include: .//body/div[@id="header"]
      -->
      <div id="header">
        <h1>The Dangerous and Thrilling Documentation Chronicles</h1>
        <div id="author">Kismet Rainbow Chameleon</div>
      </div>

      """
    And the file "examples/html/inline_quoted.html" should contain exactly:
      """
      <!-- .emphasis -->
      <em>chunky bacon</em>

      """

  Scenario: Regenerate all outdated output examples
    When I run `bundle exec rake doctest:generate FORCE=yes`
    Then the output should contain:
      """
      Generating test examples *:* in examples/html
       --> Rewriting document:title-with-author
       --> Generating inline_quoted:emphasis
       --> Unchanged quote:with-id-and-role
       --> Generating quote:with-title
       --> Rewriting quote:with-attribution
       --> Unknown quote:basic, doesn't exist in input examples!

      """
    And the file "examples/html/quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with-id-and-role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with-attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div class="attribution">— Albert Einstein</div>
      </div>

      <!-- .with-title -->
      <section class="quoteblock">
        <h6>After landing the cloaked Klingon bird of prey in Golden Gate park:</h6>
        <blockquote>Everybody remember where we parked.</blockquote>
      </section>

      """
    And the file "examples/html/document.html" should contain exactly:
      """
      <!-- .title-with-author
      :include: .//body/div[@id="header"]
      -->
      <div id="header">
        <h1>The Dangerous and Thrilling Documentation Chronicles</h1>
        <div class="details"><span id="author">Kismet Rainbow Chameleon</span></div>
      </div>

      """

  Scenario: Regenerate outdated output examples specified by filter
    When I run `bundle exec rake doctest:generate PATTERN="*:*attribution" FORCE=yes`
    Then the output should contain:
      """
      Generating test examples *:*attribution in examples/html
       --> Rewriting quote:with-attribution

      """
    And the file "examples/html/quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with-id-and-role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with-attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div class="attribution">— Albert Einstein</div>
      </div>

      """
