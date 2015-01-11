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

    socket.on 'message:send', (data) ->
      { room, user, message } = data

      return if _s.isBlank(user) && _s.isBlank(message)
      user = _s.clean(user)
      message = _s.clean(message)

      app.client.rpush "room:id:#{room}", "#{user} #{message}", (err, res) ->
        app.io.sockets.emit "room:id:#{room}", { user, message }

    socket.on 'room:nuke', (data) ->
      { room, user } = data
      app.client.del "room:id:#{room}", (err, res) ->
        app.io.sockets.emit "nuked:id:#{room}", { user }


