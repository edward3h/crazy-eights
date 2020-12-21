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
  app.get pathRaw('room.exists'), RoomController.exists

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
      { error, code, room } = data
      if error
        console.log "Emmitting room:#{roomid}:error"
        console.log { code }
        app.io.emit "room:#{roomid}:error", { code }
      else
        console.log "Emmitting room:#{roomid}:update"
        console.log { room }
        app.io.emit "room:#{roomid}:update", { room }
      console.log ""

    # handle disconnects
    socket.on 'disconnect', ->
      if roomid && username
        new RoomModel roomid, ->
          @disconnect { username }, updateEveryone

    # User wants to join with a username
    socket.on 'room:join', (data) ->
      { joiningRoomid, joiningUsername } = data
      console.log "room:join with id:#{joiningRoomid} username:#{joiningUsername}"
      new RoomModel joiningRoomid, ->
        roomid = joiningRoomid
        username = joiningUsername
        @addPlayer { username }, updateEveryone

    # Leave room
    socket.on 'room:unjoin', (data) ->
      console.log "room:unjoin with id:#{roomid} username:#{username}"
      new RoomModel roomid, ->
        @removePlayer { username }, (data) ->
          roomid = 0
          username = ''
          updateEveryone(data)

    # Start a game
    socket.on 'room:start', (data) ->
      console.log "room:start with id:#{roomid} username:#{username}"
      new RoomModel roomid, ->
        @startGame { username }, updateEveryone

    # Play a card
    socket.on 'room:card:play', (data) ->
      { card } = data
      console.log "room:card:play with id:#{roomid} username:#{username} card:#{card}"
      new RoomModel roomid, ->
        @playCard { username, card }, updateEveryone

    # Choose Wild card color
    socket.on 'room:card:chooseColor', (data) ->
      { color } = data
      console.log "room:card:chooseColor with id:#{roomid} username:#{username} color:#{color}"
      new RoomModel roomid, ->
        @chooseColor { username, color }, updateEveryone

    # Draw a card
    socket.on 'room:card:draw', (data) ->
      console.log "room:card:draw with id:#{roomid} username:#{username}"
      new RoomModel roomid, ->
        @drawCard { username }, updateEveryone

    # Skip a turn
    socket.on 'room:card:skip', (data) ->
      console.log "room:card:skip with id:#{roomid} username:#{username}"
      new RoomModel roomid, ->
        @skipTurn { username }, updateEveryone

    # play again or end
    socket.on 'room:playAgain', (data) ->
      { b } = data
      console.log "room:playAgain with id:#{roomid} username:#{username} value:#{b}"
      new RoomModel roomid, ->
        if b 
          @startGame { username }, updateEveryone
        else
          @removePlayer { username }, (data) ->
            roomid = 0
            username = ''
            updateEveryone(data)
         