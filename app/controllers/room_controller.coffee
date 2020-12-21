
module.exports = (app) ->
  { RoomModel } = app.locals

  class RoomController

    # Returns room state
    @create: (req, res) ->
      console.log 'RoomController.create'

      new RoomModel null, (data) -> res.json(data)

    # Expects room ID
    # Returns room state
    @show: (req, res) ->
      console.log 'RoomController.show'

      { roomid } = req.params

      new RoomModel roomid, (data) -> res.json(data)

    # expects room ID
    @exists: (req, res) ->
      console.log 'RoomController.exists'

      { roomid } = req.params

      if roomid
        roomid = roomid.toLowerCase()
        app.client.exists "room:#{roomid}", (err, exists) =>
          if exists == 1
            res.sendStatus 200
          else
            res.sendStatus 404
      else
        res.sendStatus 400