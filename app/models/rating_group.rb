class RatingGroup < ActiveRecord::Base

  include TopItemable

  belongs_to :person
  belongs_to :conversation
  belongs_to :contribution
  has_many   :ratings, :dependent => :destroy

  before_create :set_conversation_id

  validates_uniqueness_of :person_id, :scope => :contribution_id

  scope :group_by_contribution, lambda { |contribution|
    joins(:rating_descriptor).joins(:rating_group).
    where(:contribution_id => contribution).
    group('rating_descriptors.title')
  }



  def set_conversation_id
    self.conversation_id = contribution.conversation_id if conversation_id.blank?
  end

  def self.add_rating!(person, contribution, descriptor)
    rg = RatingGroup.find_or_create_by_person_id_and_contribution_id(person.id, contribution.id)
    rg.ratings.create(:rating_descriptor => descriptor)
  end

  def ratings_titles
    self.ratings.collect(&:title)#.to_sentance
  end





end
