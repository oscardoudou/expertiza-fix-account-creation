class CreateAutomatedMetareviews < ActiveRecord::Migration
  def self.up
    create_table :automated_metareviews do |t|
      t.text :relevance
      t.text :content
      t.text :tone
      t.text :quantity
      t.text :plagiarism
      t.text :response_id
      
      t.timestamps
    end
  end
  
  # execute 'ALTER TABLE `automated_metareviews`
             # ADD CONSTRAINT fk_responses_id
             # FOREIGN KEY (response_id) REFERENCES responses(id)'
             
  def self.down
    drop_table :automated_metareviews
  end
end
