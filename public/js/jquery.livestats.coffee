LiveStatsClient = -> 
  return new arguments.callee arguments if ! this instanceof arguments.callee
  
  self = @
  
  @.init = ->
    self.setupBayeuxHandler()

  @.setupBayeuxHandler = ->
    self.client = new Faye.Client 'http://127.0.0.1:8000/faye', timeout: 120
    self.client.subscribe '/stat', (message) ->
      console.log 'MESSAGE', message

  @.init()

jQuery -> 
  liveStatsClient = new LiveStatsClient()
  