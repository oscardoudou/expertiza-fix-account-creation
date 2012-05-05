# Create a parser object
#frequently used general constants
NOUN = 1
VERB = 2
ADJ = 3
ADV = 4

POSITIVE = 0
SUGGESTIVE = 1
NEGATED = 2

#used by patternIdentify and predictClass and relevance, while comparing edges!
EQUAL = 1.0
DISTINCT = 2.0

#constants used by graph generator
WORDS = 10000 #to control the number of tokens/vertices a graph contains
#thresholds for pruning edges during pattern selection
ALPHA_FREQ = 2 #alpha - the frequency threshold (lower)
BETA_FREQ = 10

=begin 
   THE FIRST TWO SETS ARE COMMON WORDS DURING OVERLAP ACROSS DEFINITIONS OR EXAMPLES.
   THE THIRD SET IS TO PREVENT FREQUENT WORDS FROM BEING COMPARED WITH OTHER TOKENS.
=end   
CLOSED_CLASS_WORDS = [".", ",", "THE", 
        "AND", "A", "\"", "IN", "I", ":", "YOU", "IS", "TO", "OF", 
        ")", "(", "IT", "FOR",  "!",  "?","THAT","ON", "WITH", "HAVE", 
         "BE", "...",  "AS","THIS","WAS", "e.g.", "especially","BUT", "OR", "FROM","WHAT","NOT", "ARE",  
        "MY", "AT",   "HE", "BY", "ONE","IF", "THEY", "YOUR","ALL",
        "ME", "SO",  "AN",  "WE", "CAN", "WILL", "DO","ABOUT","JUST",
         "OUT", "HIS",  "WHO", "WOULD","THERE","LIKE", "HAS","MORE","UP","NO",    
        "THEM", "ANY", "THEIR", "IT'S", "ONLY", "WHEN","SOME","HAD", "DON'T",  
        ";",  "I'M", "BEEN", "WHICH", "OTHER", "WERE", "HOW", "THEN", "NOW",
        "HER",  "SHE",  "ALSO", "US", "VERY", "BECAUSE","THAN","WELL",
        "AM",   "HIM", "INTO", "OUR", "COULD", "EVEN","MUCH","HERE",
        "TOO","THESE", "THOSE","MAY", "WHERE", "MOST","SHOULD", "OVER", "WANT", "DID",   
        "WHY", "OFF", "IT", "ITS", "I'VE","MANY","GOING", "THOSE", "DOES","PLEASE",  
        "THAT'S",  "YOU'RE",  "DOWN","ANOTHER", "AROUND","CAN'T","DIDN'T", 
         "MUST","YES", "EACH", "MAYBE","EVERY", "FEW", "DOESN'T",  
        "I'LL", "OH", "ELSE", "HE'S", "THERE'S", "HI", "AWAY", "DOING","ISN'T",  
        "OK", "THEY'RE", "YEAH", "MINE", "WE'RE", "WHAT'S", "SHALL","WON'T", 
        "SHE'S", "HELLO", "OKAY", "HERE'S", "-", "LESS", "USED", "use", "associated", "having", "certain",
        "etc", "etc.", "act", "purpose"]
  
# @invisible
STOP_WORDS = ["a", "am", "an", "and", "any", "as", "at", "is", "it", "its","de", "by","i", 
      "ie", "if", "in","no","of", "off", "or", "eg", "the", "too", "are", "the", "he",
      "about", "above", "across", "after", "afterwards", "again", "against",
      "all", "almost", "alone", "along", "already", "also", "although", "always", 
      "among", "amongst", "amoungst", "amount",  "another", 
      "anyhow", "anyone", "anything", "anyway", "anywhere", "are", "around",
     "back", "be", "became", "because", "become", "becomes",
      "becoming", "been", "before", "beforehand", "behind", "being", "below",
       "beside", "besides", "between", "beyond", "bill", "both", "bottom",  "call", 
       "can", "cannot", "cant", "co", "computer", "con", "could",
      "couldnt", "cry",  "describe", "detail", "do", "done", "does", "down",
      "due", "during", "each",  "eight", "either", "eleven", "else", "elsewhere",
      "empty", "enough", "etc", "even", "ever", "every", "everyone", "everything",
      "everywhere", "except", "few", "fifteen", "fify", "fill", "find",
      "fire", "first", "five", "for", "former", "formerly", "forty", "found",
      "four", "from", "front", "full", "further", "get", "give", "go",
      "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter",
      "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his",
      "how", "however", "hundred",  "inc", "indeed", 
      "interest", "into",  "itself", "keep", "last", "latter",
      "latterly", "least", "less", "ltd", "made", "many", "may", "me", 
      "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly",
      "move", "much", "must", "my", "myself", "name", "namely", "neither", 
      "never", "nevertheless", "next", "nine",  "nobody", "none", "noone",
      "nor", "not", "nothing", "now", "nowhere",  "often", "on", 
      "once", "one", "only", "onto",  "other", "others", "otherwise", "our",
      "ours", "ourselves", "out", "over", "own", "part", "per", "perhaps", 
      "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming",
      "seems", "serious", "several", "she", "should", "show", "side", "since", 
      "sincere", "six", "sixty", "so", "some", "somehow", "someone", "something",
      "sometime", "sometimes", "somewhere", "still", "such", "system", "take", 
      "ten", "than", "that", "the", "their", "them", "themselves", "then", 
      "thence", "there", "thereafter", "thereby", "therefore", "therein", 
      "thereupon", "these", "they", "thick", "thin", "third", "this", "those",
      "though", "three", "through", "throughout", "thru", "thus", "to", 
      "together",  "top", "toward", "towards", "twelve", "twenty", "two",
      "un", "under", "until", "up", "upon", "us", "very", "via", "was", "we", 
      "well", "were", "what", "whatever", "when", "whence", "whenever", "where", 
      "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", 
      "whether", "which", "while", "whither", "who", "whoever", "whole", "whom", 
      "whose", "why", "will", "with", "within", "without", "would", "yet", 
      "you", "your", "yours", "yourself", "yourselves", "individual","individually"]
    
#tokens containing these words aren't compared with other tokens, because they don't add any meaning
FREQUENT_WORDS = [ "a", "am", "an", "and", "any", "as", 
      "at", "are","be", "by", "can", "did", "do", "does", "is", "it", "its", "i", "ie", "if", "in","no",
      "or", "eg", "me", "my","of", "off", "oh", "our", "ours", "was", "have", "has", 
       "so","she", "the", "too", "to","they", "their", "theirs", "that", "this", "then", 
       "there","than", "up",  "us", "u", "his", "her", "hers",
       "we", "with","were", "you", "your", "yours"]

#puts FREQUENT_WORDS