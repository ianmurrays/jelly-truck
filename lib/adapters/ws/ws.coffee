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
      validation = @validatePrivateChannelSignature(subscriber.socketId, data)

      return validation unless validation[0] # If validation[0] is false, signature is wrong
    else if data.channel.match /^presence\-/i
      validation = @validatePresenceChannelSignature(subscriber.socketId, data)

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

  _userIdAlreadyPresent: (channel, user_id, socket) ->
    for subscriber in @channels[channel]
      if subscriber.socketId != socket.socketId && subscriber.channelsInfo[channel]["user_id"] == user_id
        return yes

    return no

  channelInfo: (channel, socket) ->
    if channel.match /^presence\-/i
      # Fetch all members info
      info = 
        count: 0
        ids: []
        hash: {}

      for subscriber in @channels[channel]
        # Skip duplicate connections if same user.
        if subscriber.socketId != socket.socketId && @_userIdAlreadyPresent(channel, subscriber.channelsInfo[channel]["user_id"], subscriber) 
          continue

        info.count += 1
        info.ids.push subscriber.channelsInfo[channel]["user_id"]
        info.hash[subscriber.channelsInfo[channel]["user_id"]] = subscriber.channelsInfo[channel]["user_info"]

      return {presence: info}
    else
      return {}

  _validateSignature: (socketId, data, presence = no) ->
    channel     = data.channel
    authString  = data.auth
    channelData = data.channel_data

    try
      parsedChannelData = JSON.parse(channelData)
    catch e
      return [false, "channel_data is not valid encoded JSON"]

    signatureString = if presence then "#{socketId}:#{channel}:#{channelData}" else "#{socketId}:#{channel}"

    [appKey, signature] = authString.split(":")

    if appKey != @appKey
      return [false, "Invalid key '#{appKey}"]
    else if presence && ! parsedChannelData["user_id"]
      return [false, "channel_data must include a user_id when subscribing to presence channels (#{channel})"]
    else
      # Calculate the signature ourselves
      signer = crypto.createHmac 'sha256', @appSecret
      result = signer.update(signatureString).digest('hex')

      if signature != result
        return [false, "Invalid signature: Expected HMAC SHA256 hex digest of #{signatureString}, but got #{signature}"]

    return [true, null]

  # Returns [bool, errorMessage]
  validatePrivateChannelSignature: (socketId, data) -> @_validateSignature(socketId, data)

  # Returns [bool, errorMessage]
  validatePresenceChannelSignature: (socketId, data) -> @_validateSignature(socketId, data, yes)

  ############### Event Handlers ###############

  onConnect: (ws) ->
    socket = new Socket(this, ws)
    @emit "adapter:connected", socket
    