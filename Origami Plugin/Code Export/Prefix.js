var springSystem = new rebound.SpringSystem();

springSystem.addListener({
  onAfterIntegrate: function(springSystem) {
    updateLayers();
  }
});