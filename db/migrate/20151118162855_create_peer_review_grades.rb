class CreatePeerReviewGrades < ActiveRecord::Migration
  def self.up
    create_table :peer_review_grades do |t|
	t.integer :reviewer_id
	t.integer :submission_id
	t.float :total_score
	t.integer :round
	t.float :quiz_score
	t.float :repu_hamer
	t.float :repu_lauw      
    end
  end

  def self.down
    drop_table :peer_review_grades
  end
end
