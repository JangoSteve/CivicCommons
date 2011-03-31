class CreateRatingGroups < ActiveRecord::Migration
  def self.up
    create_table :rating_groups do |t|
      t.integer :person_id
      t.integer :conversation_id
      t.integer :contribution_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rating_groups
  end
end
