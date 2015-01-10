module.exports = (app) ->
  class PartialsController
    @show = (req, res) -> res.render "partials/#{req.params.partialid}"
