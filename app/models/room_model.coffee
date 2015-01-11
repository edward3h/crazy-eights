_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  { CardSetModel } = app.locals

  class RoomModel
    players: []
    playerCount: 0
    currentPlayer: -1
    gameStarted: false

    deck: new CardSetModel()
    pile: new CardSetModel()

    constructor: (@id, callback) ->
      @exists (roomExists) =>
        if roomExists
          app.client.hgetall "room:#{@id}", (err, room) =>
            { @playerCount, @gameStarted, @currentPlayer, deck, pile } = room
            @deck = new CardSetModel(deck)
            @pile = new CardSetModel(pile)
            _.times @playerCount, =>
              @players.push new CardSetModel(room["player-#{index}"])

            callback.call(@, @roomState())
        else
          @createRoom => callback.call(@, @roomState())
      @

    # Add player
    addPlayer: (data, callback) ->
      @exists (roomExists) =>
        if roomExists
          unless @gameStarted

            app.client.hincrby "room:#{@id}", playerCount, 1, (err, data) =>
              app.client.hset "room:#{@id}", "player-#{@playerCount + 1}", '', (err, data) =>
                @playerCount++
                @players.push new CardSetModel()
                callback.call(@, error: false, room: @roomState())

          # The game has already started
          else callback.call(@, error: true, code: 2)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 1)

    # Remove player
    removePlayer: (data, callback) ->
      { playerIndex } = data
      @exists (roomExists) =>
        if roomExists
          unless @gameStarted
            app.client.hincrby "room:#{@id}", "playerCount", -1, (err, data) =>
              app.client.hdel "room:#{@id}", "player-#{playerIndex}", (err, data) =>
                @players.splice(playerIndex, 1)
                @playerCount--
                callback.call(@, error: false, room: @roomState())

          # The game has already started
          else callback.call(@, error: true, code: 2)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 1)

    # Start game
    startGame: (data, callback) ->
      @exists (roomExists) =>
        if roomExists
          unless @gameStarted
            @gameStarted = true
            @deck.getShuffledDeck()
            _.each @players, (player) ->
              _.times 8, ->
                topCard = @deck.topCard()
                player.addToSet(topCard)
                @deck.removeCard(topCard)
            @nextPlayer()

            app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
              callback.call(@, error: false, room: @roomState())

          # The game has already started
          else callback.call(@, error: true, code: 2)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 1)

    # Play card
    playCard: (data, callback) ->
      { playerIndex, card } = data
      @exists (roomExists) =>
        if roomExists
          if @gameStarted && @players[playerIndex].hasCard(card)
            if @pile.possibleNextMove(card)
              @players[playerIndex].removeCard(card)
              @pile.addCard(card)
              @nextPlayer()

              app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                callback.call(@, error: false, room: @roomState())

            # Invalid move!
            else callback.call(@, error: true, code: 3)

          # Game inconsistency error
          else callback.call(@, error: true, code: 2)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 1)

    # Helpers

    roomHash: ->
      returnVal = {
        @playerCount, @currentPlayer, @gameStarted
        deck: @deck.getHand(), pile: @pile.getHand()
      }
      _.times @playerCount, (index) =>
        returnVal["player-#{index}"] = players[index].getHand()

      returnVal

    roomState: ->
      returnVal = {
        @playerCount, @currentPlayer, @gameStarted
        deck: @deck.getHand(), pile: @pile.getHand()
      }
      returnVal.players = []
      _.times @playerCount, (index) =>
        returnVal.players.push players[index].getHand()

      returnVal

    exists: (callback) ->
      if @id
        app.client.exists "room:#{@id}", (err, exists) =>
          callback.call(@, exists == 1)
      else callback.call(@, false)

    createRoom: (data, callback) ->
      @id = Math.floor(Math.random() * 90000) + 10000
      @exists (roomExists) =>
        unless roomExists
          app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
            callback.call(@)

        # We got a room that already exists
        else @createRoom(data, callback)

    nextPlayer: ->
      @currentPlayer = (@currentPlayer + 1) % @playerCount

