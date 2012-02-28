# encoding: utf-8
# Patch to prevent slugs being generated that end with a hyphen
module Babosa

  class Identifier
    # Normalize the string for use as a URL slug. Note that in this context,
    # +normalize+ means, strip, remove non-letters/numbers, downcasing,
    # truncating to 255 bytes and converting whitespace to dashes.
    # @param Options
    # @return String
    def normalize!(options = nil)
      # Handle deprecated usage
      if options == true
        warn "#normalize! now takes a hash of options rather than a boolean"
        options = default_normalize_options.merge(:to_ascii => true)
      else
        options = default_normalize_options.merge(options || {})
      end
      if options[:transliterate]
        transliterate!(*options[:transliterations])
      end
      to_ascii! if options[:to_ascii]
      clean!
      word_chars!
      clean!
      downcase!
      truncate_bytes!(options[:max_length])
      clean!
      with_separators!(options[:separator])
    end
  end
end