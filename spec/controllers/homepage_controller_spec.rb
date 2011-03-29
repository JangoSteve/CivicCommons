require File.dirname(__FILE__) + '/../spec_helper'

describe HomepageController do
  describe "GET 'show'" do
    it "should retrieve the top visited conversations" do
      mock_conversations = [mock_model(Conversation)]
      Conversation.stub(:get_top_visited).and_return(mock_conversations)
      get :show
      assigns(:most_visited_conversations).should eq(mock_conversations)
    end
  end
end
