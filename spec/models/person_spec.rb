require 'spec_helper'

describe Person do

  describe "when parsing the name" do
    it "should parse simple name" do
      first, last = Person.parse_name("John Doe")
      first.should == "John"
      last.should == "Doe"
    end
    
    it "should have blank last name when missing" do
      first, last = Person.parse_name("John")
      first.should == "John"
      last.should == ""
    end
    
    it "should handle complex last name" do
      first, last = Person.parse_name("John van Buren")
      first.should == "John"
      last.should == "van Buren"
    end

    it "should handle multi names" do
      first, last = Person.parse_name("Gladys s.w. Lum")
      first.should == "Gladys"
      last.should == "s.w. Lum"
    end
  end

  describe "when finding all by name" do

    def given_a_person_with_name(name)
      person = Factory.create(:normal_person)
      person.name = name
      person.password = "password"
      person.email = "wendy@example.com"
      person.save!
      person
    end

    it "should find when only first name exists" do
      person = given_a_person_with_name "Wendy"
      Person.find_all_by_name("Wendy").should == [person]
    end
    
    it "should find when first and last name" do
      person = given_a_person_with_name "Wendy Smith"
      Person.find_all_by_name("Wendy Smith").should == [person]
    end

    it "should find when first and last has prefix" do
      person = given_a_person_with_name "Wendy van Buren"
      Person.find_all_by_name("Wendy van Buren").should == [person]
    end
  end
  
  describe "when setting the name" do
    it "should split the entry into first name and last name" do
      person = Factory.create(:normal_person)
      person.name = "John Doe"
      person.first_name.should == "John"
      person.last_name.should == "Doe"
    end
  end
  
  describe "when displaying a name" do
    it "should properly capitalize a persons name" do
      person = Factory.create(:normal_person)
      person.first_name = "ektor"
      person.last_name = "van capsula"
      person.name.should == "Ektor Van Capsula"
    end
    
    it "should display names without leading spaces when the first name is missing" do
      person = Factory.create(:normal_person)
      person.first_name = ""
      person.last_name = "van capsula"
      person.name.should == "Van Capsula"
    end
    
    it "should display names without trailing spaces when the last name is missing" do
      person = Factory.create(:normal_person)
      person.first_name = "ektor"
      person.last_name = ""
      person.name.should == "Ektor"
    end
  end


  it "creates a shadow account after saving" do
    person = Person.new(Factory.attributes_for(:person_with_shadow_account))
    PeopleAggregator::Person.stub!(:create).and_return(OpenStruct.new(id: 42))
    person.save
    person.people_aggregator_id.should == 42
  end


  it "doesn't create a shadow account when there are errors" do
    person = Person.new(Factory.attributes_for(:person_with_shadow_account))

    PeopleAggregator::Person.stub(:create) do
      raise PeopleAggregator::Error.new("There was an error saving this person.")
    end

    lambda { person.save }.should raise_error(ActiveRecord::RecordNotSaved)
    person.errors[:person].should include("There was an error saving this person.")

  end


end
