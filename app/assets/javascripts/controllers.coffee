#= require vendor/underscore/underscore-min.js
#= require vendor/underscore.string/dist/underscore.string.min.js
#= require vendor/angular/angular.min.js
#= require vendor/angular-route/angular-route.min.js

angular.module 'crazy-eights.controllers', []

.controller 'ChatCtrl', ['$scope', '$socket', '$http', '$routeParams', '$location', '$timeout'
  ($scope, $socket, $http, $routeParams, $location, $timeout) ->

    # Initial scope
    _.extend $scope,
      messages: []
      room: $routeParams.room.toLowerCase()
      loading: true
      login: false
      error: ''
      colors: ['red', 'green', 'blue', 'yellow']

    ($scope.loadRoom = ->
      $scope.loading = true
      $http.get("/rooms/#{$scope.room}")
      .success (data, status, headers, config) ->
        { room } = data
        _.extend $scope,
          room: room
          loading: false
          login: true

        $location.url "/#{room}"
    )()

    $scope.joinRoom = ->
      return unless $scope.login
      $socket.on "room:#{$scope.room}:error", loadError
      $socket.on "room:#{$scope.room}:update", loadRoomData
      $socket.emit 'room:join', { joiningRoomid: $scope.room, joiningUsername: $scope.username }
      $scope.login = false

    $scope.startGame = ->
      return if $scope.login
      $socket.emit 'room:start'

    $scope.playCard = (card) ->
      return if $scope.login
      return unless $scope.playerIndex == $scope.roomInfo.currentPlayer
      $socket.emit 'room:card:play', { card }

    $scope.chooseColor = (color) ->
      return if $scope.login
      return unless $scope.playerIndex == $scope.roomInfo.currentPlayer
      $socket.emit 'room:card:chooseColor', { color }

    $scope.drawCard = ->
      return if $scope.login
      return unless $scope.playerIndex == $scope.roomInfo.currentPlayer
      $socket.emit 'room:card:draw'

    $scope.skipTurn = ->
      return if $scope.login
      return unless $scope.playerIndex == $scope.roomInfo.currentPlayer
      $socket.emit 'room:card:skip'

    $scope.playAgain = (b) ->
      return if $scope.login
      $socket.emit 'room:playAgain', { b }
      unless b
        $timeout ( -> window.location.href = '/'), 100

    $scope.copyCode = () ->
      el = document.getElementById('roomCode')
      el.select()
      document.execCommand('copy')
      $scope.copied = true

    loadError = (data) ->
      { code } = data
      console.log 'received ERROR', code
      switch code
        when 46
          $scope.invalidMove = true
          $timeout ( -> $scope.invalidMove = false ), 2000
        when 10, 20, 30, 40, 50, 60, 70
          $scope.error = 'doesnt exist'
          $scope.fatal = true
        else
          $scope.error = 'some unknown error'
          $scope.error_code = code

    loadRoomData = (data) ->
      { room } = data
      # console.log "received update", room
      $scope.playerIndex = room.playerNames.indexOf($scope.username)

      $scope.isMyTurn = (room.currentPlayer == $scope.playerIndex)
      $scope.alert = room.alert
      if alert
        $timeout ( -> $scope.alert = '' ), 2000
      $scope.myProperties =
        playerCards: s.chop(room.playerCards[$scope.playerIndex], 2)
        playerName: room.playerNames[$scope.playerIndex]
        playerStarted: room.playerGameStarted[$scope.playerIndex]
        playerWon: room.playerGameWon[$scope.playerIndex]

      $scope.players = room.playerNames.map (name, i) ->
        count = room.playerCards[i].length / 2
        cards = new Array(count).fill('x')
        { name, count, cards }
      if $scope.myProperties.playerCards
        $scope.myProperties.playerCards.sort()
      $scope.roomInfo = room
      $scope.direction = room.direction
      $scope.winner = if room.gameState == 'ended'
        room.playerNames[room.playerGameWon.indexOf(1)]

]

.controller 'MainCtrl', ['$scope', '$http', '$location',
  ($scope, $http, $location) ->

    $scope.createRoom = ->

      $http.post('/rooms')
      .success (data, status, headers, config) ->
        { error, code, room } = data

        # TODO: error handling

        $location.url "/#{room}"

    $scope.joinRoom = ->
      $http.get("/rooms/#{$scope.room}/exists")
      .success (data, status, headers, config) ->
        $location.url "/#{$scope.room}"
      .error (data, status, headers, config) ->
        $scope.message = "Room does not exist"
        console.log data

] 
