#= require_tree shared

#= require vendor/angular/angular.min.js
#= require vendor/angular-route/angular-route.min.js

#= require javascripts/controllers.coffee
#= require javascripts/factories.coffee

angular.module('chat-app', [
  'ngRoute'
  'chat-app.factories'
  'chat-app.controllers'
]).config ($routeProvider, $locationProvider) ->

  $routeProvider
    .when '/',
      templateUrl: 'partials/main'
      controller: 'MainCtrl'
    .when '/:room',
      templateUrl: 'partials/room'
      controller: 'ChatCtrl'

    .otherwise redirectTo: '/'

  $locationProvider.html5Mode(true)
