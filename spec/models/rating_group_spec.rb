require 'spec_helper'

describe RatingGroup do
  before(:all) do
    @current_person = Factory.create(:normal_person)
    @conversation = Factory.create(:conversation)
    @contribution = Factory.create(:comment, :conversation => @conversation)
    @descriptor = Factory.create(:rating_descriptor)
    @descriptor2 = Factory.create(:rating_descriptor, :title => "Motivating")
    @descriptor3 = Factory.create(:rating_descriptor, :title => "Tasty")
    @descriptor4 = Factory.create(:rating_descriptor, :title => "Sad")
    @rg = Factory.create(:rating_group, :contribution => @contribution, :person => @current_person)
    @rg2 = Factory.create(:rating_group, :contribution => @contribution)
    @rating1a = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor)
    @rating1b = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor2)
    @rating2a = Factory.create(:rating, :rating_group => @rg2, :rating_descriptor => @descriptor)
    @rating2c = Factory.create(:rating, :rating_group => @rg2, :rating_descriptor => @descriptor3)
  end

  it "returns all of the ratings for a conversation" do
    expected_result = {
                        @descriptor.title => [@rating1a, @rating2a],
                        @descriptor2.title => [@rating1b],
                        @descriptor3.title => [@rating2c],
                        @descriptor4.title => []
                      }
    rgs = RatingGroup.ratings_for_conversation(@conversation)
    rgs.should == expected_result
  end

  it "returns all of the ratings for a conversation with counts" do
    expected_result = {
                        @descriptor.title => 2,
                        @descriptor2.title => 1,
                        @descriptor3.title => 1,
                        @descriptor4.title => 0
                      }
    rgs = RatingGroup.ratings_for_conversation_with_count(@conversation)
    rgs.should == expected_result
  end

  it "returns all of the ratings for a conversation by contribution with counts" do
    expected_result = {
      @contribution.id => {
        @descriptor.title => {:total => 2, :person => nil},
        @descriptor2.title => {:total => 1, :person => nil},
        @descriptor3.title => {:total => 1, :person => nil},
        @descriptor4.title => {:total => 0, :person => nil}
      }
    }
    rgs = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation)
    rgs.should == expected_result
  end

  it "returns all ratings for contributions in convo with counts for person if person given" do
    expected_result = {
      @contribution.id => {
        @descriptor.title => {:total => 2, :person => true},
        @descriptor2.title => {:total => 1, :person => true},
        @descriptor3.title => {:total => 1, :person => false},
        @descriptor4.title => {:total => 0, :person => false}
      }
    }

    rgs = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation, @current_person)
    rgs.should == expected_result
  end

  it "returns a hash of ids/titles of all rating descriptors" do
    expected_result = {
      1 => 'Inspiring',
      2 => 'Motivating',
      3 => 'Tasty',
      4 => 'Sad'
    }

    RatingGroup.rating_descriptors.should == expected_result
  end

  it "returns skeleton of expected hash for contribution with not rating_groups" do
    contribution = Factory.build(:contribution, :id => 42)
    ratings = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation, @current_person)

    expected_result = {
      @descriptor.title => {:total => 0, :person => false},
      @descriptor2.title => {:total => 0, :person => false},
      @descriptor3.title => {:total => 0, :person => false},
      @descriptor4.title => {:total => 0, :person => false}
    }

    ratings[contribution.id].should == expected_result
  end
end
