require 'spec_helper'

describe RatingGroup do
  before(:each) do
    @current_person = Factory.create(:normal_person)
    @conversation = Factory.create(:conversation)
    @contribution = Factory.create(:comment, :conversation => @conversation)
    @descriptor = Factory.create(:rating_descriptor)
    @descriptor2 = Factory.create(:rating_descriptor, :title => "Motivating")
    @rg = Factory.create(:rating_group, :contribution => @contribution, :person => @current_person)
    @rating = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor)
    @rating2 = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor2)
    @rating1b = Factory.create(:rating, :rating_descriptor => @descriptor)
  end

  it "returns all of the ratings for a conversation" do
    expected_result = {
                        @descriptor.title => [@rating],
                        @descriptor2.title => [@rating2]
                      }
    RatingGroup.ratings_for_conversation(@conversation).should == expected_result
  end
end
