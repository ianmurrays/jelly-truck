_              = require "underscore"
{EventEmitter} = require "events"

module.exports = class Socket extends EventEmitter
  channels: []

  constructor: (@adapter, @socket) ->
    @socketId = @socket.id

    _.bindAll this, 'onMessage', 'onClose'

    @socket.on 'message', @onMessage
    @socket.on 'close', @onClose

  onMessage: (message) ->
    try
      message = JSON.parse(message)
    catch e
      console.log e

    # Call the method with the same name as the event
    message.event = message.event.replace /^pusher:/, "pusher_"
    this[message.event](message.data)

  onClose: () ->
    console.log "On close"
    console.log @channels
    for channel in @channels
      console.log "removing subscription from #{channel}"
      delete _.indexOf(@channels, channel)
      @adapter.unsubscribe(this, channel)
      
  # Public: writes an object as stringified JSON
  write: (object) -> @socket.send JSON.stringify(object)

  ############ PUSHER EVENTS ############

  pusher_subscribe: (data) ->
    @channels.push(data.channel)
    @adapter.subscribe(this, data.channel)

  pusher_unsubscribe: (data) ->
    delete _.indexOf(@channels, data.channel)
    @adapter.unsubscribe(this, data.channel)