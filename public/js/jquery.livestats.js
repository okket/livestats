var LiveStatsClient;
LiveStatsClient = function() {
  var self;
  if (!this instanceof arguments.callee) {
    return new arguments.callee(arguments);
  }
  self = this;
  this.init = function() {
    return self.setupBayeuxHandler();
  };
  this.setupBayeuxHandler = function() {
    self.client = new Faye.Client('http://127.0.0.1:8000/faye', {
      timeout: 120
    });
    return self.client.subscribe('/stat', function(message) {
      return console.log('MESSAGE', message);
    });
  };
  return this.init();
};
jQuery(function() {
  var liveStatsClient;
  return liveStatsClient = new LiveStatsClient();
});