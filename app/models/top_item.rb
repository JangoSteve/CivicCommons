class TopItem < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  belongs_to :person

  before_create :set_item_created_at
  before_create :set_item_recent_visits, :if => :item_visitable?

  #scope :with_items_and_associations, includes(:item, {:item => :person}, {:item => :conversation}, {:item => :issue})

  # Eagerly loads associations for :item, {:item => :person}, {:item => :conversation}, and {:item => :issue}
  # Cannot be done normally with a scope because not all items have these associations.
  # We want to only load each association if it exists for that item, and skip it if not.
  #
  # ALWAYS include this as the last scope in a chain, because it must load all currently scoped top_items
  # in order to evaluate their associations, etc, so if you don't limit the number of top_items *before*
  # this scope method, it will eagerly load ALL top_items and associations
  # E.g.
  #   TopItem.limit(5).with_items_and_associations
  # DO NOT DO
  #   TopItem.with_items_and_associations.limit(5)
  def self.with_items_and_associations
    # Use AR to eagerly load items
    top_items = self.scoped.includes(:item)
    items = top_items.collect(&:item)

    # Manually load and attach person, conversation, and/or issue to each item
    class_to_reflection = {}
    [:person, :conversation, :issue].each do |assoc|
      class_to_reflection[assoc] ||= {}

      # Group all items in scope by their base_class type and return their reflection for given association (assoc)
      items.group_by { |item| class_to_reflection[assoc][item.class] ||= item.class.reflections[assoc]}.each do |reflection, _items|

        # If item has the reflection; i.e. given association (assoc) exists...
        if reflection

          # Set the foreign key for the given reflection
          column_id = reflection.options[:foreign_key] || "#{assoc}_id"

          # Eager-query for all associated records. E.g. Person.where(:id => [1,5,10])
          records = assoc.to_s.classify.constantize.where( :id => _items.collect{|i| i[column_id]}.uniq )

          # Now that all top_items.items and all associated records are cached, match them together
          # E.g. the following is essentially analogous to item.send("person=", records[1]), or item.person = records[1]
          _items.each do |_item|
            top_items.detect{|ti| ti.item_id == _item.id && ti.item_type == _item.class.base_class.name}.item.send( "#{assoc}=", records.detect{|p| p.id == _item[column_id]} )
          end
        end
      end
    end

    # Return all top_items with their included items and item associations
    return top_items
  end

  # Until we can upgrade to Arel 2.0, this method uses some workarounds, which make it
  # chainable on other scopes, but other scopes cannot be chained to it,
  # so only use this at the end of scope chains
  def self.for(for_item, options={})

    if for_item.is_a?(Hash)
      # e.g. :person => 35
      for_item_type = for_item.keys[0]       # :person
      for_item_id = for_item[for_item_type]  # 35
    else
      # e.g. :conversation
      for_item_type = for_item               # :conversation
      for_item_id = nil
    end

    # for :conversation means:
    # a) top_items[:item_type] or                        <= direct_items
    # b) top_items[:item][:conversation_id] IS NOT NULL  <= associated_items
    #
    # For :person means:
    # item has person and person_id = :person_id         <= direct_items only

    # direct_items
    direct_items = self.scoped.includes(:item).where(:item_type => for_item_type.to_s.classify)
    direct_items = direct_items.where(:item_id => for_item_id) if for_item_id

    # associated_items
    # Now we start building the SQL for selecting associated items.
    # This is done so we can select all associated items with a single LIMIT, etc.
    # even across polymorphic associations. So, let's get started...

    # `top_items` table
    top_items = TopItem.arel_table
    # Initialize our SQL string with the `top_items` table
    # Note this is actually an Arel::SelectManager instance (which has a +to_sql+ method)
    sql_builder = Arel::SelectManager.new(ActiveRecord::Base, top_items)
    where_builder = []

    # Select all item_types that exist in top_items table and loop through each to
    # manually join each polymorphic association's table
    TopItem.select(:item_type).group(:item_type).collect(&:item_type).each do |item|

      # Unless item already included in direct_items
      unless item == for_item_type.to_s

        # If item has for_item as an association
        for_item_association = item.constantize.reflect_on_association(for_item_type)
        if for_item_association

          # ...get association foreign_key
          for_item_column_id = for_item_association.options[:foreign_key] || "#{for_item_type}_id"

          item_table = Arel::Table.new(item.underscore.pluralize) # e.g. "Contribution" becomes `contributions` table

          # Unless association column doesn't exist on item_table,
          # like if it's a has_many :through association
          unless item_table[for_item_column_id].nil?

            wheres = []
            # WHERE `contributions`.`owner` = 35 -- if id was specified
            wheres << item_table[for_item_column_id].eq( for_item_id ) if for_item_id
            # WHERE `contributions`.#{option.key[0]} = #{option.value[0]} AND `contributions`.#{option.key[1]} = #{option.value[1]} AND... -- if options were given
            wheres << options.collect{ |key,value| item_table[key].eq( value ) }.reduce(:and) if options.size > 0
            if wheres.empty?
              join_type = Arel::Nodes::InnerJoin
            else
              where_builder << Arel::Nodes::Grouping.new(wheres) unless wheres.empty?
              join_type = Arel::Nodes::OuterJoin
            end

            sql_builder = sql_builder.
              join(item_table, join_type).                            # {INNER|LEFT OUTER} JOIN `contributions`
              on(                                                     #   ON
                 top_items[:item_id].eq( item_table[:id] ),           #   `top_items`.`item_id` = `contributions`.`id`
                 top_items[:item_type].eq( item.to_s.classify ),      #   AND `top_items`.`item_type` = "Contribution"
                 item_table[for_item_column_id].not_eq( nil )         #   AND `contributions`.owner IS NOT NULL
                )

          end
        end
      end
    end

    sql_builder.constraints << where_builder.reduce(:or) unless where_builder.empty?

    # At this point, we'd see:
    # sql_builder.to_sql
    # #=>
    # SELECT  FROM `top_items`
    # LEFT OUTER JOIN `contributions`
    #   ON `top_items`.`item_id` = `contributions`.`id`
    #   AND `top_items`.`item_type` = 'Contribution'
    #   AND `contributions`.`owner` IS NOT NULL
    # LEFT OUTER JOIN `conversations`
    #   ON `top_items`.`item_id` = `conversations`.`id`
    #   AND `top_items`.`item_type` = 'Conversation'
    #   AND `conversations`.`owner` IS NOT NULL
    # WHERE ((`contributions`.`owner` = 35) OR (`conversations`.`owner` = 35))

    #associated_items = TopItem.find_by_sql( top_items.to_sql )

    # This creates a relation so that this +for+ method is chainable, and also passes in any parameters,
    # such as +limit+, from the existing chain if the +for+ method is chained to a relation
    associated_items = ActiveRecord::Relation.new(self, sql_builder) & self.scoped

    # Hack needed to limit total items returned until above can be re-written with new Arel2 methods
    all_for_items = (direct_items | associated_items).sort_by(&:item_created_at).reverse
    all_for_items = all_for_items.first( self.scoped.limit_value ) if self.scoped.limit_value

    #p top_items.to_sql
    return all_for_items
  end

  def self.newest_items(limit=10)
    self.order("item_created_at DESC").limit(limit)
  end

  def TopItem.most_visited(limit=10)
    self.order("recent_visits DESC").limit(limit)
  end

  protected

  def item_visitable?
    self.item.respond_to?(:recent_visits)
  end

  def set_item_created_at
    self.item_created_at = self.item.created_at
  end

  def set_item_recent_visits
    self.recent_visits = self.item.recent_visits
  end
end
