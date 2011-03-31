class CreateNewRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.integer :rating_group_id
      t.integer :rating_descriptor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :ratings
  end
end
