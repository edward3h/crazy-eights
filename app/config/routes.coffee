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

    socket.on 'message:send', (data) =>
      { room, password, user, message } = data

      return if _s.isBlank(user) && _s.isBlank(message)

      model = new RoomModel(room, password)
      model.sendMessage { user, message }, (sent) =>
        if sent
          app.io.sockets.emit "room:id:#{room}", { user, message }
        else
          app.io.sockets.socket(socket.id).emit "room:id:#{room}:message:error", { code: 1 }

    socket.on 'room:nuke', (data) =>
      { room, password, user } = data

      model = new RoomModel(room, password)
      model.nukeRoom (nuked) =>
        if nuked
          app.io.sockets.emit "room:id:#{room}:nuked", { user }
        else
          app.io.sockets.socket(socket.id).emit "room:id:#{room}:nuke:error", { code: 2 }

