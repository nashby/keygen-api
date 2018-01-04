@api/v1
Feature: License policy relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: Admin retrieves the policy for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/test-key/policy"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product retrieves the policy for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product retrieves the policy for a license of another product
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the policy for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the policy for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "401"

  Scenario: Admin changes a license's policy relationship to a new policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin changes a license's policy relationship to a non-existent policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$users[0]"
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes a license's policy relationship to a new policy that belongs to another product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policy" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot change to a policy for another product"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes a encrypted license's policy relationship to a new unencrypted policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "encrypted": true
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "encrypted": false
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes an unencrypted license's policy relationship to a new encrypted policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "encrypted": false
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "encrypted": true
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes a pooled license's policy relationship to a new unpooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": true
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": false
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot change from a pooled policy to an unpooled policy (or vice-versa)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes an unpooled license's policy relationship to a new pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": false
      }
      """
    And the second "policy" has the following attributes:
      """
      {
        "productId": "$products[0]",
        "usePool": true
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "cannot change from a pooled policy to an unpooled policy (or vice-versa)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes a license's policy relationship to a new policy for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product changes a license's policy relationship to a new policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product changes a license's policy relationship to a new policy they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product changes a license's policy relationship to a new policy for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 3 "policies"
    And the first "policy" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[1]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User changes a license's policy relationship to a new policy for an unprotected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[0]",
        "protected": false
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User changes a license's policy relationship to a new policy for a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      {
        "productId": "$products[0]",
        "protected": true
      }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User changes a license's policy relationship to a new policy for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous changes a license's policy relationship to a new policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "$time.1.day.from_now"
      }
      """
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
