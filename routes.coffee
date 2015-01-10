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

    socket.on 'initial', (data) ->
      { room } = data
      client.lrange "room-#{room}", 0, 100, (err, data) ->
        data = _.map data, (string) ->
          user: string.substr(0, string.indexOf(' '))
          message: string.substr(string.indexOf(' ') + 1)

        io.to(socket.id).emit "room-#{room}", data

    socket.on 'send', (data) ->
      { room, user, message } = data
      return if !user? || user == ''
      return if !message? || message == ''
      client.rpush "room-#{room}", "#{user} #{message}", (err, res) ->
        io.sockets.emit "room-#{room}", { user, message }

    socket.on 'nuke', (data) ->
      { room, user } = data
      client.del "room-#{room}", (err, res) ->
        io.sockets.emit "nuked-#{room}", { user }



