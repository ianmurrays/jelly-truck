WSAdapter  = require './adapters/ws/ws'
_          = require 'underscore'
needle     = require 'needle'
crypto     = require "crypto"

module.exports = class Sockets
  constructor: (port = 8080, adapter, @appId, @appKey, @appSecret, @webhook) ->
    console.log "Initializing Websockets Server at 0.0.0.0:#{port}"
    @wss = new adapter(@port, @appKey, @appSecret)

    _.bindAll this, 'onConnect', 'onChannelVacated', 'onChannelOccupied'

    @wss.on 'adapter:connected',        @onConnect
    @wss.on 'adapter:channel_occupied', @onChannelOccupied
    @wss.on 'adapter:channel_vacated',  @onChannelVacated
    # @wss.on 'adapter:member_added',     @onMemberAdded
    # @wss.on 'adapter:member_removed',   @onMemberRemoved

  onConnect: (socket) ->
    console.log "  [#{socket.socketId}] Socket connection established"
    socket.write 
      event: "pusher:connection_established"
      data:
        socket_id: socket.socketId

  triggerEvent: (event, channel, data) -> @wss.triggerEvent(event, channel, data)

  _generateSecurityHeaders: (body) ->
    signer = crypto.createHmac 'sha256', @appSecret
    result = signer.update(body).digest('hex')

    options = 
      headers:
        "X-Pusher-Key": @appKey
        "X-Pusher-Signature": result
        "Content-Type": "application/json"

    return options

  _postWebHook: (event) ->
    return unless @webhook

    body = 
      time_ms: Date.now()
      events: [event]

    body = JSON.stringify(body)

    needle.post @webhook, body, @_generateSecurityHeaders(body), (err, resp, respBody) => 
      if err
        console.log "  [WebHook #{@webhook}] #{err} (#{body})"
      else
        console.log "  [WebHook #{@webhook}] #{body}"

  onChannelOccupied: (channel) ->
    @_postWebHook
      name: "channel_occupied"
      channel: channel

  onChannelVacated: (channel) ->
    @_postWebHook
      name: "channel_vacated"
      channel: channel
