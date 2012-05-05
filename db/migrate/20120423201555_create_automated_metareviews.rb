class CreateAutomatedMetareviews < ActiveRecord::Migration
  def self.up
    create_table :automated_metareviews do |t|
      t.String :relevance
      t.String :content
      t.String :tone
      t.String :quantity
      t.String :plagiarism
      t.integer :response_id
      
      t.timestamps
    end
  end
  
  execute 'ALTER TABLE `automated_metareviews`
             ADD CONSTRAINT fk_responses_id
             FOREIGN KEY (response_id) REFERENCES responses(id)'
             
  def self.down
    drop_table :automated_metareviews
  end
end
