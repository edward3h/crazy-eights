#= require vendor/underscore/underscore-min.js
#= require vendor/angular/angular.min.js
#= require vendor/angular-route/angular-route.min.js

angular.module 'crazy-eights.controllers', []

.controller 'ChatCtrl', ['$scope', '$socket', '$http', '$routeParams', '$location',
  ($scope, $socket, $http, $routeParams, $location) ->

    # Initial scope
    _.extend $scope,
      messages: []
      room: parseInt($routeParams.room, 10)
      loading: true
      login: false

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
      console.log "joining room #{$scope.room} with username #{$scope.username}"
      console.log "subscribing to room:#{$scope.room}:error"
      $socket.on "room:#{$scope.room}:error", (data) ->
        console.log 'Error has occurred'
        loadError(data.code)
      console.log "subscribing to room:#{$scope.room}:update"
      $socket.on "room:#{$scope.room}:update", (data) ->
        console.log 'Updating room'
        $scope.roomInfo = data.room
        console.log $scope.room
      $socket.emit 'room:join', { joiningRoomid: $scope.room, joiningUsername: $scope.username }
      $scope.login = false
      console.log $scope.room









    loadError = (code) ->
      switch code
        when 10, 20, 30, 40, 50, 60, 70
          $scope.error = 'hi doesnt exist lol'
        else
          $scope.error = 'lulz error'

    $scope.closeError = ->
      $scope.error = ''


]

.controller 'MainCtrl', ['$scope', '$http', '$location',
  ($scope, $http, $location) ->
    $scope.hi = "DUUUUUUUUUDE"



    $scope.createRoom = ->

      $http.post('/rooms')
      .success (data, status, headers, config) ->
        { error, code, room } = data

        # TODO: error handling

        $location.url "/#{room}"
]
