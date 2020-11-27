_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  class CardSetModel

    POSSIBLE_SUITS: 'rgby'.split('')
    POSSIBLE_NUMBERS: '0123456789srd'.split('')
    WILD: ['xw', 'x4']

    constructor: (@set = '') ->
      @

    getSet: -> @set
    isActive: -> @set != ''

    addCard: (card) ->
      @set += card if @validateCard(card)

    removeCard: (card) ->
      @set = _.without(_s.chop(@set, 2), card).join '' if @validateCard(card)
      card

    popCard: ->
      card = @set.substr(-2)
      @set = @set.substr(0, @set.length - 2)
      card

    hasCard: (card) ->
      if @validateCard(card)
        _.contains(_s.chop(@set, 2), card)
      else
        false

    topCard: ->
      array = _s.chop(@set, 2) || []
      array[array.length - 1] || ''

    getShuffledDeck: ->
      deck = []
      for suit in @POSSIBLE_SUITS
        for number in @POSSIBLE_NUMBERS
          deck.push "#{suit}#{number}"
          if number != "0"
            deck.push "#{suit}#{number}" # two each of these
      for card in @WILD
        for n in [1..4]
          deck.push card # four each of these
      @set = _.shuffle(deck).join ''

    validateCard: (card) ->
      _.contains(@WILD, card) || 
      (_.contains(@POSSIBLE_SUITS, card.charAt(0)) &&
      _.contains(@POSSIBLE_NUMBERS, card.charAt(1)))

    possibleNextMove: (card, color) ->
      @validateCard(card) &&
      (@set == '' ||
      card.charAt(0) == @topCard().charAt(0) ||
      card.charAt(1) == @topCard().charAt(1) ||
      _.contains(@WILD, card)) || # TODO restriction on playing +4 
      (_.contains(@WILD, @topCard()) && color && card.charAt(0) == color.charAt(0))