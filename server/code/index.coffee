express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
cons = require 'consolidate'
request = require 'request'
bcrypt = require 'bcrypt'

passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

app = express()

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (obj, done) ->
  done null, obj

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser('SECRET')
  app.use express.session({ cookie: { maxAge: 60000 }, secret: 'SECRET'})
  app.use require('connect-flash')()
  app.use passport.initialize()
  app.use passport.session()

  app.use assets({src: 'client'})
  # Set the public folder as static assets
  app.use express.static(process.cwd() + '/shared')
  app.use express.favicon()



# Auth with cobalt
authenticateProfile = (profile, password, done) ->
  console.warn "#{profile} #{password}"
  # Must the password be plaintext?
  options =
    uri: 'https://boxecutor-dev-1.scraperwiki.net/passwd_auth/'
    form:
      profile: profile
      password: password

  request.post options, (err, resp, body) ->
    if resp.statusCode is 200
      done true
    else
      done false


# Passport.js spike
strategy = (username, password, done) ->
  authenticateProfile username, password, (authed) ->
    if authed
      return done null, {id:1, username: 'chris'}
    else
      done null, false, message: 'WRONG'

passport.use 'local', new LocalStrategy(strategy)


# Set View Engine
app.set 'views', 'server/template'
app.engine 'html', cons.jazz
app.set 'view engine', 'html'
js.root = 'code'


ensureAuthenticated = (req, res, next) ->
  return next()  if req.isAuthenticated()
  res.redirect "/login"

app.post "/login", passport.authenticate("local",
  successRedirect: "/"
  failureRedirect: "/login"
  failureFlash: true
)

app.get '/login', (req, resp) ->
  resp.render 'login'

app.all '*', ensureAuthenticated

# TODO: sort out nice way of serving templates
app.get '/tpl/:page', (req, resp) ->
  resp.render req.params.page

app.get '*', (req, resp) ->
  resp.render 'index', { scripts: js 'app' }

# Define Port
port = process.env.PORT or process.env.VMC_APP_PORT or 3000
# Start Server
app.listen port, ->
  console.log "Listening on #{port}\nPress CTRL-C to stop server."
