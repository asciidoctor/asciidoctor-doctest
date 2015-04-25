Feature: Testing a custom HTML backend

  Background:
    Given I do have a template-based HTML backend with DocTest

  Scenario: Some examples do not match the expected output
    When I run `bundle exec rake doctest:test`
    Then the output should contain:
      """
      Running DocTest for the templates: templates.

      .SFFS
      """
    Then the output should contain:
      """
      ✗  Failure: block_quote:with_attribution
         Failing example..

            <div class="quoteblock">
              <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
         E    <div>Albert Einstein</div>
         A    <div class="attribution">— Albert Einstein</div>
            </div>
      """
    And the output should contain:
      """
      ✗  Failure: document:title_with_author
         This example should fail..

            <div id="header">
              <h1>The Dangerous and Thrilling Documentation Chronicles</h1>
         E    <div id="author">Kismet Rainbow Chameleon</div>
         A    <div class="details"><span id="author">Kismet Rainbow Chameleon</span></div>
            </div>
      """
    And the output should contain:
      """
      5 examples (1 passed, 2 failed, 2 skipped)
      """
    And the output should contain:
      """
      You have skipped tests. Run with VERBOSE=yes for details.
      """

    When I run `bundle exec rake doctest:test VERBOSE=yes`
    Then the output should contain:
      """
      Running DocTest for the templates: templates.

      ✓  block_quote:with_id_and_role
      ∅  block_quote:with_title
      ✗  block_quote:with_attribution
      ✗  document:title_with_author
      ∅  inline_quoted:emphasis

      """
    And the output should contain:
      """
      ∅  Skipped: block_quote:with_title
         No expected output found
      """
    And the output should contain:
      """
      ∅  Skipped: inline_quoted:emphasis
         No expected output found
      """

  Scenario: Test only examples matching the pattern
    When I run `bundle exec rake doctest:test PATTERN=block_*:* VERBOSE=yes`
    Then the output should contain:
      """
      Running DocTest for the templates: templates.

      ✓  block_quote:with_id_and_role
      ∅  block_quote:with_title
      ✗  block_quote:with_attribution

      """

  Scenario: A necessary template is missing and fallback to the built-in converter is disabled
    When I remove the file "templates/inline_quoted.html.slim"
    And I run `bundle exec rake doctest:test`
    Then the output should contain:
      """
      Could not find a custom template to handle template_name: inline_quoted
      """
    And the output should contain:
      """
      ✗  Failure: block_quote:with_attribution
         Failing example..

            <div class="quoteblock">
         E    <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
         E    <div>Albert Einstein</div>
         A    <blockquote>A person who never made a mistake --TEMPLATE NOT FOUND-- tried anything new.</blockquote>
         A    <div class="attribution">— Albert Einstein</div>
            </div>
      """
