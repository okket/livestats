LiveStatsClient = -> 
  return new arguments.callee arguments if ! this instanceof arguments.callee

  self = @

  @.init = ->
    self.drawMap()
    self.viewDidResize()
    self.setupBayeuxHandler()
    return @

  @.setupBayeuxHandler = ->
    self = @
    $.getJSON "/config.json", (config) ->
      self.client = new Faye.Client 'http://' + window.location.hostname + ':' + config.port + '/faye', timeout: 120
      self.client.subscribe '/stat', (message) ->
        self.drawMarker message

  @.viewDidResize = ->
    self = @
    width = $('body').width()
    windowHeight = $(window).height()
    mapCanvasHeight = width * (369.0 / 567.0)
    self.map.setSize width, mapCanvasHeight
    $('#map').css
      'margin-top': (windowHeight - mapCanvasHeight) / 2.0

  @.drawMap = ->
    self = @
    self.map = Raphael 'map', 0, 0 
    self.map.canvas.setAttribute 'viewBox', '0 0 567 369'

    self.map.path(mapPath).attr(
      stroke: 'black'
      fill: '#222'
    ).attr(
      'stroke-width': 0.7
    )

  @.geoCoordsToMapCoords = (latitude, longitude) ->
    latitude = parseFloat latitude
    longitude = parseFloat longitude

    mapWidth = 567
    mapHeight = 369

    x = (mapWidth * (180 + longitude) / 360) % mapWidth

    latitude = latitude * Math.PI / 180
    y = Math.log(Math.tan((latitude / 2) + (Math.PI / 4)))
    y = (mapHeight / 2) - (mapWidth * y / (2 * Math.PI))

    mapOffsetX = mapWidth * 0.026
    mapOffsetY = mapHeight * 0.141

    return {
      x: (x - mapOffsetX) * 0.97
      y: (y + mapOffsetY + 15)
      xRaw: x
      yRaw: y
    }

  @.drawMarker = (message) ->
    self = @
    latitude = message.latitude
    longitude = message.longitude
    text = message.title
    city = message.city

    mapCoords = @.geoCoordsToMapCoords latitude, longitude
    x = mapCoords.x
    y = mapCoords.y

    person = self.map.path personPath
    person.scale 0.01, 0.01
    person.translate -255, -255 # Reset location to 0,0
    person.translate x, y 
    person.attr 
      fill: '#ff9',
      stroke: 'transparent'

    title = self.map.text x, y + 11, text
    title.attr
      fill: 'white',
      "font-size": 10,
      "font-family": "'Helvetica Neue', 'Helvetica', sans-serif",
      'font-weight': 'bold'
    subtitle = self.map.text x, y + 21, city
    subtitle.attr
      fill: '#999',
      "font-size": 7,
      "font-family": "'Helvetica Neue', 'Helvetica', sans-serif"

    hoverFunc = ->
      person.attr
        fill: 'white'
      $(title.node).fadeIn 'fast'
      $(subtitle.node).fadeIn 'fast'

    hideFunc = ->
      person.attr
        fill: '#ff9'
      $(title.node).fadeOut 'slow'
      $(subtitle.node).fadeOut 'slow'

    $(person.node).hover hoverFunc, hideFunc

    person.animate
      scale: '0.02, 0.02'
      2000, 'elastic', ->
        $(title.node).fadeOut 5000
        $(subtitle.node).fadeOut 5000

  @.init()

jQuery -> 
  liveStatsClient = new LiveStatsClient()
  $(window).resize ->
    liveStatsClient.viewDidResize()
