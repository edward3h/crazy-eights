express =      require 'express.io'
connect =      require 'connect-assets'
autoprefixer = require 'express-autoprefixer'
redis =        require 'redis'
routes =       require './routes'
io =           require 'socket.io'

# Initialize Express and redis
exports.app = app = express()
client = redis.createClient()

# Determine port and environment
port = process.env.PORT or 3000
env = app.get 'env'

# all environments
app.configure ->
  app.set 'port', port
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.favicon("#{__dirname}/public/favicon.ico")
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()

  app.use autoprefixer
    browsers: 'last 5 versions'
    cascade: false
  app.use connect()

  app.use express.static("#{__dirname}/public")
  app.use app.router

# development only
app.configure "development", ->
  app.use express.errorHandler()

io = io.listen app.listen port, ->
  console.log "Site running at port #{port} in #{env} mode"

routes app, client, io
