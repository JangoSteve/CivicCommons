class CreateNewRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.integer :person_id
      t.integer :contribution_id
      t.integer :rating_descriptor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :ratings
  end
end
