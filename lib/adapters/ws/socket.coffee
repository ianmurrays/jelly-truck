_              = require "underscore"
{EventEmitter} = require "events"
rbytes         = require "rbytes"

module.exports = class Socket extends EventEmitter
  constructor: (@adapter, @socket) ->
    @channels = []

    # Holds user info for each presence channel
    @channelsInfo = {}

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
      
      # Call this first so we can trigger all events
      @adapter.unsubscribe(this, {channel: channel})

      index = _.indexOf(@channels, channel)
      @channels.splice(index, 1) unless index == -1
      delete @channelsInfo[channel]
      
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

  updateChannelInfo: (channel, data) -> 
    @channelsInfo[channel] = JSON.parse(data) if data

  ############ PUSHER EVENTS ############

  pusher_subscribe: (data) ->
    if @validateChannelName(data.channel)
      @updateChannelInfo(data.channel, data.channel_data)

      [result, error] = @adapter.subscribe(this, data) # This could fail due to invalid auth signature
      if result
        @channels.push(data.channel)
  
        @triggerEvent "pusher_internal:subscription_succeeded", data.channel, @adapter.channelInfo(data.channel, this)

        console.log "  [#{@socketId}] Subscribed to channel #{data.channel}"
      else
        delete @channelsInfo[channel]
        @sendError null, error
        console.log "  [#{@socketId}] #{error}"
    else
      @sendError null, "Invalid channel name '#{data.channel}'"

  pusher_unsubscribe: (data) ->
    index = _.indexOf(@channels, data.channel)

    if index != -1
      @channels.splice(index, 1)
      delete @channelsInfo[data.channel]
      @adapter.unsubscribe(this, data)

      console.log "  [#{@socketId}] Unsubscribed from channel #{data.channel}"
    else
      @sendError null, "No current subscription to channel #{data.channel}, or subscription in progress"

