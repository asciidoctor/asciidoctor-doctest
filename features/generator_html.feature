Feature: Generating output examples for a custom HTML backend

  Background:
    Given I do have a template-based HTML backend with DocTest

  Scenario: Generate missing output examples
    When I run `bundle exec rake doctest:generate`
    Then the output should contain:
      """
      Generating test examples *:* in examples/html
       --> Unchanged block_quote:with_id_and_role
       --> Generating block_quote:with_title
       --> Skipping block_quote:with_attribution
       --> Unknown block_quote:basic, doesn't exist in input examples!
       --> Skipping document:title_with_author
       --> Generating inline_quoted:emphasis

      """
    And the file "examples/html/block_quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with_id_and_role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with_attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div>Albert Einstein</div>
      </div>

      <!-- .with_title -->
      <section class="quoteblock">
        <h6>After landing the cloaked Klingon bird of prey in Golden Gate park:</h6>
        <blockquote>Everybody remember where we parked.</blockquote>
      </section>

      """
    And the file "examples/html/document.html" should contain exactly:
      """
      <!-- .title_with_author
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
       --> Unchanged block_quote:with_id_and_role
       --> Generating block_quote:with_title
       --> Rewriting block_quote:with_attribution
       --> Unknown block_quote:basic, doesn't exist in input examples!
       --> Rewriting document:title_with_author
       --> Generating inline_quoted:emphasis

      """
    And the file "examples/html/block_quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with_id_and_role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with_attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div class="attribution">— Albert Einstein</div>
      </div>

      <!-- .with_title -->
      <section class="quoteblock">
        <h6>After landing the cloaked Klingon bird of prey in Golden Gate park:</h6>
        <blockquote>Everybody remember where we parked.</blockquote>
      </section>

      """
    And the file "examples/html/document.html" should contain exactly:
      """
      <!-- .title_with_author
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
       --> Rewriting block_quote:with_attribution

      """
    And the file "examples/html/block_quote.html" should contain exactly:
      """
      <!-- .basic
      Doesn't exist in input examples.
      -->
      <div class="quoteblock">
        <blockquote>Four score and seven years ago our fathers brought forth
      on this continent a new nation&#8230;&#8203;</blockquote>
      </div>

      <!-- .with_id_and_role
      Correct example.
      -->
      <div id="parking"
           class="quoteblock startrek">
        <blockquote>
          Everybody   remember
          where   we    parked.
        </blockquote>
      </div>

      <!-- .with_attribution
      Failing example.
      -->
      <div class="quoteblock">
        <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
        <div class="attribution">— Albert Einstein</div>
      </div>

      """
