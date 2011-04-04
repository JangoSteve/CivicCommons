require 'spec_helper'

describe Rating do
  before(:each) do
    @current_person = Factory.create(:normal_person)
    @contribution = Factory.create(:comment)
    @descriptor = Factory.create(:rating_descriptor)
    @descriptor2 = Factory.create(:rating_descriptor, :title => "Motivating")
    @rg = Factory.create(:rating_group, :contribution => @contribution, :person => @current_person)
    @rating = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor)
    @rating2 = Factory.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor2)
    @rating1b = Factory.create(:rating, :rating_descriptor => @descriptor)
  end

  it "should have a descriptor" do
    @rating.rating_descriptor.title.should == "Inspiring"
  end

  it "should display the descriptor when using the title shortcut" do
    @rating.title.should == "Inspiring"
  end

  # For Historical reasons, Commented out so we don't lose it as part of a git rebase
  #context "should total up the rating for a contribution" do
    #it "when using a text descriptor" do
      #Rating.descriptor_total_for_contribution(@contribution, "Inspiring").should == 2
    #end

    #it "when using a symbol descriptor" do
      #Rating.descriptor_total_for_contribution(@contribution, :Inspiring).should == 2
    #end

    #it "when using a descriptor object" do
      #Rating.descriptor_total_for_contribution(@contribution, @descriptor).should == 2
    #end

    #it "when there are no ratings for a descriptor" do
      #Rating.descriptor_total_for_contribution(@contribution, "Junk").should == nil
    #end
  #end

  #it "should return an array of summary rating results" do |variable|
    #Rating.by_contribution(@contribution).should == {@descriptor.title => 2, @descriptor2.title => 1}

    #Rating.by_contribution(nil).should == {}
  #end

  #it "should return a users ratings" do
    #Rating.where(:person_id => @current_person, :contribution_id => @contribution).collect do |x| x.rating_descriptor.title end.should == ["Inspiring", "Motivating"]
    #Rating.person_ratings_for_contribution(@current_person, @contribution).should == {"Inspiring"=>1, "Motivating"=>1}
  #end

  #context "should return a users ratings" do
    #it "when using a text descriptor" do
      #Rating.person_ratings_for_contribution_and_descriptor(@current_person, @contribution, "Inspiring").should == 1
    #end

    #it "when using a symbol descriptor" do
      #Rating.person_ratings_for_contribution_and_descriptor(@current_person, @contribution, :Inspiring).should == 1
    #end

    #it "when using a descriptor object" do
      #Rating.person_ratings_for_contribution_and_descriptor(@current_person, @contribution, @descriptor).should == 1
    #end

    #it "when there are no ratings for a descriptor" do
      #Rating.person_ratings_for_contribution_and_descriptor(@current_person, @contribution, "Junk").should == nil
    #end
  #end

  #context "topitemable" do
    ## Make Rating topitemable (TopItemableSpec)
    ## Rating shows up in recent activety stream
    ## TopItem.for(:rating) make it work...
  #end

end

