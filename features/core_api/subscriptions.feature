Feature:
  As a developer
  I want to be able to retrieve a user's subscriptions
  So that I encourage others to participate and show how people are using the system

  Background:
    Given a registered user:
      | First Name           | Joe           |
      | Last Name            | Test          |
      | Email                | joe@test.com  |
      | Zip                  | 44444         |
      | Password             | abcd1234      |
      | ID                   | 12            |
    Given I am following the conversation:
      | ID       | 2                                            |
      | Title    | Understanding The Latest Health Care Changes |
      | Summary  | This is a great new conversation.            |
      | Zip Code | 48105                                        |
      | Comment  | This is a sweet new comment.                 |
    Given I am following the conversation:
      | ID       | 3                                               |
      | Title    | Obamacare Pushes on Through Despite Antagonists |
      | Summary  | This is a great new conversation.               |
      | Zip Code | 48105                                           |
      | Comment  | This is a sweet new comment.                    |
    And I am following the issue:
      | ID   | 200                                           |
      | Name | Democrats Upset About Recent Election Results |

  Scenario: Retrieve all subscriptions
    When I ask for subscriptions for the person with ID 12
    Then I should receive the response:
    """
    [
      {
        "id": 200,
        "title": "Democrats Upset About Recent Election Results",
        "url": "http://www.example.com/issues/democrats-upset-about-recent-election-results",
        "type": "issue"
      },
      {
        "id": 3,
        "title": "Obamacare Pushes on Through Despite Antagonists",
        "url": "http://www.example.com/conversations/3",
        "type": "conversation"
      },
      {
        "id": 2,
        "title": "Understanding The Latest Health Care Changes",
        "url": "http://www.example.com/conversations/2",
        "type": "conversation"
      }
    ]
    """

  Scenario: Retrieve subscribed conversations
    When I ask for conversations the person with ID 12 is following
    Then I should receive the response:
    """
    [
      {
        "id": 3,
        "title": "Obamacare Pushes on Through Despite Antagonists",
        "url": "http://www.example.com/conversations/3"
      },
      {
        "id": 2,
        "title": "Understanding The Latest Health Care Changes",
        "url": "http://www.example.com/conversations/2"
      }
    ]
    """

  Scenario: Retrieve subscribed issues
    When I ask for issues the person with ID 12 is following
    Then I should receive the response:
    """
    [{
      "id": 200,
      "title": "Democrats Upset About Recent Election Results",
      "url": "http://www.example.com/issues/democrats-upset-about-recent-election-results"
    }]
    """

  Scenario: Retrieve subscriptions for non-existant user
    When I ask for subscriptions for the person with ID 1099932
    Then I should receive a 404 Not Found response

