Sockets    = require './lib/sockets'
WSAdapter  = require './lib/adapters/ws/ws'
Api        = require './lib/api'

# Initialize Websockets server, with the websockets adapter
ws = new Sockets(8080, WSAdapter)

# Initialize API
api = new Api(ws)
