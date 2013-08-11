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
    # Event triggering api 
    @api.post "/apps/#{@adapter.appId}/events", (req, res) =>
      # Check authentication signature
      signature     = req.query.auth_signature
      authKey       = req.query.auth_key
      authTimestamp = req.query.auth_timestamp
      authVersion   = req.query.auth_version
      bodyMD5       = req.query.body_md5

      if authKey != @adapter.appKey
        return res.send(401) 

      # NOT CALCULATING MD5 UNTIL WE FIND A SIMPLE WAY TO GET
      # THE RAW BODY 
      #  
      # # Calculate the actual body md5
      # md5Signer     = crypto.createHash 'md5'
      # actualBodyMD5 = md5Signer.update(req.rawBody).digest('hex')

      # if bodyMD5 != actualBodyMD5
      #   return res.send(401) 

      # Generate our own signature and check
      stringToSign =  "POST"
      stringToSign += "\n/apps/#{@adapter.appId}/events"
      stringToSign += "\nauth_key=#{authKey}"
      stringToSign += "&auth_timestamp=#{authTimestamp}"
      stringToSign += "&auth_version=#{authVersion}"
      stringToSign += "&body_md5=#{bodyMD5}"

      signer = crypto.createHmac 'sha256', @adapter.appSecret
      result = signer.update(stringToSign).digest('hex')

      if result != signature
        return res.send(401, "Invalid signature: Expected HMAC SHA256 hex digest of #{stringToSign}, but got #{signature}")

      # Trigger the event, signature is good
      if req.body.channel
        req.body.channels = [req.body.channel]

      try
        parsedData = JSON.parse(req.body.data)
      catch e
        res.send(400, "Invalid JSON in data parameter: #{req.body.data}")
        return
      
      for channel in req.body.channels
        @adapter.triggerEvent req.body.name, channel, parsedData

      console.log "  [API] Received event #{req.rawBody}"
      
      res.send(200)

    # -------------------------------- TEST METHODS --------------------------------

    @api.get '/', (req, res) -> 
      res.sendfile(__dirname + '/index.html')

    @api.get '/test', (req, res) -> 
      res.sendfile(__dirname + '/test-pusher.html')

    @api.get '/pusher.js', (req, res) -> 
      res.sendfile(__dirname + '/pusher-2.1.js')

    @api.post "/pusher_auth_test", (req, res) =>
      socketId    = req.body.socket_id
      channelName = req.body.channel_name

      signer = crypto.createHmac 'sha256', @adapter.appSecret
      result = signer.update("#{socketId}:#{channelName}").digest('hex')

      res.json(auth: "#{@adapter.appKey}:#{result}")

    @api.post "/pusher_auth_test_presence", (req, res) =>
      socketId    = req.body.socket_id
      channelName = req.body.channel_name
      channelData = JSON.stringify
        user_id: Date.now()
        user_info:
          name: "John Doe"

      signer = crypto.createHmac 'sha256', @adapter.appSecret
      # signer = crypto.createHmac 'sha256', "00d1561e00b340cdbe40" # @adapter.appSecret
      result = signer.update("#{socketId}:#{channelName}:#{channelData}").digest('hex')

      res.json(auth: "#{@adapter.appKey}:#{result}", channel_data: channelData)
      # res.json(auth: "f97381306669f7ca9ab7:#{result}", channel_data: channelData)

    @api.post "/pusher_auth_test_presence_for_pusher", (req, res) =>
      socketId    = req.body.socket_id
      channelName = req.body.channel_name
      channelData = JSON.stringify
        user_id: Date.now()
        user_info:
          name: "John Doe"

      # signer = crypto.createHmac 'sha256', @adapter.appSecret
      signer = crypto.createHmac 'sha256', "00d1561e00b340cdbe40" # @adapter.appSecret
      result = signer.update("#{socketId}:#{channelName}:#{channelData}").digest('hex')

      # res.json(auth: "#{@adapter.appKey}:#{result}", channel_data: channelData)
      res.json(auth: "f97381306669f7ca9ab7:#{result}", channel_data: channelData)
