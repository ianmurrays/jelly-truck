express = require('express')
crypto  = require('crypto')

module.exports = class APIServer
  constructor: (@adapter, @port = 4567) ->
    console.log "Initializing API Server at 0.0.0.0:#{@port}"
    @api = express()
    @api.listen(@port)
    @api.use(express.bodyParser())

    @_bindMethods()

  _bindMethods: ->
    @api.get '/', (req, res) -> 
      res.sendfile(__dirname + '/index.html')

    @api.get '/pusher.js', (req, res) -> 
      res.sendfile(__dirname + '/pusher-2.1.js')

    # Event triggering api 
    # console.log "/apps/#{@adapter.appId}/events"
    @api.post "/apps/#{@adapter.appId}/events", (req, res) =>
      # Just post whatever to test
      @adapter.triggerEvent "female", "login.adult", {message: "hola"}
      res.send(200)

    @api.post "/pusher_auth_test", (req, res) =>
      socketId    = req.body.socket_id
      channelName = req.body.channel_name

      signer = crypto.createHmac 'sha256', @adapter.appSecret
      result = signer.update("#{socketId}:#{channelName}").digest('hex')

      res.json(auth: "#{@adapter.appKey}:#{result}")
