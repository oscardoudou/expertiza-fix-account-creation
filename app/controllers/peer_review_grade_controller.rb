class PeerReviewGradeController < ApplicationController
  def action_allowed?
    true
  end

  def hello
    @message = "hello, here is hello function in PeerReviewGradeController"
    teams = AssignmentTeam.where(:parent_id => 724)
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
end
