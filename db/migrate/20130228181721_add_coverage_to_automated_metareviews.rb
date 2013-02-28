class AddCoverageToAutomatedMetareviews < ActiveRecord::Migration
  def self.up
    add_column :automated_metareviews, :coverage, :float
  end

  def self.down
    remove_column :automated_metareviews, :coverage
  end
end
