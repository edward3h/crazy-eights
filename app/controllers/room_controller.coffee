
module.exports = (app) ->
  { RoomModel } = app.locals

  class RoomController

    # Returns room state
    @create: (req, res) ->
      model = new RoomModel null, (data) ->
        res.json(data)

    # Expects room ID
    # Returns room state
    @show: (req, res) ->
      { roomid } = req.params

      model = new RoomModel roomid, (data) ->
        res.json(data)
