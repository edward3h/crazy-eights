_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  { CardSetModel } = app.locals

  class RoomModel

    constructor: (@id, callback) ->
      # Reset all values
      @playerCards = []
      @playerNames = []
      @playerGameStarted = []
      @playerGameWon = []
      @playerCount = 0
      @currentPlayer = -1
      @deck = new CardSetModel()
      @pile = new CardSetModel()

      @gameState = 'notstarted'
      # States:
      # notstarted - Game has not started
      # started - Game is in progress
      # ended - The game ended
      # disconnected - An active player disconnected, and the game is now destroyed

      @exists (roomExists) =>
        if roomExists
          app.client.hgetall "room:#{@id}", (err, room) =>
            { @gameState, deck, pile } = room
            @currentPlayer = parseInt(room.currentPlayer, 10)
            @playerCount = parseInt(room.playerCount, 10)
            @deck = new CardSetModel(deck)
            @pile = new CardSetModel(pile)
            for index in [0...@playerCount]
              @playerCards.push new CardSetModel(room["player-#{index}"])
              @playerNames.push(room["player-#{index}-name"])
              @playerGameStarted.push(room["player-#{index}-start"] == 'true')
              @playerGameWon.push(parseInt(room["player-#{index}-won"], 10))

            callback.call(@, @roomState())
        else
          @createRoom =>
            callback.call(@, @roomState())
      @

    # Add player
    addPlayer: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'notstarted'
            if @getPlayerIndex(username) == -1

              @playerCards.push new CardSetModel()
              @playerNames.push username
              @playerGameStarted.push false
              @playerGameWon.push 0
              @playerCount++

              app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                callback.call(@, error: false, room: @roomState())

            # The username already exists
            else callback.call(@, error: true, code: 12)

          # The game has already started
          else callback.call(@, error: true, code: 11)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 10)

    # Remove player
    removePlayer: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'notstarted'
            playerIndex = @getPlayerIndex(username)
            if playerIndex > -1
              @playerCards.splice(playerIndex, 1)
              @playerNames.splice(playerIndex, 1)
              @playerGameStarted.splice(playerIndex, 1)
              @playerGameWon.splice(playerIndex, 1)
              @playerCount--

              if @playerCount == 0
                @gameState = 'disconnected'
                app.client.del "room:#{@id}", @roomHash(), (err, data) =>
                  callback.call(@, error: false, room: @roomState())

              else
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
            unless playerIndex == -1

              @playerGameStarted[playerIndex] = true

              # All users agreed to start game
              if @playerCount >= 2 && _.all(@playerGameStarted)
                @gameState = 'started'
                @deck.getShuffledDeck()
                for playerCard in @playerCards
                  for n in [1..8]
                    playerCard.addCard @deck.popCard()
                @nextPlayer()

              app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                callback.call(@, error: false, room: @roomState())

            # Player doesn't exist
            else callback.call(@, error: true, code: 32)

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
            unless playerIndex == -1
              if playerIndex == @currentPlayer
                if @playerCards[playerIndex].hasCard(card)
                  if @playerGameWon[playerIndex] == 0
                    if @pile.possibleNextMove(card)
                      @pile.addCard @playerCards[playerIndex].removeCard(card)

                      unless @playerCards[playerIndex].isActive()
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
                    else callback.call(@, error: true, code: 46)

                  # Player has already won
                  else callback.call(@, error: true, code: 45)

                # Player does not have the card
                else callback.call(@, error: true, code: 44)

              # Player isn't playing right now
              else callback.call(@, error: true, code: 43)

            # Player doesn't exist
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
            unless playerIndex == -1
              if playerIndex == @currentPlayer

                topCard = @deck.topCard()
                @playerCards[playerIndex].addCard @deck.removeCard(topCard)

                @nextPlayer()

                app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                  callback.call(@, error: false, room: @roomState())

              # Player isn't playing right now
              else callback.call(@, error: true, code: 53)

            # Player doesn't exist
            else callback.call(@, error: true, code: 52)

          # Game is not in progress
          else callback.call(@, error: true, code: 51)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 50)

    skipTurn: (data, callback) ->
      { username } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)
            unless playerIndex == -1
              if playerIndex == @currentPlayer
                @nextPlayer()

                app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                  callback.call(@, error: false, room: @roomState())

              # Player isn't playing right now
              else callback.call(@, error: true, code: 62)

            # Player doesn't exist
            else callback.call(@, error: true, code: 52)

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
            if playerIndex > -1 && !@playerCards[playerIndex].isActive()

              # Destroy game if an active player disconnects
              @gameState = 'disconnected'
              app.client.del "room:#{@id}", (err, data) =>
                callback.call(@, error: false, room: @roomState())

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 70)

    # Helpers

    roomHash: ->
      hash = {
        @playerCount, @currentPlayer, @gameState
        deck: @deck.getSet(), pile: @pile.getSet()
      }
      for index in [0...@playerCount]
        hash["player-#{index}"] = @playerCards[index].getSet()
        hash["player-#{index}-name"] = @playerNames[index]
        hash["player-#{index}-start"] = if @playerGameStarted[index] then "true" else "false"
        hash["player-#{index}-won"] = @playerGameWon[index]

      hash

    roomState: ->
      state = {
        room: @id
        @playerCount, @currentPlayer, @gameState
        pile: @pile.topCard()
        @playerNames, @playerGameStarted, @playerGameWon
        playerCards: []
      }
      for index in [0...@playerCount]
        state.playerCards.push @playerCards[index].getSet()

      state

    exists: (callback) ->
      if @id
        app.client.exists "room:#{@id}", (err, exists) =>
          callback.call(@, exists == 1)
      else callback.call(@, false)

    createRoom: (callback) ->
      @id = Math.floor(Math.random() * 90000) + 10000
      @exists (roomExists) =>
        unless roomExists
          app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
            callback.call(@)

        # We got a room that already exists
        else @createRoom(callback)

    nextPlayer: ->
      @currentPlayer = (parseInt(@currentPlayer, 10) + 1) % @playerCount
      if (@playerCards[@currentPlayer].isActive())
        @currentPlayer
      else
        @nextPlayer()

    getPlayerIndex: (username) ->
      @playerNames.indexOf username
