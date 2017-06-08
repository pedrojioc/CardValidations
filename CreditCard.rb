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

  def self.validCreditCard(number, type = nil)
    response = {
      'valid' => false,
      'number' => '',
      'type' => '',
    }
    number = number.gsub(/[^0-9]/, '')

    unless type != nil
      type = self.creditCardType(number)
    end
    puts type
  end

  #Protected methods
  protected
  #Return the credit card type
  def self.creditCardType(number)
    @cards.each do |key, value|
      matches = number.scan(value['pattern'])
      if matches != nil and matches.length > 0
        return value['type']
      end
    end
    return nil
  end

end

puts CreditCard.validCreditCard('4927704633109664')
#puts CreditCard.creditCardType('55927109664')