_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  class CardSetModel

    POSSIBLE_SUITS: 'rgby'.split('')
    POSSIBLE_NUMBERS: '0123456789srd'.split('')
    WILD: ['xw', 'x4']

    constructor: (@set = '', @onEmpty = (csm) -> ) ->
      @

    clear: -> @set = ''
    getSet: -> @set
    isActive: -> @set != ''

    addCard: (card) ->
      @set += card if @validateCard(card)

    removeCard: (card) ->
      if @validateCard(card)
        array = _s.chop(@set, 2) || []
        index = array.lastIndexOf(card)
        console.log("removeCard", card, @set, array, index)
        if index > -1
          array.splice(index, 1)
          @set = array.join ''
      card

    popCard: ->
      if @set == ''
        @onEmpty(@)
      if @set == ''
        return
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

    possibleNextMove: (card, color, playerCards) ->
      pileCard = @topCard()
      @validateCard(card) &&
      (@set == '' ||
      card.charAt(0) == pileCard.charAt(0) ||
      card.charAt(1) == pileCard.charAt(1) ||
      card == 'xw' ||
      (card == 'x4' && !_.some(_s.chop(playerCards.getSet(), 2), (c) -> c.charAt(0) == pileCard.charAt(0))) ||
      (_.contains(@WILD, pileCard) && color && card.charAt(0) == color.charAt(0)))
