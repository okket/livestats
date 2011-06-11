var LiveStats, faye, http, nodeStatic, sys, url;
http = require('http');
sys = require('sys');
nodeStatic = require('node-static');
faye = require('faye');
url = require('url');
LiveStats = function(options) {
  var self;
  if (!this instanceof arguments.callee) {
    return new arguments.callee(arguments);
  }
  self = this;
  self.settings = {
    port: options.port,
    geoipServer: {
      hostname: options.geoipServer.hostname,
      port: options.geoipServer.port || 80
    }
  };
  return self.init();
};
LiveStats.prototype.init = function() {
  var self;
  self = this;
  self.bayeux = self.createBayeuxServer();
  self.httpServer = self.createHTTPServer();
  self.bayeux.attach(self.httpServer);
  self.httpServer.listen(self.settings.port);
  return sys.log('Server started on PORT ' + self.settings.port);
};
LiveStats.prototype.createBayeuxServer = function() {
  var bayeux, self;
  self = this;
  return bayeux = new faye.NodeAdapter({
    mount: '/faye',
    timeout: 45
  });
};
LiveStats.prototype.createHTTPServer = function() {
  var self, server;
  self = this;
  return server = http.createServer(function(request, response) {
    var file;
    file = new nodeStatic.Server('./public', {
      cache: false
    });
    return request.addListener('end', function() {
      var jsonString, location, params;
      location = url.parse(request.url, true);
      params = location.query || request.headers;
      if (location.pathname === '/config.json' && request.method === 'GET') {
        response.writeHead(200, {
          'Content-Type': 'application/x-javascript'
        });
        jsonString = JSON.stringify({
          port: self.settings.port
        });
        response.write(jsonString);
        return response.end();
      } else if (location.pathname === '/stat' && request.method === 'GET') {
        self.ipToPosition(params.ip, function(latitude, longitude, city) {
          return self.bayeux.getClient().publish('/stat', {
            title: params.title,
            latitude: latitude,
            longitude: longitude,
            city: city,
            ip: params.ip
          });
        });
        response.writeHead('200', {
          'content-Type': 'text/plain'
        });
        response.write('OK');
        return response.end();
      } else {
        return file.serve(request, response);
      }
    });
  });
};
LiveStats.prototype.ipToPosition = function(ip, callback) {
  var client, request, self;
  self = this;
  client = http.createClient(self.settings.geoipServer.port, self.settings.geoipServer.hostname);
  console.log('ip: ' + ip);
  request = client.request('GET', '/geoip/api/locate.json?ip=' + ip, {
    'host': self.settings.geoipServer.hostname
  });
  return request.addListener('response', function(response) {
    var body;
    response.setEncoding('utf8');
    body = '';
    response.addListener('data', function(chunk) {
      return body += chunk;
    });
    return response.addListener('end', function() {
      var json;
      json = JSON.parse(body);
      if (json.latitude && json.longitude) {
        return callback(json.latitude, json.longitude, json.city);
      }
    });
  });
};
module.exports = LiveStats;