_               = require "underscore"
{EventEmitter}  = require "events"
WebSocket       = require("ws")
WebSocketServer = require("ws").Server
Socket          = require "./socket"

module.exports = class WSAdapter extends EventEmitter
  log: (message) ->
    return unless @debugging
    console.log message

  constructor: (@port = 8080, @debugging = on) ->
    @channels = {}
    @wss = new WebSocketServer(port: @port)

    # Bind all event methods to this
    _.bindAll this, 'onConnect'
    
    @configure()

  configure: () -> @wss.on 'connection', @onConnect

  triggerEvent: (event, channel, data) ->
    return unless @channels[channel]
    for subscriber in @channels[channel]
      subscriber.write
        event: event
        channel: channel
        data: data
      
  subscribe: (subscriber, channel) ->
    @channels[channel] ||= []

    # Don't add subscriber if already there
    if _.indexOf(@channels, subscriber) == -1
      @channels[channel].push subscriber

  unsubscribe: (subscriber, channel) ->
    return unless @channels[channel]

    index = _.indexOf(@channels[channel], subscriber)

    return unless index != -1

    @channels[channel].splice(index, 1)

  ############### Event Handlers ###############

  onConnect: (ws) ->
    socket = new Socket(this, ws)
    @emit "adapter:connected", socket
    