_ = require 'underscore'
_s = require 'underscore.string'
crypto = require 'crypto'
shasum = crypto.createHash 'sha1'

module.exports = (app) ->
  class RoomModel
    constructor: (@id = null, @password = '') ->
      @

    # Create room
    createRoom: (data, callback) ->
      @id = Math.floor(Math.random() * 900000) + 100000
      @exists (roomExists) =>
        unless roomExists
          @setPassword (authenticated) =>
            if authenticated
              app.client.set "room:id:#{@id}:exists", true, (err, data) =>
                unless err? && err
                  callback.call(@, error: false, room: @id)

                # We got a Redis error
                else callback.call(@, error: true, code: 3)

            # We got a Redis error
            else callback.call(@, error: true, code: 2)

        # We got a room that already exists
        else @createRoom(data, callback)

    # Load room
    loadRoom: (data, callback) ->
      @exists (roomExists) =>
        if roomExists
          @authenticate (authenticated) =>
            if authenticated
              app.client.lrange "room:id:#{@id}", 0, 100, (err, messages) =>
                returnVal = _.map messages, (string) ->
                  user: _s.words(string)[0]
                  message: _s.strRight(string, ' ')
                callback.call(@, error: false, messages: returnVal)

            # We have the wrong password
            else callback.call(@, error: true, code: 2)

        # We're loading a room that doesn't exist
        else callback.call(@, error: true, code: 1)

    # Send a message in a room
    sendMessage: (data, callback) ->
      { user, message } = data
      @exists (roomExists) =>
        if roomExists
          @authenticate (authenticated) =>
            if authenticated
              user = _s.clean(user)
              message = _s.clean(message)
              app.client.rpush "room:id:#{@id}", "#{user} #{message}", (err, res) ->
                unless err? && err
                  callback.call(@, true)
                else callback.call(@, false)
            else callback.call(@, false)
        else callback.call(@, false)

    # Nuke a room
    nukeRoom: (data, callback) ->
      @exists (roomExists) =>
        if roomExists
          @authenticate (authenticated) =>
            if authenticated
              app.client.del "room:id:#{@id} room:id:#{@id}:exists room:id:#{@id}:password", (err, res) ->
                unless err? && err
                  callback.call(@, true)
                else callback.call(@, false)
            else callback.call(@, false)
        else callback.call(@, true)

    # Helpers

    exists: (callback) ->
      if @id
        app.client.exists "room:id:#{@id}:exists", (err, exists) =>
          callback.call(@, exists == 1)
      else callback.call(@, false)

    authenticate: (callback) ->
      if @password != ''
        hasPassword (serverPasswordExists) =>
          if serverPasswordExists
            app.client.get "room:id:#{@id}:password", (err, serverPassword) =>
              callback.call(@, @saltedPassword(@password) == serverPassword)
          else callback.call(@, true)
      else callback.call(@, true)

    hasPassword: (callback) ->
      app.client.exists "room:id:#{@id}:password", (err, serverPasswordExists) =>
        callback.call(@, serverPasswordExists == 1)

    setPassword: (callback) ->
      if @password != ''
        hasPassword (serverPasswordExists) =>
          unless serverPasswordExists
            app.client.set "room:id:#{@id}:password", @saltedPassword(@password), (err, res) =>
              unless err? && err
                callback.call(@, true)
              else callback.call(@, false)
          else callback.call(@, true)
      else callback.call(@, true)

    saltedPassword: (sha1) ->
      salt = process.env.SUPER_SECRET_SALT or 'super_not_secret_salt'
      shasum.update "#{salt}#{sha1}#{salt}"
      shasum.digest 'hex'


