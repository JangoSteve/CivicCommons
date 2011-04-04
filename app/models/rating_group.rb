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


  # Potential Direct SQL Query:
  #   SELECT RG.CONTRIBUTION_ID, RD.TITLE, COUNT(*)
  #     FROM RATING_GROUPS AS RG,
  #          RATINGS AS R,
  #          RATING_DESCRIPTORS AS RD
  #    WHERE RG.CONVERSATION_ID = 120
  #      AND RG.ID = R.RATING_GROUP_ID
  #      AND R.`RATING_DESCRIPTOR_ID` = RD.ID
  # GROUP BY CONTRIBUTION_ID,
  #          RATING_DESCRIPTOR_ID
  def self.ratings_for_conversation(conversation)
    rgs = RatingGroup.where(:conversation_id => conversation).includes(:ratings)

    rgs.collect{|rg| rg.ratings}.flatten.group_by(&:title)
  end

end
