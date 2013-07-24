Sockets    = require './sockets'
WSAdapter  = require './adapters/ws/ws'
Api        = require './api'

# Initialize Websockets server, with the websockets adapter
ws = new Sockets(8080, WSAdapter)

# Initialize API
api = new Api(ws)

# ws.on 'connection', (socket) ->
#   console.log "Connection"
  
#   socket.write(JSON.stringify
#     event: 'pusher:connection_established'
#     data:
#       socket_id: socket.id
#   )

#   interval = setInterval(->
#     socket.write(JSON.stringify({event: "pusher:ian_event", data: "omfg"}))
#   , 5000)

#   socket.on 'close', -> 
#     console.log "Closed"
#     clearInterval(interval)

# wsHTTP = http.createServer()
# # wsHTTP.addListener 'request', (req, res) ->
# #     static_directory.serve(req, res)

# # wsHTTP.addListener 'upgrade', (req,res) -> res.end()

# ws.installHandlers wsHTTP, prefix:'/app/pusherKey'
# # ws.installHandlers wsHTTP, prefix:'/pusher'
# wsHTTP.listen 8080