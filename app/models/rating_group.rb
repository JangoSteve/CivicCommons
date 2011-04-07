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

    returning Hash.new do |hash|
      RatingGroup.rating_descriptors.values.collect{ |rd_title| hash[rd_title] = [] }
    end.merge( rgs.collect{|rg| rg.ratings}.flatten.group_by(&:title) )
  end

  def self.ratings_for_conversation_with_count(conversation)
    rgs = ratings_for_conversation(conversation)

    RatingGroup.rating_descriptors.values.each{|rd_title| rgs[rd_title] = rgs[rd_title].count}
    rgs
  end

  def self.ratings_for_conversation_by_contribution_with_count(conversation, person=nil)
    person = person.is_a?(Person) ? person.id : person
    # First get the Rating Group that is associated with each Contribution
    #   Contribution_id => [Rating Group(s)]
    rgs       = RatingGroup.scoped
    rgs       = rgs.where(:conversation_id => conversation).includes(:ratings).all
    contribution_ids = rgs.collect(&:contribution_id).uniq
    ratings = rgs.collect(&:ratings)

    default_ratings_hash = returning Hash.new do |hash|
      RatingGroup.rating_descriptors.each do |rd_id, rd_title|
        hash[rd_title] = {
          :total => 0,
          :person => false
        }
      end
    end

    default_contribution_hash = Hash.new do |hash, key|
      hash[key] = default_ratings_hash
    end

    # Start with new Hash #=> {}
    out = contribution_ids.each.inject(default_contribution_hash) do |h, contribution_id|
      contribution_rgs = rgs.select{ |rg| rg.contribution_id == contribution_id }
      contribution_person_ratings = contribution_rgs.select{ |rg| rg.person_id == person }.collect(&:ratings).flatten if person
      # Populate hash with each unique contribution_id as a key #=> { 1 => {}, 2 => {} }
      contribution_hash = returning Hash.new do |h2|
        # Populate each contribution_id value hash with rating_descriptor keys
        # e.g. { 1 => { 'some-descriptor' => ... }, 2 => { 'some-descriptor' => ... } }
        RatingGroup.rating_descriptors.each do |rd_id, rd_title|
          # Populate each rating_descriptor value with hash of total and person ratings
          h2[rd_title] = {
            :total => contribution_rgs.collect(&:ratings).flatten.count{|r| r.rating_descriptor_id == rd_id },
            :person => person ? contribution_person_ratings.any?{ |r| r.rating_descriptor_id == rd_id } : nil
          }
        end
      end
      h.merge(contribution_id => contribution_hash)
    end
  end

  def self.rating_descriptors
    # Builds { 1 => 'Appropriate', 2 => 'Inspiring', ... }
    @rating_desciptors ||= Hash[*RatingDescriptor.select([ :id, :title ]).map{ |m| [m.id, m.title]}.flatten]
  end
end
