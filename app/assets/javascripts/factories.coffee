#= require vendor/angular/angular.min.js

angular.module 'chat-app.factories', []

.factory '$socket', ($rootScope) ->
  socket = io.connect("#{window.location.protocol}//#{window.location.host}")
  {
    on: (eventName, callback) ->
      socket.on eventName, ->
        args = arguments
        $rootScope.$apply ->
          callback.apply(socket, args)
    emit: (eventName, data, callback) ->
      socket.emit eventName, data, ->
        args = arguments
        $rootScope.$apply ->
          callback.apply(socket, args) if callback
  }
