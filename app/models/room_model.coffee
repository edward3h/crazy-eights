_ = require 'underscore'
_s = require 'underscore.string'

module.exports = (app) ->
  { CardSetModel } = app.locals

  class RoomModel

    COLORS: ['red', 'green', 'blue', 'yellow']

    constructor: (@id, callback) ->
      # Reset all values
      @playerCards = []
      @playerNames = []
      @playerGameStarted = []
      @playerGameWon = []
      @playerCount = 0
      @currentPlayer = -1
      @direction = 1
      @playState = ''
      @wildColor = ''
      @pile = new CardSetModel()
      @deck = new CardSetModel('', (deck) ->
        if @pile.isActive()
          topCard = @pile.popCard()
          pileCards = _s.chop(@pile.getSet(), 2)
          pileCards = _.shuffle(pileCards)
          _.each(pileCards, (card) -> deck.addCard(card))
          @pile.clear()
          @pile.addCard(topCard)
      )

      @gameState = 'notstarted'
      # States:
      # notstarted - Game has not started
      # started - Game is in progress
      # ended - The game ended
      # disconnected - An active player disconnected, and the game is now destroyed

      @exists (roomExists) =>
        if roomExists
          app.client.hgetall "room:#{@id}", (err, room) =>
            { @gameState, deck, pile, @playState, @wildColor } = room
            @currentPlayer = parseInt(room.currentPlayer, 10)
            @playerCount = parseInt(room.playerCount, 10)
            @direction = parseInt(room.direction, 10)
            @deck = new CardSetModel(deck)
            @pile = new CardSetModel(pile)
            for index in [0...@playerCount]
              @playerCards.push new CardSetModel(room["player-#{index}"])
              @playerNames.push(room["player-#{index}-name"])
              @playerGameStarted.push(room["player-#{index}-start"] == 'true')
              @playerGameWon.push(parseInt(room["player-#{index}-won"], 10))

            callback.call(@, @roomState())
        else if @id != null
          throw "Room #{@id} not found"
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
          if @gameState == 'notstarted' || @gameState == 'ended'
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
                @startGame({}, callback)

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
          if @gameState == 'notstarted' || @gameState == 'ended'

            playerIndex = @getPlayerIndex(username)
            unless playerIndex == -1

              @playerGameStarted[playerIndex] = true

            # All users agreed to start game
            if @playerCount >= 2 && _.all(@playerGameStarted)
              @gameState = 'started'
              @playerGameWon= @playerGameWon.map (v) -> 0
              @pile.clear()
              @deck.getShuffledDeck()
              for playerCard in @playerCards
                playerCard.clear()
                for n in [1..7]
                  playerCard.addCard @deck.popCard()
              @pile.addCard @deck.popCard()
              while @pile.topCard().charAt(0) == 'x'
                @pile.addCard @deck.popCard()

              for n in [1.._.random(@playerCount)]
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
            unless playerIndex == -1
              if playerIndex == @currentPlayer
                if @playerCards[playerIndex].hasCard(card)
                  if @playerGameWon[playerIndex] == 0
                    if @pile.possibleNextMove(card, @wildColor, @playerCards[playerIndex])
                      @pile.addCard @playerCards[playerIndex].removeCard(card)
                      @wildColor = ''
                      @playState = ''

                      unless @playerCards[playerIndex].isActive()
                        @playerGameWon[playerIndex] = _.max(@playerGameWon) + 1

                      if _.select(@playerGameWon, ( (i) -> i )).length == 1
                        @gameState = 'ended'
                        @playerGameStarted = @playerGameStarted.map (v) -> false
                        app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                          callback.call(@, error: false, room: @roomState())

                      else
                        console.log("deck", @deck)
                        console.log("pile", @pile)
                        if card.charAt(0) == 'x' # wild card
                          @playState = 'chooseColor'
                        else if card.charAt(1) == 'r' && @playerCount > 2 # reverse
                          @direction *= -1
                          @alert = "Reversed direction"
                          @nextPlayer()
                        else if card.charAt(1) == 's' || (card.charAt(1) == 'r' && @playerCount == 2) # skip
                          @nextPlayer()
                          @alert = "Skipped player #{@playerNames[@currentPlayer]}"
                          @nextPlayer()
                        else if card.charAt(1) == 'd' # draw 2
                          @nextPlayer()
                          @alert = "Player #{@playerNames[@currentPlayer]} had to draw 2"
                          for n in [1..2]
                            @playerCards[@currentPlayer].addCard @deck.popCard()
                          @nextPlayer()
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

    chooseColor: (data, callback) ->
      { username, color } = data
      @exists (roomExists) =>
        if roomExists
          if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)
            unless playerIndex == -1
              if playerIndex == @currentPlayer
                console.log('chooseColor', data, @)
                if @playState == 'chooseColor'
                  if @playerGameWon[playerIndex] == 0
                    if @validColor(color)
                      @playState = ''
                      @wildColor = color
                      card = @pile.topCard()
                      if card.charAt(1) == '4' # draw 4
                        @nextPlayer()
                        @alert = "Player #{@playerNames[@currentPlayer]} had to draw 4"
                        for n in [1..4]
                          @playerCards[@currentPlayer].addCard @deck.popCard()
                      @nextPlayer()
                      app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
                        callback.call(@, error: false, room: @roomState())

                    # Invalid move!
                    else callback.call(@, error: true, code: 46)

                  # Player has already won
                  else callback.call(@, error: true, code: 45)

                # not waiting for color
                else callback.call(@, error: true, code: 81)

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

                topCard = @deck.popCard()
                @playerCards[playerIndex].addCard topCard
                if @pile.possibleNextMove(topCard, @wildColor, @playerCards[playerIndex])
                  @playState = 'playDraw'
                else
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
                @playState = ''
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
          if @gameState == 'notstarted' || @gameState == 'ended'
            @removePlayer { username }, callback

          # Game is in progress
          else if @gameState == 'started'
            playerIndex = @getPlayerIndex(username)
            if playerIndex > -1 && @playerCards[playerIndex].isActive()

              # Destroy game if an active player disconnects
              @gameState = 'disconnected'
              app.client.del "room:#{@id}", (err, data) =>
                callback.call(@, error: true, code: 82, message: "Player #{username} disconnected")

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 70)

    # Helpers

    roomHash: ->
      hash = {
        @playerCount, @currentPlayer, @gameState, @playState, @direction, @wildColor
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
        @playerCount, @currentPlayer, @gameState, @playState, @direction, @wildColor, @alert
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
      # @id = Math.floor(Math.random() * parseInt("yzzzz", 36)) + 10000
      @id = Math.floor(Math.random() * parseInt("yzz", 36)) + 100
      @id = @id.toString(36)
      @exists (roomExists) =>
        unless roomExists
          app.client.hmset "room:#{@id}", @roomHash(), (err, data) =>
            callback.call(@)

        # We got a room that already exists
        else @createRoom(callback)

    nextPlayer: ->
      @currentPlayer = (parseInt(@currentPlayer, 10) + @direction + @playerCount) % @playerCount
      if (@playerCards[@currentPlayer].isActive())
        @currentPlayer
      else
        @nextPlayer()

    getPlayerIndex: (username) ->
      @playerNames.indexOf username

    validColor: (color) ->
      console.log("validColor", color, @COLORS)
      _.contains(@COLORS, color)
