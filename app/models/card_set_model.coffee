_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  class CardSetModel

    POSSIBLE_SUITS: ['s', 'c', 'd', 'h']
    POSSIBLE_NUMBERS: ['a', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'j', 'q', 'k']

    constructor: (@set = '') ->
      @

    getHand: -> @hand

    addCard: (card) ->
      @set += card if validateCard(card)

    playCard: (card) ->
      _.without(_s.chop(@set, 2), card).join '' if validateCard(card)

    removeCard: @playCard

    hasCard: (card) ->
      _.contains(_s.chop(@set, 2), card) if validateCard(card)

    topCard: ->
      array = _s.chop set, 2
      array[array.length - 1] || null

    getShuffledDeck: ->
      deck = []
      _.each CardHelper.POSSIBLE_SUITS, (suit) ->
        _.each CardHelper.POSSIBLE_NUMBERS, (number) ->
          deck.push "#{suit}#{number}"
      @set = _.shuffle(deck).join ''

    validateCard: (card) ->
      _.contains(POSSIBLE_SUITS, card.charAt(0)) &&
      _.contains(POSSIBLE_NUMBERS, card.charAt(1))

    possibleNextMove: (card) ->
      validateCard(card) &&
      (card.charAt(0) == @topCard().charAt(0) ||
      card.charAt(1) == @topCard().charAt(1))
