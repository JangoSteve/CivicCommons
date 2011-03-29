class Rating < ActiveRecord::Base
  include TopItemable

  belongs_to :person # who made this rating
  belongs_to :contribution
  belongs_to :rating_descriptor

  delegate :title, :to => :rating_descriptor

  scope :group_by_contribution, lambda { |contribution|
    joins(:rating_descriptor).
    where(:contribution_id => contribution).
    group('rating_descriptors.title')
  }

  scope :group_by_rating_descriptor, lambda {
    joins(:rating_descriptor).
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
