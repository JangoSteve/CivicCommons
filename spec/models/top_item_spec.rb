require File.dirname(__FILE__) + '/../spec_helper'

describe TopItem, "when retrieving the top items by date" do
  before(:each) do
    @seven_day_contribution = Factory.create(:top_level_contribution, {:created_at=>(Time.now - 7.days), :title => "Seven Day Contribution"})
    @three_day_contribution = Factory.create(:top_level_contribution, {:created_at=>(Time.now - 3.days), :title => "Three Day Contribution"})
    @today_contribution = Factory.create(:top_level_contribution, {:created_at=>Time.now, :title => "Today Contribution"})

    @seven_day_conversation = Factory.create(:conversation, {:created_at=>(Time.now - 7.days), :summary => "Seven Day Conversation"})
    @three_day_conversation = Factory.create(:conversation, {:created_at=>(Time.now - 3.days), :summary => "Three Day Conversation"})
    @today_conversation = Factory.create(:conversation, {:created_at=>Time.now, :summary => "Today Conversation"})

    @seven_day_issue = Factory.create(:issue, {:conversations=>[@seven_day_conversation], :created_at=>(Time.now - 7.days), :name => "Seven Day Issue"})
    @three_day_issue = Factory.create(:issue, {:conversations=>[@three_day_conversation], :created_at=>(Time.now - 3.days), :name => "Three Day Issue"})
    @today_issue = Factory.create(:issue, {:conversations=>[@today_conversation], :created_at=>Time.now, :name => "Today Issue"})
  end

  it "should return the number passed in" do
    result = TopItem.limit(5).newest_items(5).all.count
    result.should == 5
  end

  it "should return 10 items if no limit is passed in" do
    result = TopItem.newest_items.all.count
    result.should == 10
  end

  it "should merge top itemable items" do
    result = TopItem.newest_items.includes(:item)
    items = result.collect{ |ti| ti.item }
    old_top_items = TopItem.order("item_created_at ASC").includes(:item).limit(TopItem.all.size - 10)

    items.include?(@today_conversation).should == true
    items.include?(@today_contribution).should == true
    items.include?(@today_issue).should == true
  end

end

describe TopItem, "when retrieving the top items by number of visits" do
  before(:each) do
    @ten_visit_conversation = Factory.create(:conversation, {:recent_visits=>10})
    @five_visit_conversation = Factory.create(:conversation, {:recent_visits=>5})
    @one_visit_conversation = Factory.create(:conversation, {:recent_visits=>1})
    Conversation.stub(:get_top_visited).and_return([@ten_visit_conversation, @five_visit_conversation, @one_visit_conversation])

    @ten_visit_contribution = Factory.create(:contribution, {:recent_visits=>10})
    @five_visit_contribution = Factory.create(:contribution, {:recent_visits=>5})
    @one_visit_contribution = Factory.create(:contribution, {:recent_visits=>1})
    Comment.stub(:get_top_visited).and_return([@ten_visit_contribution, @five_visit_contribution, @one_visit_contribution])

    @ten_visit_issue = Factory.create(:issue, {:recent_visits=>10})
    @five_visit_issue = Factory.create(:issue, {:recent_visits=>5})
    @one_visit_issue = Factory.create(:issue, {:recent_visits=>1})
    Issue.stub(:get_top_visited).and_return([@ten_visit_issue, @five_visit_issue, @one_visit_issue])
  end

  it "should merge all visitable types" do
    result = TopItem.most_visited
    items = result.collect{ |ti| ti.item }

    items.include?(@ten_visit_conversation).should == true
    items.include?(@ten_visit_contribution).should == true
    items.include?(@ten_visit_issue).should == true
  end

  it "should return the number passed in" do
    result = TopItem.most_visited(5).all.count
    result.should == 5
  end

  it "should return 10 items if no limit is passed in" do
    result = TopItem.most_visited.all.count
    result.should == 10
  end
end

describe TopItem, "when retrieving top items for specific polymorphic association" do
  before(:each) do
    @conversation = Factory.create(:conversation)
    # @issue.id set below to @convo id for spec on #with_items_and_associations that ensures associations are matched to correct items without being mixed up
    @issue = Factory.create(:issue, :id => @conversation.id)

    @person = Factory.create(:normal_person)
    @conversation_comment = Factory.create(:contribution, :conversation => @conversation, :person => @person)
    @issue_comment = Factory.create(:issue_contribution, :issue => @issue, :person => @person)
    @conversation_question = Factory.create(:question, {:content => "oh hai?", :override_confirmed => true, :created_at => 1.hour.ago})
  end
  it "returns direct top_items for specified type" do
    result = TopItem.for(:conversation)
    items = result.collect{ |ti| ti.item }

    items.should include(@conversation)
    items.should_not include(@issue)
  end
  it "returns indirect items from specified type" do
    result = TopItem.for(:conversation)
    items = result.collect{ |ti| ti.item }

    items.should include(@conversation_comment)
    items.should include(@conversation_question)
    items.should_not include(@issue_comment)
  end
  it "returns only items from specified item by id" do
    result = TopItem.newest_items(10).for(:conversation => @conversation.id)
    items = result.collect{ |ti| ti.item }

    items.should include(@conversation)
    items.should include(@conversation_comment)
    items.should_not include(@conversation_question)
    items.should_not include(@conversation_question.conversation)
  end
  it "returns only items from specified items by conditions" do
    result = TopItem.for(:conversation, {:content => "oh hai?", :type => :question})
    items = result.collect{ |ti| ti.item }

    items.should include(@conversation_question)
    items.should_not include(@conversation_comment)
  end
  it "returns all items for a specified person" do
    result = TopItem.for(:person => @person.id)
    items = result.collect{ |ti| ti.item }

    items.should include(@conversation_comment)
    items.should include(@issue_comment)
    items.should_not include(@conversation_question)
  end
  it "is chainable from an Arel scope when #for used" do
    result = []
    lambda {
      result = TopItem.limit(2).for(:conversation)
    }.should_not raise_error
    result.size.should == 2
  end
  it "allows Arel scopes to be chained to it when #for used" do
    # Would need to include direct_items in same ActiveRecord::Relation
    # as associated_items, so that a single Relation object could be
    # returned from TopItem#for. However, for that to work, would need
    # to use Arel's Where#or method, which doesn't work until Arel 2.0,
    # so gem would need to be updated.
    pending "Would need to upgrade to Arel 2.0 to implement this"
    result = []
    lambda {
      result = TopItem.for(:conversation).limit(2)
    }.should_not raise_error
    result.size.should == 2
  end
  it "eagerly loads associations on item polymorphic associations when they exist, and doesn't error if they don't" do
    lambda {
      result = TopItem.with_items_and_associations.collect(&:item)
    }.should_not raise_error
  end
  it "matches polymorphic association items with correct item associations" do
    result = TopItem.with_items_and_associations
    items = result.collect(&:item)
    items.each do |item|
      item.changed?.should be_false
    end
  end
end
