#= require js/controllers.coffee
#= require js/factories.coffee

angular.module 'chat-app', [
  'ngRoute'
  'chat-app.factories'
  'chat-app.controllers'
]
.config ($routeProvider, $locationProvider) ->
  $routeProvider

    .when '/',
      templateUrl: 'index'
      controller: 'ChatCtrl'

    .otherwise redirectTo: '/'

  $locationProvider.html5Mode true
