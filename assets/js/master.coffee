chatApp = angular.module 'chat-app', ['socketIO']

ChatCtrl = ($scope, $socket) ->
  $scope.messages = []

  $scope.room = 0

  $socket.emit 'room:new', room: $scope.room

  $socket.on "room:id:#{$scope.room}:initial", (data) ->
    throw "Invalid value from server" unless data instanceof Array
    appendMessage(item) for item in data

  $socket.on "room:id:#{$scope.room}", appendMessage

  $scope.sendMessage = ->
    if $scope.currentMessage && $scope.currentUser
      $socket.emit 'message:send',
        user: $scope.currentUser
        message: $scope.currentMessage
        room: $scope.room
      $scope.currentMessage = ''

  appendMessage = (input) ->
    { user, message } = input
    throw "Invalid value from server" unless user? && message?
    $scope.messages.push { user, message }

chatApp.controller 'ChatCtrl', ['$scope', '$socket', ChatCtrl]
