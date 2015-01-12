_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  { CardSetModel } = app.locals

  class RoomModel
    players: []
    playerNames = []
    playerGameStarted = []
    playerGameWon = []
    playerCount: 0
    currentPlayer: -1

    gameState: 'notstarted'
    # States:
    # notstarted - Game has not started
    # started - Game is in progress
    # ended - The game ended
    # disconnected - An active player disconnected, and the game is now destroyed

    deck: new CardSetModel()
    pile: new CardSetModel()

    constructor: (@id, callback) ->
      @exists (roomExists) =>
        if roomExists
          app.client.hgetall "room:#{@id}", (err, room) =>
            { @playerCount, @currentPlayer, @gameState, deck, pile } = room
            @deck = new CardSetModel(deck)
            @pile = new CardSetModel(pile)
            _.times @playerCount, =>
              @players.push new CardSetModel(room["player-#{index}"])
              @playerNames.push(room["player-#{index}-name"])
              @playerGameStarted.push(room["player-#{index}-start"] == 'true')
              @playerGameWon.push(parseInt(room["player-#{index}-won"], 10))

            callback.call(@, @roomState())
        else
          @createRoom => callback.call(@, @roomState())
      @

    # Add player
    addPlayer: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          unless _.all(@playerGameStarted)
            @players.push new CardSetModel()
            @playerNames.push username
            @playerGameStarted.push false
            @playerGameWon.push 0
            @playerCount++

            app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
              callback.call(@, error: false, room: @roomState())

          # The game has already started
          else callback.call(@, error: true, code: 11)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 10)

    # Remove player
    removePlayer: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          unless _.all(@playerGameStarted)
            playerIndex = @getPlayerIndex(username)
            if playerIndex > -1
              @players.splice(playerIndex, 1)
              @playerNames.splice(playerIndex, 1)
              @playerGameStarted.splice(playerIndex, 1)
              @playerGameWon.splice(playerIndex, 1)
              @playerCount--

              app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                callback.call(@, error: false, room: @roomState())

            # We're trying to remove a player that doesn't exist
            else callback.call(@, error: true, code: 22)

          # The game has already started
          else callback.call(@, error: true, code: 21)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 20)

    # Start game
    startGame: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'notstarted'

            playerIndex = @getPlayerIndex(username)
            @playerGameStarted[playerIndex] = true

            # All users agreed to start game
            if _.all(@playerGameStarted)
              @gameState = 'started'
              @deck.getShuffledDeck()
              _.each @players, (player) ->
                _.times 8, ->
                  topCard = @deck.topCard()
                  player.addToSet(topCard)
                  @deck.removeCard(topCard)
              @nextPlayer()

            app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
              callback.call(@, error: false, room: @roomState())

          # Game has already started
          else callback.call(@, error: true, code: 31)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 30)

    # Play card
    playCard: (data, callback) ->
      { username, card } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)
            if @players[playerIndex].hasCard(card)
              if @playerGameWon[playerIndex]
                if @pile.possibleNextMove(card)
                  @players[playerIndex].removeCard(card)
                  @pile.addCard(card)

                  unless @players[playerIndex].isActive()
                    @playerGameWon[playerIndex] = _.max(@playerGameWon) + 1

                  if _.all(@playerGameWon)
                    @gameState = 'ended'
                    app.client.del "room:#{@id}", (err, data) =>
                      callback.call(@, error: false, room: @roomState())

                  else
                    @nextPlayer()
                    app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                      callback.call(@, error: false, room: @roomState())

                # Invalid move!
                else callback.call(@, error: true, code: 44)

              # Player has already won
              else callback.call(@, error: true, code: 43)

            # Player does not have the card
            else callback.call(@, error: true, code: 42)

          # Game is not in progress
          else callback.call(@, error: true, code: 41)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 40)

    drawCard: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)

            topCard = @deck.topCard()
            @players[playerIndex].addCard(topCard)
            @deck.removeCard(topCard)

            app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
              callback.call(@, error: false, room: @roomState())

          # Game is not in progress
          else callback.call(@, error: true, code: 51)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 50)

    skipTurn: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'started'
            if playerNames[@currentPlayer] == username
              @nextPlayer()

            # Turn skipper is not current player
            else callback.call(@, error: true, code: 62)

          # Game is not in progress
          else callback.call(@, error: true, code: 61)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 60)


    disconnect: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists

          # Game has not started yet
          if @gameState == 'notstarted'
            @removePlayer { username }, callback

          # Game is in progress
          else if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)
            unless @players[playerIndex].isActive()

              # Destroy game if an active player disconnects
              @gameState = 'disconnected'
              app.client.del "room:#{@id}", (err, data) =>
                callback.call(@, error: false, room: @roomState())

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 70)

    # Helpers

    roomHash: ->
      returnVal = {
        @playerCount, @currentPlayer
        deck: @deck.getHand(), pile: @pile.getHand()
      }
      _.times @playerCount, (index) =>
        returnVal["player-#{index}"] = @players[index].getHand()
        returnVal["player-#{index}-name"] = @playerNames[index]
        returnVal["player-#{index}-start"] = if @playerGameStarted[index] then "true" else "false"
        returnVal["player-#{index}-won"] = @playerGameWon[index]

      returnVal

    roomState: ->
      returnVal = {
        @playerCount, @currentPlayer
        deck: @deck.topCard(), pile: @pile.topCard()
        @playerNames, @playerGameStarted, @playerGameWon
      }
      returnVal.players = []
      _.times @playerCount, (index) =>
        returnVal.players.push @players[index].getHand()

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
      if (@players[@currentPlayer].isActive())
        @currentPlayer
      else
        @nextPlayer()

    getPlayerIndex: (username) ->
      @playerNames.indexOf username
