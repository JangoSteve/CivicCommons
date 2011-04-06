require 'spec_helper'

describe RatingGroup do
  before(:all) do
    @current_person = Factory.create(:normal_person)
    @conversation = Factory.create(:conversation)
    @contribution = Factory.create(:comment, :conversation => @conversation)
    @descriptor = Factory.create(:rating_descriptor)
    @descriptor2 = Factory.create(:rating_descriptor, :title => "Motivating")
    @rg = Factory.create(:rating_group, :contribution => @contribution, :person => @current_person)
    @rg2 = Factory.create(:rating_group, :contribution => @contribution)
    @rating1a = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor)
    @rating1b = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor2)
    @rating2a = Factory.create(:rating, :rating_group => @rg2, :rating_descriptor => @descriptor)
  end

  it "returns all of the ratings for a conversation" do
    expected_result = {
                        @descriptor.title => [@rating1a, @rating2a],
                        @descriptor2.title => [@rating1b]
                      }
    rgs = RatingGroup.ratings_for_conversation(@conversation)
    rgs.should == expected_result
  end

  it "returns all of the ratings for a conversation with counts" do
    expected_result = {
                        @descriptor.title => 2,
                        @descriptor2.title => 1
                      }
    rgs = RatingGroup.ratings_for_conversation_with_count(@conversation)
    rgs.should == expected_result
  end

  it "returns all of the ratings for a conversation by contribution with counts" do
    expected_result = { @contribution.id => { @descriptor.title => 2,
                                              @descriptor2.title => 1
                                            }
                      }
    rgs = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation)
    rgs.should == expected_result
  end

  it "returns all ratings for contributions in convo with counts for person if person given" do
    expected_result = {
      @contribution.id => {
        @descriptor.title => 1,
        @descriptor2.title => 1
      }
    }

    rgs = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation, @current_person)
    rgs.should == expected_result
  end
end
