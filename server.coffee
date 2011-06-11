process.addListener 'uncaughtException', (err, stack) ->
  console.log '---------------------------'
  console.log 'Exception: ' + err
  console.log err.stack
  console.log '---------------------------'

LiveStats  = require './lib/livestats'

new LiveStats
  port: 8000
  geoipServer:
      hostname: 'geoip.peepcode.com'
      port: 80
