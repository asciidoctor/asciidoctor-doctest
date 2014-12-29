Feature: Testing a custom HTML backend

  Background:
    Given I do have a template-based HTML backend with DocTest

  Scenario: Some examples do not match the expected output
    When I run `bundle exec rake test`
    Then the output should contain:
      """
        1) Failure:
      TestHtml :: block_quote : with_attribution:
      Failing example..

         <div class="quoteblock">
           <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
      E    <span>Albert Einstein</span>
      A    <div class="attribution">— Albert Einstein</div>
         </div>
      """
    And the output should contain:
      """
        2) Failure:
      TestHtml :: document : title_with_author:
      This example should fail..

         <div id="header">
           <h1>The Dangerous and Thrilling Documentation Chronicles</h1>
      E    <div id="author">Kismet Rainbow Chameleon</div>
      A    <div class="details"><span id="author">Kismet Rainbow Chameleon</span></div>
         </div>
      """
    And the output should contain:
      """
      5 runs, 3 assertions, 2 failures, 0 errors, 2 skips
      """

  Scenario: A necessary template is missing and fallback to the built-in converter is disabled
    When I remove the file "templates/inline_quoted.html.slim"
    And I run `bundle exec rake test`
    Then the output should contain:
      """
      Could not find a custom template to handle template_name: inline_quoted
      """
    And the output should contain:
      """
        1) Failure:
      TestHtml :: block_quote : with_attribution:
      Failing example..

         <div class="quoteblock">
      E    <blockquote>A person who never made a mistake <em>never</em> tried anything new.</blockquote>
      E    <span>Albert Einstein</span>
      A    <blockquote>A person who never made a mistake --TEMPLATE NOT FOUND-- tried anything new.</blockquote>
      A    <div class="attribution">— Albert Einstein</div>
         </div>
      """
