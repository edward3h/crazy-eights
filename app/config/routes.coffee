_ = require 'underscore'
_s = require 'underscore.string'

# Routes file
module.exports = (app, client, io) ->

  app.get '*', (req, res) -> res.render 'index', view: 'index'

  io.sockets.on 'connection', (socket) ->

    socket.on 'room:new', (data) ->
      { room } = data
      client.lrange "room:id:#{room}", 0, 100, (err, data) ->
        returnVal = _.map data, (string) ->
          user: _s.words(string)[0]
          message: _s.strRight(string, ' ')
        io.to(socket.id).emit "room:id:#{room}:initial", returnVal

    socket.on 'message:send', (data) ->
      { room, user, message } = data

      return if _s.isBlank(user) && _s.isBlank(message)
      user = _s.clean(user)
      message = _s.clean(message)

      client.rpush "room:id:#{room}", "#{user} #{message}", (err, res) ->
        io.sockets.emit "room:id:#{room}", { user, message }

    socket.on 'room:nuke', (data) ->
      { room, user } = data
      client.del "room:id:#{room}", (err, res) ->
        io.sockets.emit "nuked:id:#{room}", { user }


