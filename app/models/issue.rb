class Issue < ActiveRecord::Base
  include Rateable
  include Visitable
  include TopItemable
  
  belongs_to :person

  has_and_belongs_to_many :conversations
  # Contributions directly related to this Issue
  has_many :contributions
  has_many :comments
  has_many :suggested_actions
  has_many(:media_contributions, :class_name => "Contribution",
           :conditions => "type = 'Link' or type = 'AttachedFile'")
  
  
  # Anyone who has contributed directly to the issue via a contribution
  has_many(:participants,
           :through => :contributions,
           :source => :person,
           :uniq => true)
  
  validates :name, :presence => true, :length => { :minimum => 5 }  
  
  
  scope(:most_active, :select =>
        'count(1) as contribution_count, issues.*',
        :joins => [:contributions],
        :group => "issues.id",
        :order => 'contribution_count DESC')
  
  scope :most_recent, {:order => 'created_at DESC'}
  scope :most_recent_update, {:order => 'updated_at DESC'}
  scope :alphabetical, {:order => 'name ASC'}
  scope :sort, lambda { |sort_type|
      case sort_type
      when 'most_recent'
        most_recent
      when 'alphabetical'
        alphabetical
      when 'most_recent_update'
        most_recent_update
      when 'most_active'
        most_active
      end
    }
  
end
