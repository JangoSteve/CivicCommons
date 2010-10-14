Feature:
  As an anonymous person
  I want to sign up for an account
  So that I can interact with the Civic Commons community


  @api
  Scenario: User signs up for account with email address, name, zip code, username and password

      Given the user signs up with:
        | Name      | Joe Test      |
        | Email     | joe@test.com  |
        | Zip       | 44444         |
        | Password  | abcd1234      |
      Then a user should be created with email "joe@test.com"
      And a confirmation email is sent:
        | From    | admin@theciviccommons.com     |
        | To      | joe@test.com                  |
        | Subject | Confirmation instructions     |
      And a People Aggregator shadow account should be created

  Scenario: User clicks confirmation link in email

    Given the user signs up with:
      | Name      | Joe Test      |
      | Email     | joe@test.com  |
      | Zip       | 44444         |
      | Password  | abcd1234      |
    When the user confirms his account
    Then the user should be confirmed
    And the user should be logged in


  Scenario: Deleting a user should destroy the user's shadow account

    Given the user signs up with:
        | Name      | Joe Test      |
        | Email     | joe@test.com  |
        | Zip       | 44444         |
        | Password  | abcd1234      |
    When I delete the user
    Then the user's People Aggregator shadow account should no longer exist