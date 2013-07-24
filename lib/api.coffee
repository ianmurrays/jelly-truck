express = require('express')

module.exports = class APIServer
  constructor: (@adapter, @port = 4567) ->
    console.log "Initializing API Server at 0.0.0.0:#{@port}"
    @api = express()
    @api.listen(@port)

    @_bindMethods()

  _bindMethods: ->
    @api.get '/', (req, res) -> 
      res.sendfile(__dirname + '/index.html')

    @api.get '/pusher.js', (req, res) -> 
      res.sendfile(__dirname + '/pusher-2.1.js')

    # Event triggering api 
    @api.post "/apps/#{@adapter.appId}/events", (req, res) =>
      # Just post whatever to test
      @adapter.triggerEvent "testevent", "testchannel", {message: "hola"}
      res.send(200)
