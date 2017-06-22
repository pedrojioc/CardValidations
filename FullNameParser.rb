class FullNameParse
  def initialize()
    @dict = {
    'prefix' => {
      'Mr.' => {0 =>'mr', 1=>'mister', 2=>'master'},
      'Mrs.' => {0=>'mrs', 1=>'missus', 2=>'missis'},
      'Ms.' => {0=>'ms', 1=>'miss'},
      'Dr.' => {0=>'dr'},
      'Rev.' => {0=>"rev", 1=>"rev'd", 2=>"reverend"},
      'Fr.' => {0=>'fr', 1=>'father'},
      'Sr.' => {0=>'sr', 1=>'sister'},
      'Prof.' => {0=>'prof', 1=>'professor'},
      'Sir' => {0=>'sir'},
      ' ' => {0=>'the'}
    },
    'compound' => {0=>'da',1=>'de',2=>'del',4=>'della',5=>'der',6=>'di',7=>'du',8=>'la',9=>'pietro',10=>'st.',11=>'st',12=>'ter',13=>'van',14=>'vanden',15=>'vere',16=>'von'},
    'suffixes' => {
      'line' => {0=>'I',1=>'II',2=>'III',4=>'IV',5=>'V',6=>'1st',7=>'2nd',8=>'3rd',9=>'4th',10=>'5th',11=>'Senior',12=>'Junior',13=>'Jr',14=>'Sr'},
      'prof' => {0=>'PhD',1=>'APR',2=>'RPh',3=>'PE',4=>'MD',5=>'MA',6=>'DMD',7=>'CME'}
    },
    'vowels' => {0=>'a',1=>'e',2=>'i',3=>'o',4=>'u'}
    }
  end

  def parse_name full_name
    full_name.strip!
    #Setup vars
    salutation = ''; fname = ''; initials = ''; lname = ''; suffix = ''

    professional_suffix = get_pro_suffix(full_name)
    if professional_suffix
      # Remove the suffix from full name
      full_name = full_name.gsub(/#{professional_suffix}/, '')
      
      # Remove the preceeding comma and space(s) from suffix
      professional_suffix = professional_suffix.gsub(/, */, '')

      # Normalize the case of suffix if found in dictionary
      @dict['suffixes']['prof'].each do |key, value|
        professional_suffix = value if value.downcase === professional_suffix.downcase
      end
    end

    # Deal with nickname, push to array
    has_nick = get_nickname(full_name)
    if has_nick
      # Remove wrapper chars from around nickname
      name = Hash.new
      name['nickname'] = has_nick[1, has_nick.length-2]
      # Remove the nickname from the full name
      full_name.gsub!(has_nick, '')
      # Get rid of consecutive spaces left by the removal
      full_name.gsub!('  ', ' ')
    end
    #Grab a list of words from name
    unfiltered_name_parts = break_words(full_name)
    while s = is_salutation(unfiltered_name_parts[0]) do
      salutation += "#{s} "
      unfiltered_name_parts.shift
    end
    salutation.strip!
    
    # Is last word a suffix or multiple suffixes consecutively?
    while s = is_suffix(unfiltered_name_parts[(unfiltered_name_parts.length)-1], full_name)
      suffix += "#{s} "
      unfiltered_name_parts.pop
    end
    suffix.strip!
    
    # If suffix and professional suffix not empty, add comma
    if not professional_suffix.empty? and not suffix.empty?
       suffix = ', '
    end
    
    # Concat professional suffix to suffix
    suffix += professional_suffix.to_s

    # set the ending range after prefix/suffix trim
    len_parts = unfiltered_name_parts.length

    # concat the first name
    for i in 0...(len_parts-1)
      word = unfiltered_name_parts[i]
      # move on to parsing the last name if we find an indicator of a compound last name (Von, Van, etc)
      # we use $i != 0 to allow for rare cases where an indicator is actually the first name (like "Von Fabella")
      break if is_compound(word) and i != 0
      # is it a middle initial or part of their first name?
      # if we start off with an initial, we'll call it the first name
      if is_initial(word)
        # is the initial the first word?
        if i == 0
          # if so, do a look-ahead to see if they go by their middle name
          # for ex: "R. Jason Smith" => "Jason Smith" & "R." is stored as an initial
          # but "R. J. Smith" => "R. Smith" and "J." is stored as an initial
          if is_initial(unfiltered_name_parts[i+1])
            fname += " #{word.upcase}"
          else
            initials += " #{word.upcase}"
          end
          # otherwise, just go ahead and save the initial
        else
          initials += " #{word.upcase}"
        end
      else
        fname += " #{fix_case(word)}"
      end
    end

    # check that we have more than 1 word in our string
    if (len_parts-1) > 1
      # concat the last name
      for i in 0...(len_parts)
        lname = " #{fix_case(unfiltered_name_parts[i])}"
      end
    else
      # otherwise, single word strings are assumed to be first names
      fname = fix_case(unfiltered_name_parts[i])
    end
    # return the various parts in an array
    name = {
      'salutation' => salutation,
      'fname' => fname.strip,
      'initials' => initials.strip,
      'lname' => lname.strip,
      'suffix' => suffix
    }
    return name
  end#End method
 
  #Protected methods
  protected

  #Breaks name into individual words
  def break_words name
      name.split(' ')
  end

  #Checks for the existence of, and returns professional suffix
  def get_pro_suffix name
    @dict['suffixes']['prof'].each do |key, value|
      matches = name.scan(/,[\s]*#{value}\b/i)
      if matches.length > 0
        return matches[0]
      end
    end
    #Retuen empty string
    return ''
  end
  
  #Function to check name for existence of nickname based on these stipulations
  def get_nickname name
    matches = name.scan(/[\(|\"].*?[\)|\"]/)
    return matches[0] if matches.length > 0
    return false
  end

  #Checks word against array of common suffixes
  def is_suffix word, name
    # Ignore periods, normalize case
    #puts word
    word = word.downcase.gsub('.', '')

    # Search the array for our word
    line_match = array_search(word, @dict['suffixes']['line'])
    prof_match = array_search(word, @dict['suffixes']['prof'])

    # Break out for professional suffix matches first
    if prof_match != false
      return @dict['suffixes']['prof'][prof_match]
    end

    # Now test our edge cases based on lineage
    if line_match != false

      # Store our match
      matched_case = @dict['suffixes']['line'][line_match]

      # Remove it from the array
      temp_array = @dict['suffixes']['line']
      temp_array.delete(line_match)
      
      # Make sure we're dealing with the suffix and not a surname
      if word == 'senior' or word == 'junior'
        # If name is Joshua Senior, it's pretty likely that Senior is the surname
        # However, if the name is Joshua Jones Senior, then it's likely a suffix
        if name.scan(/[[:alpha:]]+/).count < 3
          return false
        end

        # If the word Junior or Senior is contained, but so is some other
        # lineage suffix, then the word is likely a surname and not a suffix
        temp_array.each do |suffix|
          if name.scan(/\b#{suffix}\b/i).length > 0
            return false
          end
        end
      end
      return matched_case
    end
    return false
  end

  #Checks word against list of common honorific prefixes
  def is_salutation word
    word = word.downcase.gsub('.', '')
    @dict['prefix'].each do |key, value|
      if value.has_value?(word)
        return key
      end
    end
    return false
  end

  #Checks our dictionary of compound indicators to see if last name is compound
  def is_compound word
    array_search(word.downcase, @dict['compound'])
  end

  #Test string to see if it's a single letter/initial (period optional)
  def is_initial word
    (word.length == 1 or (word.length == 2 and word[1] == "."))
  end

  #Checks for camelCase words such as McDonald and MacElroy
  def is_camel_case word
    return true if word.scan(/[A-Za-z]([A-Z]*[a-z][a-z]*[A-Z]|[a-z]*[A-Z][A-Z]*[a-z])[A-Za-z]*/).length > 0
    return false
  end

  def fix_case word
    # Fix case for words split by periods (J.P.)
    word = safe_ucfirst('.', word) if word.index('.') != nil
    
    # Fix case for words split by hyphens (Kimura-Fay)
    word = safe_ucfirst('-', word) if word.index('-') != nil

    # Special case for single letters
    word = word.upcase if word.length == 1

    # Special case for 2-letter words
    if word.length == 2
      # Both letters vowels (uppercase both)
      if @dict['vowels'].has_value?(word[0].downcase) and @dict['vowels'].has_value?(word[1].downcase)
        word = word.upcase
      end
      # Both letters consonants (uppercase both)
      if !@dict['vowels'].has_value?(word[0].downcase) and !@dict['vowels'].has_value?(word[1].downcase)
        word = word.upcase
      end
      # First letter is vowel, second letter consonant (uppercase first)
      if @dict['vowels'].has_value?(word[0].downcase) and !@dict['vowels'].has_value?(word[1].downcase)
        word = word.capitalize
      end
      # First letter consonant, second letter vowel or "y" (uppercase first)
      if !@dict['vowels'].has_value?(word[0].downcase) and (@dict['vowels'].has_value?(word[1].downcase) or word[1].downcase == 'y')
        word = word.capitalize
      end
    end
    
    # Fix case for words which aren't initials, but are all upercase or lowercase
    if (word.length >= 3) and (letters_is_upcase?(word) or letters_is_downcase?(word))
      word = word.sub(/^(\w)/) {|s| s.capitalize}
    end

    return word
  end

  #helper public function for fix_case
  def safe_ucfirst separator, word
    # uppercase words split by the separator (ex. dashes or periods)
    parts = word.split(separator)
    i = 0
    words = Array.new
    parts.each do |word|
      words[i] = (is_camel_case(word) ? word : word.capitalize)
      i += 1
    end
    return words.join(separator)
  end

  #Busca un valor en el array y retorna la llave de este si encuantra el valor a buscar
  def array_search word, vector
    vector.each do |key, value|
      return key if value.downcase == word
    end
    return false
  end

  #Return true if letter of word is all upcase
  def letters_is_upcase?(letters)
    return true if letters = letters.upcase
    return false
  end

  #Return true if letter of word is all downcase
  def letters_is_downcase?(letters)
    return true if letters = letters.downcase
    return false
  end
end#End class

parser = FullNameParse.new

puts parser.parse_name "pedro jose Jimenez Ochoa"