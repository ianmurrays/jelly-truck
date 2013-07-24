WSAdapter  = require './adapters/ws/ws'
_          = require 'underscore'

module.exports = class Sockets
  constructor: (port = 8080, adapter) ->
    @wss = new adapter(port)

    _.bindAll this, 'onConnect'

    @wss.on 'adapter:connected', @onConnect

  onConnect: (socket) ->
    console.log "Adapter connected"
    socket.write 
      event: "pusher:connection_established"
      data:
        socket_id: socket.socketId

  triggerEvent: (event, channel, data) -> @wss.triggerEvent(event, channel, data)
  