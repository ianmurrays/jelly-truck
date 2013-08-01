_               = require "underscore"
{EventEmitter}  = require "events"
WebSocket       = require("ws")
WebSocketServer = require("ws").Server
Socket          = require "./socket"
crypto          = require "crypto"

module.exports = class WSAdapter extends EventEmitter
  constructor: (@port = 8080, @appKey, @appSecret) ->
    @channels = {}
    @wss = new WebSocketServer(port: @port)

    # Bind all event methods to this
    _.bindAll this, 'onConnect'
    
    @configure()

  configure: () -> @wss.on 'connection', @onConnect

  triggerEvent: (event, channel, data) ->
    return unless @channels[channel]
    for subscriber in @channels[channel]
      subscriber.triggerEvent event, channel, data

  # Returns true if subscription succeeded, false if signature was invalid        
  subscribe: (subscriber, data) ->
    if data.channel.match /^private\-/i
      # Validate the signature
      validation = @validatePrivateChannelSignature(subscriber.socketId, data.channel, data.auth)

      return validation unless validation[0] # If validation[0] is false, signature is wrong
        
    @channels[data.channel] ||= []

    # Don't add subscriber if already there
    if _.indexOf(@channels, subscriber) == -1
      @channels[data.channel].push subscriber

    return [true, null]

  unsubscribe: (subscriber, data) ->
    return unless @channels[data.channel]

    index = _.indexOf(@channels[data.channel], subscriber)

    return unless index != -1

    @channels[data.channel].splice(index, 1)

  # Returns [bool, errorMessage]
  validatePrivateChannelSignature: (socketId, channel, authString) ->
    [appKey, signature] = authString.split(":")

    if appKey != @appKey
      return [false, "Invalid key '#{appKey}"]
    else
      # Calculate the signature ourselves
      signer = crypto.createHmac 'sha256', @appSecret
      result = signer.update("#{socketId}:#{channel}").digest('hex')

      if signature != result
        return [false, "Invalid signature: Expected HMAC SHA256 hex digest of #{socketId}:#{channel}, but got #{signature}"]

    return [true, null]

  ############### Event Handlers ###############

  onConnect: (ws) ->
    socket = new Socket(this, ws)
    @emit "adapter:connected", socket
    