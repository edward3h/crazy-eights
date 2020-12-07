express =      require 'express'
connect =      require 'connect-assets'
autoprefixer = require 'express-autoprefixer'
redis =        require 'redis'
io =           require 'socket.io'
url =          require 'url'

# Express
exports.app = app = express()

# Redis
if process.env.REDISCLOUD_URL
  redisCloud = url.parse(process.env.REDISCLOUD_URL)
  app.client = client = redis.createClient(redisCloud.port, redisCloud.hostname)
  if redisCloud.auth
    client.auth(redisCloud.auth.split(':')[1])
else
  app.client = client = redis.createClient()

# Determine port and environment
PORT = 3000
PORT_TEST = PORT + 1

# all environments
app.configure ->
  app.set 'port', process.env.PORT or PORT
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.favicon("#{__dirname}/public/favicon.ico")
  app.use express.logger('dev') if app.get('env') is 'development'
  app.use express.bodyParser()
  app.use express.methodOverride()

  app.use autoprefixer
    browsers: 'last 5 versions'
    cascade: false
  app.use connect(src: "#{__dirname}/assets", fingerprinting: true)

  app.use express.static("#{__dirname}/public")
  app.use app.router

# development only
app.configure "development", ->
  app.use express.errorHandler()
  # app.locals.pretty = true

# test only
app.configure 'test', ->
  app.set 'port', PORT_TEST

autoload = require('./config/autoload')(app)
autoload "#{__dirname}/assets/javascripts/shared", true
autoload "#{__dirname}/models"
autoload "#{__dirname}/controllers"

# listen
app.io = io = io.listen app.listen app.get('port'), ->
  port = app.get 'port'
  env = app.settings.env
  console.log "Site running at port #{port} in #{env} mode"

# routes
require('./config/routes')(app)

module.exports = app
