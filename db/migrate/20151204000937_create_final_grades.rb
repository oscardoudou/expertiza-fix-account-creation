class CreateFinalGrades < ActiveRecord::Migration
  def change
    create_table :final_grades do |t|
      t.integer :team_id
      t.string :team_name
      t.integer :final_grade

      t.timestamps null: false
    end
  end
end
