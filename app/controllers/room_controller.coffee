
module.exports = (app) ->
  { RoomModel } = app.locals

  class RoomController

    # Expects password
    # Returns room id
    @create: (req, res) ->
      { password } = req.body

      model = new RoomModel(null, password)
      model.createRoom {}, (data) =>
        res.json(data)

    # Expects room ID and (optional) password
    # Returns last 100 messages
    @show: (req, res) ->
      { roomid } = req.params
      { password } = req.query

      model = new RoomModel(roomid, password)
      model.loadRoom {}, (data) =>
        res.json(data)
