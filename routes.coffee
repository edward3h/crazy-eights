_ = require 'underscore'

# Routes file
module.exports = (app, client, io) ->
  # Universal Headers
  app.get '*', (req, res, next) ->
    res.header 'X-UA-Compatible', 'IE=edge'
    next()

  app.get '/', (req, res) ->
    res.render 'index'

  io.sockets.on 'connection', (socket) ->

    socket.on 'room:new', (data) ->
      { room } = data
      client.lrange "room:id:#{room}", 0, 100, (err, data) ->
        returnVal = _.map data, (string) ->
          user: string.substr(0, string.indexOf(' '))
          message: string.substr(string.indexOf(' ') + 1)
        io.to(socket.id).emit "room:id:#{room}:initial", returnVal

    socket.on 'message:send', (data) ->
      { room, user, message } = data

      return unless goodInput(user) && goodInput(message)
      user = user.trim()
      message = message.trim()

      client.rpush "room:id:#{room}", "#{user} #{message}", (err, res) ->
        io.sockets.emit "room:id:#{room}", { user, message }

    socket.on 'room:nuke', (data) ->
      { room, user } = data
      client.del "room:id:#{room}", (err, res) ->
        io.sockets.emit "nuked:id:#{room}", { user }


  # Helpers
  goodInput = (string) -> string? && string.trim() != ''

