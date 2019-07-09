module Cadmium
  # Uses sentiment analysis to score a sentence's "feeling". `Cadmium::Sentiment`
  # also takes advantage of emojis to further increase accuracy.
  module Sentiment
    extend self

    # Negate the next word in the phrase.
    NEGATORS = {
      "cant"    => 1,
      "can't"   => 1,
      "dont"    => 1,
      "don't"   => 1,
      "doesnt"  => 1,
      "doesn't" => 1,
      "not"     => 1,
      "non"     => 1,
      "wont"    => 1,
      "won't"   => 1,
      "isnt"    => 1,
      "isn't"   => 1,
      "wasnt"   => 1,
      "wasn't"  => 1,
    }

    @@tokenizer = Cadmium::Tokenizer::TreebankWordTokenizer.new
    @@data = File.read(File.join(__DIR__, "../../data/sentiment.txt"))

    # Analyze a phrase and return a `result` hash comprised of a score,
    # comparative analysis (a score based soley on number of negative
    # and positive words), tokens, words, positive (positive words),
    # and negative (negative words).
    #
    # ```
    # pp Cadmium::Sentiment.analyze("You are a piece of 💩")
    # # => {score: -1,
    # #     comparative: -1,
    # #     tokens: ["You", "are", "a", "piece", "of", "💩"],
    # #     words: ["💩"],
    # #     positive: [],
    # #     negative: ["💩"]}
    # ```
    def analyze(phrase, inject = nil)
      # Turn our text file into an array
      data = @@data.split("\n").map do |d|
        arr = d.split(/\s+/).reject(&.empty?)
        str = [] of String
        int = 1
        arr.each do |item|
          if item.to_i { nil }
            int = item
          else
            str.push item
          end
        end
        [str.join(" "), int]
      end.reject(&.empty?)

      # Inject data into our array
      if inject.is_a?(Array)
        data += inject
      end

      # Turn our data array into a hash
      data = data.to_h

      # Inject data into our hash
      if inject.is_a?(Hash) || inject.is_a?(NamedTuple)
        data = inject.to_h.merge(data)
      end

      tokens = @@tokenizer.tokenize(phrase)
      score = 0
      words = [] of String
      positive = [] of String
      negative = [] of String

      (0..tokens.size - 1).each do |i|
        obj = tokens[i]
        item = data[obj]? ? data[obj].to_i : nil
        next unless item

        if i > 0
          prev_token = tokens[i - 1]
          item = -item if NEGATORS.includes?(prev_token)
        end

        words.push(obj)
        positive.push(obj) if item > 0
        negative.push(obj) if item < 0

        score += item
      end

      result = {
        score:       score,
        comparative: tokens.size > 0 ? score / tokens.size : 0,
        tokens:      tokens,
        words:       words,
        positive:    positive,
        negative:    negative,
      }

      result
    end

    module StringExtension
      # Get the sentiment of a string. Same as running
      # `Cadmium::Sentiment.analyze(STRING)`.
      def sentiment(inject = nil)
        Cadmium::Sentiment.analyze(self, inject)
      end

      # Determines if a string is more positive than negative.
      # Returns `Bool`.
      def is_positive?
        sentiment = self.sentiment
        sentiment[:positive] > sentiment[:negative]
      end

      # Determines if a string is more negative than positive.
      # Returns `Bool`.
      def is_negative?
        sentiment = self.sentiment
        sentiment[:negative] > sentiment[:positive]
      end
    end
  end
end
