express =      require 'express'
connect =      require 'connect-assets'
autoprefixer = require 'express-autoprefixer'
redis =        require 'redis'
io =           require 'socket.io'
url =          require 'url'
pug = require 'pug'
favicon = require('serve-favicon')
logger = require('morgan')
bodyParser = require('body-parser')
methodOverride = require('method-override')
errorHandler = require('errorhandler')

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

env = process.env.NODE_ENV || 'development'
# all environments
app.set 'port', process.env.PORT or PORT
app.engine('pug', pug.__express)
app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'pug'
app.use favicon("#{__dirname}/public/favicon.ico")
app.use logger('dev') if env is 'development'
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))
app.use methodOverride()

app.use autoprefixer
  browsers: 'last 5 versions'
  cascade: false
app.use connect(src: "#{__dirname}/assets", fingerprinting: true)

app.use express.static("#{__dirname}/public")
app.use '/assets/webfonts', express.static("#{__dirname}/assets/vendor/components-font-awesome/webfonts")
# app.use app.router

# development only
if env is "development"
  app.use errorHandler()
  # app.locals.pretty = true

# test only
if env is 'test'
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
