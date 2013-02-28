class SentencePair
attr_accessor :sent1_ID, :sent2_ID, :similarity
def initialize(sent_1, sent_2, sim)
    @sent1_ID = sent_1
    @sent2_ID = sent_2
    @similarity = sim
end
end
