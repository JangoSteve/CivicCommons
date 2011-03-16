class CreateRatingDescriptors < ActiveRecord::Migration
  def self.up
    create_table :rating_descriptors do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :rating_descriptors
  end
end
