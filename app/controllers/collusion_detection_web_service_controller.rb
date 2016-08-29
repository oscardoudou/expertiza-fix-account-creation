require 'json'
require 'uri'
require 'net/http'
require 'openssl'
require 'base64'

class CollusionDetectionWebServiceController < ApplicationController
  @@request_body = ''
  @@response_body = ''
  @@assignment_id = ''
  @@another_assignment_id = ''
  @@round_num = ''
  @@additional_info = ''
  @@response = ''

  def action_allowed?
    ['Super-Administrator',
     'Administrator',
     'Instructor',
     'Teaching Assistant'].include? current_role_name
  end

  # normal db query, return peer review grades
  def db_query(assignment_id, round_num, has_topic, another_assignment_id = 0)
    actors = []
    raw_data_array = []
    assignment_ids = []
    assignment_ids << assignment_id
    assignment_ids << another_assignment_id unless another_assignment_id.zero?
    ReviewResponseMap.where(['reviewed_object_id in (?) and calibrate_to = ?', assignment_ids, false]).each do |response_map|
      reviewer = response_map.reviewer.user
      team = AssignmentTeam.find(response_map.reviewee_id)
      topic_condition = ((has_topic and SignedUpTeam.where(team_id: team.id).first.is_waitlisted == false) or !has_topic)
      last_valid_response = response_map.response.select {|r| r.round == round_num }.sort.last
      next unless topic_condition == true and !last_valid_response.nil?
      answers = Answer.where(response_id: last_valid_response.id)
      max_question_score = answers.first.question.questionnaire.max_question_score
      temp_sum = 0
      weight_sum = 0
      valid_answer = answers.select {|a| a.question.type == 'Criterion' and !a.answer.nil? }
      next if valid_answer.empty?
      valid_answer.each do |answer|
        temp_sum += answer.answer * answer.question.weight
        weight_sum += answer.question.weight
      end

      peer_review_grade = (100.0 * temp_sum / (weight_sum * max_question_score)).round(2)
      team.teams_users.each do |teams_user|
        user_name = User.find(teams_user.user_id).name 
        raw_data_array << {"reviewer_actor_id" => reviewer.name,
                           "reviewee_actor_id" => user_name,
                           "score"             => peer_review_grade} 
        actors << {"id" => user_name}
      end
    end
    [raw_data_array, actors]
  end

  def json_generator(assignment_id, another_assignment_id = 0, round_num = 2)
    assignment = Assignment.find_by_id(assignment_id)
    has_topic = !SignUpTopic.where(assignment_id: assignment_id).empty?
    @results, @actors = db_query(assignment.id, round_num, has_topic, another_assignment_id)
    request_body = {"actors" => @actors, "crituques" => @results}
  end

  def client
    @request_body = @@request_body
    @response_body = @@response_body
    @max_assignment_id = Assignment.last.id
    @assignment = Assignment.find(@@assignment_id) rescue nil
    @another_assignment = Assignment.find(@@another_assignment_id) rescue nil
    @round_num = @@round_num
    @response = @@response
  end

  def send_post_request
    # https://www.socialtext.net/open/very_simple_rest_in_ruby_part_3_post_to_create_a_new_workspace
    req = Net::HTTP::Post.new('/collusion_detection', initheader = {'Content-Type' => 'application/json', 'charset' => 'utf-8'})
    curr_assignment_id = (params[:assignment_id].empty? ? '724' : params[:assignment_id])
    req.body = json_generator(curr_assignment_id, params[:another_assignment_id].to_i, params[:round_num].to_i).to_json
    @@assignment_id = params[:assignment_id]
    @@round_num = params[:round_num]
    @@another_assignment_id = params[:another_assignment_id]

    # Eg.
    # {
    #   "actors": [
    #     {"id": "Myriel"},
    #     {"id": "Napoleon"},
    #     {"id": "Mlle.Baptistine"},
    #     {"id": "Mme.Magloire"},
    #     {"id": "CountessdeLo"}
    #   ],
    #   "crituques": [
    #     {"reviewer_actor_id": "Napoleon", "reviewee_actor_id": "Myriel", "score": 91},
    #     {"reviewer_actor_id": "Mlle.Baptistine", "reviewee_actor_id": "Myriel", "score": 81},
    #     {"reviewer_actor_id": "Mme.Magloire", "reviewee_actor_id": "Myriel", "score": 100},
    #     {"reviewer_actor_id": "Mme.Magloire", "reviewee_actor_id": "Mlle.Baptistine", "score": 64},
    #     {"reviewer_actor_id": "CountessdeLo", "reviewee_actor_id": "Myriel", "score": 100}
    #   ]
    # }
    @@request_body = req.body
    puts 'This is the request prior to encryption: ' + req.body
    puts
    # Encryption
    # AES symmetric algorithm encrypts raw data
    aes_encrypted_request_data = aes_encrypt(req.body)
    req.body = aes_encrypted_request_data[0]
    # RSA asymmetric algorithm encrypts keys of AES
    encrypted_key = rsa_public_key1(aes_encrypted_request_data[1])
    encrypted_vi = rsa_public_key1(aes_encrypted_request_data[2])
    # fixed length 350
    req.body.prepend('", "data":"')
    req.body.prepend(encrypted_vi)
    req.body.prepend(encrypted_key)
    # request body should be in JSON format.
    req.body.prepend('{"keys":"')
    req.body << '"}'
    req.body.gsub!(/\n/, '\\n')
    response = Net::HTTP.new('peerlogic.csc.ncsu.edu').start {|http| http.request(req) }
    # RSA asymmetric algorithm decrypts keys of AES
    # Decryption
    response.body = JSON.parse(response.body)
    key = rsa_private_key2(response.body["keys"][0, 350])
    vi = rsa_private_key2(response.body["keys"][350, 350])
    # AES symmetric algorithm decrypts data
    aes_encrypted_response_data = response.body["data"]
    response.body = aes_decrypt(aes_encrypted_response_data, key, vi)

    puts "Response #{response.code} #{response.message}:
          #{response.body}"
    puts
    @@response = response
    @@response_body = response.body

    redirect_to action: 'client'
  end

  def send_post_request
    curr_assignment_id = (params[:assignment_id].empty? ? '724' : params[:assignment_id])
    @@request_body = json_generator(curr_assignment_id, params[:another_assignment_id].to_i, params[:round_num].to_i).to_json
    redirect_to action: 'client'
  end

  def rsa_public_key1(data)
    public_key_file = 'public1.pem'
    public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
    encrypted_string = Base64.encode64(public_key.public_encrypt(data))

    encrypted_string
  end

  def rsa_private_key2(cipertext)
    private_key_file = 'private2.pem'
    password = "ZXhwZXJ0aXph\n"
    encrypted_string = cipertext
    private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file), Base64.decode64(password))
    string = private_key.private_decrypt(Base64.decode64(encrypted_string))

    string
  end

  def aes_encrypt(data)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    cipertext = Base64.encode64(cipher.update(data) + cipher.final)
    [cipertext, key, iv]
  end

  def aes_decrypt(cipertext, key, iv)
    decipher = OpenSSL::Cipher::AES.new(256, :CBC)
    decipher.decrypt
    decipher.key = key
    decipher.iv = iv
    plain = decipher.update(Base64.decode64(cipertext)) + decipher.final
    plain
  end
end
