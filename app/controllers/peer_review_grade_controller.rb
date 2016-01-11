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


        median_peer_review_score_r1 = median_peer_review_score(team.id,1)
        median_peer_review_score_r2 = median_peer_review_score(team.id,1)
        aggregated_by_hamer_r1 = aggregate_for_round(team.id,1,"hamer")
        aggregated_by_hamer_r2 = aggregate_for_round(team.id,2,"hamer")
        aggregated_by_lauw_r1 = aggregate_for_round(team.id,1,"lauw")
        aggregated_by_lauw_r2 = aggregate_for_round(team.id,2,"lauw")
        aggregated_by_quiz = aggregate_for_round(team.id,2,"quiz")
        num_review_done_r1 = num_review_done_in_round(team.id,1)
        num_review_done_r2 = num_review_done_in_round(team.id,2)
        num_quiz_done = num_quiz_done(team.id)
        final_grade = FinalGrade.where(team_id:team.id).first.final_grade rescue 'N/A'

        current_team_report ={"team_id"=>team.id, "median_r1"=>median_peer_review_score_r1,"median_r2"=>median_peer_review_score_r2,
                              "agg_hamer_r1"=>aggregated_by_hamer_r1, "agg_hamer_r2"=>aggregated_by_hamer_r2,
                              "agg_lauw_r1"=>aggregated_by_lauw_r1,"agg_lauw_r2"=>aggregated_by_lauw_r2,
                              "agg_quiz"=>aggregated_by_quiz,
                              "num_review_r1"=>num_review_done_r1,"num_review_r2"=>num_review_done_r2,
                              "num_quiz"=>num_quiz_done,"final_grade"=>final_grade}
        @report[team.id]= current_team_report

    end
  end

  private
  def num_quiz_done(team_id)
    peer_review_grades = PeerReviewGrade.where(:submission_id => team_id, :round => 2)
    peer_review_grades.reject {|a| a.quiz_score.nil?}.size
  end

  def num_review_done_in_round(team_id,round)
    peer_review_grades = PeerReviewGrade.where(:submission_id => team_id, :round => round)
    peer_review_grades.size
  end

  def median_peer_review_score (team_id,round)
    peer_review_scores = []
    peer_review_grades = PeerReviewGrade.where(:submission_id => team_id, :round => round)
    if !peer_review_grades.empty?

      peer_review_grades.each do |peer_review_grade_record|
        peer_review_scores << peer_review_grade_record.total_score
      end
    end
    median(peer_review_scores)
  end

  def median(array)
    if array.empty?
      return 'N/A'
    end
    sorted = array.sort
    len = sorted.length
    return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def aggregate_for_round (team_id, round,algorithm)
    peer_review_grades = PeerReviewGrade.where(:submission_id => team_id, :round => round)
    if peer_review_grades.empty?
      return 'N/A'
    end
    sum_repu=0
    sum_weighted_score=0

    peer_review_grades.each do |peer_review_grade|
      if algorithm=="hamer"
        sum_repu += peer_review_grade.repu_hamer
        sum_weighted_score += peer_review_grade.repu_hamer * peer_review_grade.total_score
      elsif algorithm=="lauw"
        sum_repu += peer_review_grade.repu_lauw
        sum_weighted_score += peer_review_grade.repu_lauw * peer_review_grade.total_score
      elsif algorithm=="quiz"
        if peer_review_grade.quiz_score && peer_review_grade.quiz_score>=80  # quiz got 80+
          sum_repu+= peer_review_grade.quiz_score
          sum_weighted_score+= peer_review_grade.quiz_score*peer_review_grade.total_score
        elsif peer_review_grade.quiz_score.nil?  # no quiz score
          sum_repu+= 20.0
          sum_weighted_score+= 20.0*peer_review_grade.total_score
        else
          sum_repu+= peer_review_grade.quiz_score  # quiz got 80-
          sum_weighted_score+= peer_review_grade.quiz_score*peer_review_grade.total_score
        end
      end
    end

    if sum_repu!=0
      return sum_weighted_score / sum_repu
    else
      return "N/A"
    end

  end
end
