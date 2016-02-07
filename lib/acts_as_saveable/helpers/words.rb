module ActsAsSaveable::Helpers

  # this helper provides methods that help find what words are
  # up saves and what words are down saves
  #
  # It can be called
  #
  # saveable_object.saveable_words.that_mean_true
  #
  module Words

    def saveable_words
      SaveableWords
    end

  end

  class SaveableWords

    def self.that_mean_true
      ['up', 'upsaved', 'like', 'liked', 'positive', 'yes', 'good', 'true', 1, true]
    end

    def self.that_mean_false
      ['down', 'downsaved', 'dislike', 'disliked', 'negative', 'no', 'bad', 'false', 0, false]
    end

    # check is word is a true or bad saved
    # if the word is unknown, then it counts it as a true/good
    # saved.  this exists to allow all saving to be good by default
    def self.meaning_of word
      !that_mean_false.include?(word)
    end

  end
end
