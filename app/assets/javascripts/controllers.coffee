#= require vendor/underscore/underscore-min.js
#= require vendor/angular/angular.min.js
#= require vendor/angular-route/angular-route.min.js

angular.module 'chat-app.controllers', []

.controller 'ChatCtrl', ['$scope', '$socket', '$http', '$routeParams', '$location',
  ($scope, $socket, $http, $routeParams, $location) ->

    # Initial scope
    _.extend $scope,
      messages: []
      room: $routeParams.room
      password: ''
      loading: true
      errors:
        doesNotExist: false
        enterPassword: false
        wrongPassword: false

    appendMessage = (input) ->
      { user, message } = input
      throw "Invalid value from server" unless user? && message?
      $scope.messages.push { user, message }

    ($scope.loadRoom = ->
      $scope.loading = true
      { room, password } = $scope
      data = {}
      _.extend data, { password } if password
      $http.get("/rooms/#{room}", data)
      .success (data, status, headers, config) ->
        if data.error
          switch data.code
            when 1
              $scope.errors.doesNotExist = true
            when 2
              if $scope.errors.enterPassword && !$scope.errors.wrongPassword
                $scope.errors.enterPassword = false
                $scope.errors.wrongPassword = true
              else
                $scope.errors.enterPassword = false
          $scope.loading = false
        else
          $scope.room = parseInt(room, 10)
          appendMessage(item) for item in data.messages
          $scope.loading = false
          $socket.on "room:id:#{$scope.room}", appendMessage
    )()

    $scope.sendMessage = ->
      console.log 'SENDING MESSAGE'
      if $scope.currentMessage && $scope.currentUser
        $socket.emit 'message:send',
          user: $scope.currentUser
          message: $scope.currentMessage
          room: $scope.room
        $scope.currentMessage = ''

    $scope.goHome = ->
      $location.url '/'

]

.controller 'MainCtrl', ['$scope', '$http', '$location',
  ($scope, $http, $location) ->
    $scope.hi = "DUUUUUUUUUDE"



    $scope.createRoom = ->

      $http.post('/rooms', password: $scope.password)
      .success (data, status, headers, config) ->
        { error, code, room } = data

        # TODO: error handling

        $location.url "/#{room}"
]
