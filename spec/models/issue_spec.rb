require 'spec_helper'

describe Issue do
  def given_an_issue_with_contributions_and_conversations_and_page_visits
    @issue = Factory.create(:issue)
    @contribution = Factory.create(:contribution,:issue => @issue)
    @conversation = Factory.create(:conversation,:issues => [@issue])
    @issue.visits << Factory.create(:visit)
  end
  def given_2_issues_with_contributions_and_visits
    @issue1 = Factory.create(:issue)
    Factory.create(:contribution,:issue => @issue1)
    @issue1.visits << Factory.create(:visit)
    
    @issue2 = Factory.create(:issue)
    Factory.create(:contribution,:issue => @issue2)
    Factory.create(:contribution,:issue => @issue2)
    @issue2.visits << Factory.create(:visit)
    @issue2.visits << Factory.create(:visit)
  end
  context "Top Issues" do
    it "should be determined by total # of contributions to an Issue + total # of page visits." do
      pending
      given_2_issues_with_contributions_and_visits
      Issue.top_issues.should == [@issue2,@issue1]
    end  
  end
  context "Featured Issues" do
    it "are editorially set." do
      pending
    end
  end
  context "counters" do
    it "should have the correct count of contributions" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.contributions.count.should == 1
    end
    it "should have the correct count of conversations" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.conversations.count.should == 1
    end
    it "should have visit counts" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.visits.count.should == 1
    end
  end
  context "Sort filter" do
    def given_3_issues
      @issue1 = Factory.create(:issue, :description => 'A first issue')
      @issue2 = Factory.create(:issue, :description => 'Before I had a problem')
      @issue3 = Factory.create(:issue, :description => 'Cat in the bag')
    end
    it "should sort issue by alphabetical" do
      given_3_issues
      Issue.sort('alphabetical').should == [@issue1, @issue2, @issue3]
    end
    it "should sort issue by date created" do
      given_3_issues
      Issue.sort('most_recent').should == [@issue3, @issue2, @issue1]
    end
    it "should sort issue by recently updated" do
      given_3_issues
      @issue1.touch
      @issue2.touch
      @issue3.touch
      Issue.sort('most_recent_update').should == [@issue3, @issue2, @issue1]      
    end
    it "should sort issue by region" do
      pending
    end
  end
end
