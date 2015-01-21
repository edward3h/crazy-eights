
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
