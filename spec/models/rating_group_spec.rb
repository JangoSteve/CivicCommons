require 'spec_helper'

describe RatingGroup do
  before(:each) do
    @current_person = Factory.create(:normal_person)
    @contribution = Factory.create(:comment)
    @descriptor = Factory.create(:rating_descriptor)
    @descriptor2 = Factory.create(:rating_descriptor, :title => "Motivating")
    @rating = Factory.create(:rating, :contribution => @contribution, :person => @current_person, :rating_descriptor => @descriptor)
    @rating2 = Factory.create(:rating, :contribution => @contribution, :person => @current_person, :rating_descriptor => @descriptor2)
    @rating1b = Factory.create(:rating, :contribution => @contribution, :rating_descriptor => @descriptor)
  end

end
