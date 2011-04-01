class Rating < ActiveRecord::Base

  belongs_to :rating_descriptor
  belongs_to :rating_group

  delegate :person,
           :contribution, :to => :rating_group

  delegate :title, :to => :rating_descriptor
  delegate :name, :to => :person

  scope :group_by_contribution, lambda { |contribution|
    joins(:rating_descriptor).joins(:rating_group)
    where(:contribution_id => contribution).
    group('rating_descriptors.title')
  }

  scope :group_by_rating_descriptor, lambda {
    joins(:rating_descriptor).joins(:rating_group)
    group('rating_descriptors.title')
  }

  def self.by_all_contributions
    group_by_rating_descriptor.count
  end

  def self.by_contribution(contribution)
    group_by_contribution(contribution).count
  end

  def self.person_ratings_for_contribution(person, contribution)
    group_by_contribution(contribution).where(:person_id => person).count
  end

  def self.person_ratings_for_contribution_and_descriptor(person, contribution, descriptor)
    descriptor_title = descriptor.respond_to?(:title) ? descriptor.title : descriptor.to_s
    group_by_contribution(contribution).where(:person_id => person).count[descriptor_title]
  end

  def self.descriptor_total_for_contribution(contribution, descriptor)
    descriptor_title = descriptor.respond_to?(:title) ? descriptor.title : descriptor.to_s
    group_by_contribution(contribution).count[descriptor_title]
  end
end
