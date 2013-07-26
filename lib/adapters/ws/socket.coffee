_              = require "underscore"
{EventEmitter} = require "events"
rbytes         = require "rbytes"

module.exports = class Socket extends EventEmitter
  constructor: (@adapter, @socket) ->
    @channels = []
    @socketId = rbytes.randomBytes(16).toHex()

    _.bindAll this, 'onMessage', 'onClose', 'write'

    @socket.on 'message', @onMessage
    @socket.on 'close', @onClose

  onMessage: (message) ->
    try
      message = JSON.parse(message)
    catch e
      console.log e

    console.log "> [#{@socketId}] #{JSON.stringify(message)}"

    # Call the method with the same name as the event
    message.event = message.event.replace /^pusher:/, "pusher_"
    this[message.event](message.data)

  onClose: () ->
    console.log "  [#{@socketId}] Connection closed"
    for channel in @channels
      console.log "  [#{@socketId}] Removing subscription from #{channel}"
      delete _.indexOf(@channels, channel)
      @adapter.unsubscribe(this, channel)
      
  # Public: writes an object as stringified JSON
  write: (object) ->
    json = JSON.stringify(object)
    console.log "< [#{@socketId}] #{json}"
    @socket.send(json)

  sendError: (code, message) ->
    @write 
      event: "pusher:error"
      data:
        code: code
        message: message

  triggerEvent: (event, channel, data) ->
    @write
      event: event
      channel: channel
      data: data

  validateChannelName: (name) -> name.match(/^[a-z0-9\_\-\=\@\,\.\;]+$/i) != null

  ############ PUSHER EVENTS ############

  pusher_subscribe: (data) ->
    if @validateChannelName(data.channel)
      @channels.push(data.channel)
      @adapter.subscribe(this, data.channel)

      @triggerEvent "pusher_internal:subscription_succeeded", data.channel, {}

      console.log "  [#{@socketId}] Subscribed to channel #{data.channel}"
    else
      @sendError null, "Invalid channel name '#{data.channel}'"

  pusher_unsubscribe: (data) ->
    index = _.indexOf(@channels, data.channel)

    if index != -1
      @channels.splice(index, 1)
      @adapter.unsubscribe(this, data.channel)

      console.log "  [#{@socketId}] Unsubscribed from channel #{data.channel}"
    else
      @sendError null, "No current subscription to channel #{data.channel}, or subscription in progress"

