module TopItemable

  def self.included(base)
    base.has_one :top_item, :as => :item, :dependent => :destroy
    base.after_create :create_top_item, :unless => :record_has_confirmed_set_to_false?
    base.after_save :create_top_item, :if => :record_was_just_confirmed?
  end

  def record_has_confirmed_set_to_false?
    self.respond_to?(:confirmed) && !self.confirmed
  end

  def record_was_just_confirmed?
    self.respond_to?(:confirmed) && self.confirmed_changed? && self.confirmed
  end

end
