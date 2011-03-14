require 'parent_validator'

class Contribution < ActiveRecord::Base
  include Visitable
  include TopItemable

  # Needs :dependent => :destroy on nested_set to ensure top_items for
  # nested contributions are destroyed via callbacks
  acts_as_nested_set :exclude_unless => {:confirmed => true}, :dependent => :destroy
  profanity_filter :content, :method => 'hollow'

  ALL_TYPES = ["Answer","AttachedFile","Comment","EmbeddedSnippet","Link",
               "Question","SuggestedAction"]

  belongs_to :person, :foreign_key => "owner"
  belongs_to :conversation
  belongs_to :issue

  validates_with ContributionValidator
  validates :item, :presence=>true

  scope :most_recent, {:order => 'created_at DESC'}
  scope :not_top_level, where("#{quoted_table_name}.type != 'TopLevelContribution'")
  scope :without_parent, where(:parent_id => nil)
  scope :confirmed, where(:confirmed => true)
  scope :unconfirmed, where(:confirmed => false)
  # Scope for contributions that are still editable, i.e. no descendants and less than 30 minutes old
  scope :editable, where(["#{quoted_table_name}.created_at >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 30 MINUTE)"])
  scope :for_conversation, lambda { |convo|
    confirmed.
      where(:conversation_id => convo.id).
      includes([:person]).
      order('contributions.created_at ASC')
  }

  after_initialize :set_confirmed, :if => :new_record? # sets confirmed to false by default when object created
  before_validation :set_person_from_item, :if => :person_blank?

  attr_reader :override_confirmed

  def self.find_or_new_unconfirmed(params,person)
    attrs = {
      :conversation_id => params[:id],
      :parent_id => params[:contribution_id],
      :owner => person.id
    }
    return Contribution.unconfirmed.editable.where(attrs).first || Contribution.new(attrs)
  end

  def self.update_or_create_node_level_contribution(params,person)
    if contribution = Contribution.unconfirmed.where(:type => params[:type], :parent_id => params[:parent_id], :owner => person.id).first
      contribution.update_attributes(params)
    else 
      contribution = Contribution.create_node_level_contribution(params,person)
    end
    return contribution
  end

  def self.new_node_level_contribution(params, person)
    model, params = setup_node_level_contribution(params,person)
    model.new(params)
  end

  def self.new_confirmed_node_level_contribution(params, person)
    params.merge!(:override_confirmed => true)
    new_node_level_contribution(params, person)
  end

  def self.create_node_level_contribution(params, person)
    model, params = setup_node_level_contribution(params,person)
    contribution = model.create(params)
  end

  def self.create_confirmed_node_level_contribution(params, person)
    params.merge!(:override_confirmed => true)
    create_node_level_contribution(params, person)
  end

  def self.delete_old_unconfirmed_contributions(age=30.minutes)
    count = self.unconfirmed.where(["created_at < ?", (Time.now - age)]).count
    self.unconfirmed.destroy_all(["created_at < ?", (Time.now - age)])
    return count
  end

  def self.valid_attributes?(attributes)
    mock = self.new(attributes)
    unless mock.valid?
      return mock.errors.select{|k,v| attributes.keys.collect(&:to_sym).include?(k)}.size == 0
    end
    true
  end

  def item=(item)
    if item.is_a?(Conversation)
      self.conversation = item
    elsif item.is_a?(Issue)
      self.issue = item
    end
  end

  def item
    self.conversation || self.issue
  end

  def item_id
    self.conversation_id || self.issue_id
  end

  def item_class
    if conversation
      conversation.class.to_s
    elsif issue
      issue.class.to_s
    end
  end

  # Is this contribution an Image? Default to false, override in
  # subclasses
  def is_image?
    false
  end

  def suggestion?
    false
  end
  
  def unconfirmed?
    !self.confirmed
  end
  
  def confirm!
    self.update_attribute(:confirmed, true)
  end
  
  def destroy_by_user(user)
    if self.editable_by?(user)
      self.destroy
    else
      self.errors[:base] << "Contributions cannot be deleted if they are older than 30 minutes or have any responses."
      return false
    end
  end
  
  def update_attributes_by_user(params, user)
    params = params.select{ |k,v| ['content', 'url', 'attachment'].include?(k.to_s) && !v.blank? }
    if self.editable_by?(user)
      self.update_attributes(params)
    else
      self.errors[:base] << "Contributions cannot be edited if they are older than 30 minutes or have any responses."
      return false
    end
  end
  
  def editable_by?(user)
    return false if user.nil?
    (user.admin? || (self.owner == user.id && self.created_at > 30.minutes.ago)) && self.confirmed && self.descendants_count == 0
  end

  def moderate_contribution
    self.destroy_descendants

    self.destroy
    true
  end

  def attachment_url
    if self.attachment_file_name
      if self.is_image?
        attachment.url(:thumb).gsub(/\?\d+$/, '')
      else
        attachment.url.gsub(/\?\d+$/, '')
      end
    else
      ''
    end
  end
  
  def override_confirmed=(value)
    @override_confirmed = value
    self.confirmed = true if value
  end
  
  def contribution_type
    if self.you_tubeable?
      :video
    elsif self.suggestion?
      :suggestion
    elsif self.is_image?
      :image
    else
      self.type.underscore
    end
  end

  protected

  def self.setup_node_level_contribution(params,person)
    model = (params.delete(:type) || params.delete('type')).constantize
    # could probably do this much cleaner, but still need to sanitize this for now
    raise(ArgumentError, "not a valid node-level Contribution type") unless ALL_TYPES.include?(model.to_s)
    params.merge!({:person => person})
    return model,params
  end

  def top_level_contribution?
    self.class == TopLevelContribution
  end

  def set_confirmed
    self.confirmed = self.override_confirmed || self.top_level_contribution? ? true : 0
    # RAILS BUG - ActiveRecord::RecordNotSaved if set to false, but works for true, 1, and 0
  end

  def you_tubeable?
    false
  end

  def url_title
    if self.url
      self.title
    else
      ''
    end
  end

  def person_blank?
    self.person.blank?
  end

  def set_person_from_item
    self.person = item.person
  end
end
