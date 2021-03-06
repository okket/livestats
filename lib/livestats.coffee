http       = require 'http'
sys        = require 'sys'
nodeStatic = require 'node-static'
faye       = require 'faye'
url        = require 'url'

LiveStats = (options) ->
  return new arguments.callee arguments if ! this instanceof arguments.callee

  self = @

  self.settings =
    port: options.port
    geoipServer: 
        hostname: options.geoipServer.hostname
        port:     options.geoipServer.port or 80

  self.init()

LiveStats::init = ->
  self = @
  self.bayeux = self.createBayeuxServer()
  self.httpServer = self.createHTTPServer()
  self.bayeux.attach self.httpServer
  self.httpServer.listen self.settings.port
  sys.log 'Server started on PORT ' + self.settings.port

LiveStats::createBayeuxServer = ->
  self = @
  bayeux = new faye.NodeAdapter mount: '/faye', timeout: 45

LiveStats::createHTTPServer = ->
  self = @
  server = http.createServer (request, response) ->
    file = new nodeStatic.Server './public', cache: false
    request.on 'end', ->
      location = url.parse request.url, true
      params   = location.query or request.headers
      if location.pathname is '/config.json' and request.method is 'GET'
        response.writeHead(200, 'Content-Type': 'application/x-javascript')
        jsonString = JSON.stringify port: self.settings.port
        response.write jsonString
        response.end()
      else if location.pathname is '/stat' and request.method is 'GET'
        self.ipToPosition params.ip, (latitude, longitude, city) ->
          self.bayeux.getClient().publish '/stat',
            title: params.title,
            latitude: latitude,
            longitude: longitude,
            city: city,
            ip: params.ip
        response.writeHead '200', 'content-Type': 'text/plain'
        response.write 'OK'
        response.end()
      else
        file.serve request, response

LiveStats::ipToPosition = (ip, callback) ->
  self = @

  options = 
    host: self.settings.geoipServer.hostname
    port: self.settings.geoipServer.port
    path: '/geoip/api/locate.json?ip=' + ip

  request = http.get options, (response) ->
    response.setEncoding 'utf8'
    body = ''
    response.on 'data', (chunk) ->
      body += chunk
    response.on 'end', ->
      json = JSON.parse body
      if json.latitude and json.longitude
        callback json.latitude, json.longitude, json.city

  request.end()

module.exports = LiveStats