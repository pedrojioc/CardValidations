class CreditCard
  
  @cards = {
    'visaelectron' => {
      'type' => 'visaelectron',
      'pattern' => /^4(026|17500|405|508|844|91[37])/,
      'length' => { 0 => 16 },
      'cvcLength' => { 0 => 3 },
      'luhn' => true,
    },
    'maestro' => {
      'type' => 'maestro',
      'pattern' => /^(5(018|0[23]|[68])|6(39|7))/,
      'length' => { 0 => 12 }, 
      'cvcLength' => { 0 => 3 },
      'luhn' => true,
    },
    'forbrugsforeningen' => {
      'type' => 'forbrugsforeningen',
      'pattern' => /^600/,
      'length' => {0=>16},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
    'dankort' => {
      'type' => 'dankort',
      'pattern' => /^5019/,
      'length' => {0=>16},
      'cvcLength' => {0=>16},
      'luhn' => true,
    },
    #Credit cards
    'visa' => {
      'type' => 'visa',
      'pattern' => /^4/,
      'length' => {0=>13, 1=>16},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
    'mastercard' => {
      'type' => 'mastercard',
      'pattern' => /^(5[0-5]|2[2-7])/,
      'length' => {0=>16},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
    'amex' => {
      'type' => 'amex',
      'pattern' => /^3[47]/,
      'format' => '/(\d{1,4})(\d{1,6})?(\d{1,5})?/',
      'length' => {0=>15},
      'cvcLength' => {0=>3, 1=>4},
      'luhn' => true,
    },
    'dinersclub' => {
      'type' => 'dinersclub',
      'pattern' => /^3[0689]/,
      'length' => {0=>14},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
    'discover' => {
      'type' => 'discover',
      'pattern' => /^6([045]|22)/,
      'length' => {0=>16},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
    'unionpay' => {
      'type' => 'unionpay',
      'pattern' => /^(62|88)/,
      'length' => {0=>16, 1=>17, 2=>18, 3=>19},
      'cvcLength' => {0=>3},
      'luhn' => false,
    },
    'jcb' => {
      'type' => 'jcb',
      'pattern' => /^35/,
      'length' => {0=>16},
      'cvcLength' => {0=>3},
      'luhn' => true,
    },
  }

  #Return hash with cards
  def self.cards
    @cards
  end

  #Verify if the card is valid
  def self.validCreditCard number, type = nil
    response = {
      :valid => false,
      :number => nil,
      :type => nil,
    }
    number = number.gsub(/[^0-9]/, '')

    unless type != nil
      type = self.creditCardType(number)
    end
    if @cards.key?(type) and self.validCard(number, type)
      response[:valid] = true
      response[:number] = number
      response[:type] = type
    end
    return response
  end

  #Check if the cvc number is valid according to the type of card
  def self.validCvc cvc, type
    self.is_numeric?(cvc) and @cards.key?(type) and self.validCvcLength(cvc, type)
  end

  def self.validDate year, month
    month = month.rjust(2, '0')
    return false if year.scan(/^20\d\d$/).length == 0
    return false if month.scan(/^(0[1-9]|1[0-2])$/).length == 0
    return false if year.to_i <= Time.now.year and month.to_i < Time.now.month

    return true

  end

  #Protected methods
  protected

  #Return the credit card type
  def self.creditCardType number
    @cards.each do |key, value|
      matches = number.scan(value['pattern'])
      if matches != nil and matches.length > 0
        return value['type']
      end
    end
    return nil
  end
  #End return the credit card type

  def self.validCard number, type
    self.validPattern(number, type) and self.validLength(number, type) and self.validLuhn(number, type)
  end

  def self.validPattern number, type
    number.scan(@cards[type]['pattern'])
  end

  #Valida la longitud del numero de la tarjeta, segun franquicia
  def self.validLength number, type
    @cards[type]['length'].each do |key, value|
      return true if number.length == value
    end
    return false
  end

  #Valida la longitud del cvc, segun franquicia
  def self.validCvcLength cvc, type
    @cards[type]['cvcLength'].each do |key, value|
      return true if cvc.length == value
    end
    return false
  end

  def self.validLuhn number, type
    if not @cards[type]['luhn']
      return true
    else
      return self.luhnCheck(number)
    end
  end

  #Check if the number is valid, using the luhn algorithm
  def self.luhnCheck(number)
    number
      .chars       # Break into individual digits
      .map(&:to_i) # map each character by calling #to_i on it
      .reverse     # Start from the end
      .map.with_index { |x, i| i.odd? ? x * 2 : x } # Double every other digit
      .map { |x| x > 9 ? x - 9 : x }  # If > 9, subtract 9 (same as adding the digits)
      .inject(0, :+) % 10 == 0        # Check if multiple of 10
  end
  #Retorna true si un string contiene solo caracteres numericos
  def self.is_numeric?(str)
    str.scan(/\D/).empty?
  end

end

#puts CreditCard.validDate('2017', '06')
#puts CreditCard.creditCardType('55927109664')