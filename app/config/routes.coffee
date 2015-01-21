_ = require 'underscore'
_s = require 'underscore.string'

# Routes file
module.exports = (app) ->

  # Load controllers and helpers
  { PartialsController, RoomController } = app.locals
  { pathRaw } = app.locals.path

  # Default page
  app.locals.renderRoot = (req, res) -> res.render 'index', view: 'index'

  # API routes
  app.post pathRaw('room.create'), RoomController.create
  app.get pathRaw('room.show'), RoomController.show

  # Routes for partials
  app.get pathRaw('partial.show'), PartialsController.show

  # Routes for SPA
  app.get '/',      app.locals.renderRoot
  app.get '/:room', app.locals.renderRoot

  # Socket IO
  app.io.sockets.on 'connection', (socket) ->
    { RoomModel } = app.locals
    roomid = 0
    username = ''

    updateEveryone = (data) ->
      console.log "updating everyone in room #{roomid} with #{data}"
      { error, code, room } = data
      if error
        socket.emit 'room:#{roomid}:error', { code }
      else
        socket.emit "room:#{roomid}:update", { room, username }

    # handle disconnects
    socket.on 'disconnect', ->
      if roomid && username
        new RoomModel roomid, (roomState) ->
          @disconnect { username }, updateEveryone

    # User wants to join with a username
    socket.on 'room:join', (data) ->
      { joiningRoomid, joiningUsername } = data
      new RoomModel roomid, (roomState) ->
        roomid = joiningRoomid
        username = joiningUsername
        @addPlayer { username }, updateEveryone

    # Leave room
    socket.on 'room:unjoin', (data) ->
      new RoomModel roomid, (roomState) ->
        @removePlayer { username }, (data) ->
          roomid = 0
          username = ''
          updateEveryone(data)

    # Start a game
    socket.on 'room:start', (data) ->
      new RoomModel roomid, (roomState) ->
        @startGame { username }, updateEveryone

    # Play a card
    socket.on 'room:card:play', (data) ->
      { card } = data
      new RoomModel roomid, (roomState) ->
        @playCard { username, card }, updateEveryone

    # Draw a card
    socket.on 'room:card:draw', (data) ->
      new RoomModel roomid, (roomState) ->
        @drawCard { username }, updateEveryone

    # Skip a turn
    socket.on 'room:card:skip', (data) ->
      new RoomModel roomid, (roomState) ->
        @skipTurn { username }, updateEveryone

