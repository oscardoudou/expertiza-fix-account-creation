class PeerReviewGradeController < ApplicationController
  def action_allowed?
    true
  end

  def hello
    @message = "hello, here is hello function in PeerReviewGradeController"
    #teams = AssignmentTeam.where(:parent_id => 724)
    teams = AssignmentTeam.where(:parent_id => 733)
    teams.each do |team|
      quiz_questionnaire = QuizQuestionnaire.where(:instructor_id => team.id).first rescue nil

      if quiz_questionnaire # if this team created a quiz, find the response of this quiz.
        quiz_response_maps = QuizResponseMap.where(:reviewee_id => team.id)
        if !quiz_response_maps.empty?
          quiz_response_maps.each do |quiz_response_map|
            if !quiz_response_map.quiz_score.eql?("N/A")
              #update the peer_review_grade table
              quiz_taker_participant= Participant.find(quiz_response_map.reviewer_id)
              quiz_taker_user_id = quiz_taker_participant.user_id
              peer_review_grade = PeerReviewGrade.where(:submission_id => team.id, :reviewer_id => quiz_taker_user_id, :round => 2).first
              if peer_review_grade
                peer_review_grade.quiz_score = quiz_response_map.quiz_score
                peer_review_grade.save
              end
            end

          end
        end
      end

    end
  end

  def comparison
    teams_b = AssignmentTeam.where(:parent_id => 733)
    teams_a = AssignmentTeam.where(:parent_id => 724)
    teams = teams_a + teams_b
    @report = Hash.new
    teams.each do |team|
      peer_review_scores = []
      sum_repu_hamer=0
      sum_repu_lauw=0
      sum_weighted_score_hamer=0
      sum_weighted_score_lauw=0
      sum_quiz_score=0
      sum_weighted_score_quiz=0

      peer_review_grades = PeerReviewGrade.where(:submission_id => team.id, :round => 2) # only do this for round 2
      if !peer_review_grades.empty?

        peer_review_grades.each do |peer_review_grade_record|
          peer_review_scores << peer_review_grade_record.total_score

          sum_repu_hamer += peer_review_grade_record.repu_hamer
          sum_repu_lauw += peer_review_grade_record.repu_lauw

          if peer_review_grade_record.quiz_score && peer_review_grade_record.quiz_score>=80  # quiz got 80+
            sum_quiz_score+= peer_review_grade_record.quiz_score
            sum_weighted_score_quiz+= peer_review_grade_record.quiz_score*peer_review_grade_record.total_score
          elsif peer_review_grade_record.quiz_score.nil?  # no quiz score
            sum_quiz_score+= 20.0
            sum_weighted_score_quiz+= 20.0*peer_review_grade_record.total_score
          else
            sum_quiz_score+= peer_review_grade_record.quiz_score  # quiz got 80-
            sum_weighted_score_quiz+= peer_review_grade_record.quiz_score*peer_review_grade_record.total_score
          end

          sum_weighted_score_hamer = peer_review_grade_record.repu_hamer*peer_review_grade_record.total_score
          sum_weighted_score_lauw = peer_review_grade_record.repu_lauw*peer_review_grade_record.total_score

        end

        median_peer_review_score = median(peer_review_scores)
        aggregated_by_hamer = sum_repu_hamer!=0? (sum_weighted_score_hamer/sum_repu_hamer) : "N/A"
        aggregated_by_lauw = sum_repu_lauw!=0? (sum_weighted_score_lauw/sum_repu_lauw) : "N/A"
        aggregated_by_quiz = sum_quiz_score!=0? (sum_weighted_score_quiz/sum_quiz_score) : "N/A"
        num_review_done = peer_review_grades.size
        num_quiz_done = peer_review_grades.reject {|a| a.quiz_score.nil?}.size

        current_team_report ={"team_id"=>team.id, "median"=>median_peer_review_score, "agg_hamer"=>aggregated_by_hamer, "agg_lauw"=>aggregated_by_lauw,
                              "agg_quiz"=>aggregated_by_quiz, "num_review"=>num_review_done,"num_quiz"=>num_quiz_done}
        @report[team.id]= current_team_report
      end
    end
  end

  def median(array)
    sorted = array.sort
    len = sorted.length
    return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
