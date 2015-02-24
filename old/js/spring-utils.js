(function() {
  window.createSpring = function createSpring(springSystem, friction, tension, rawValues) {
    var spring = springSystem.createSpring();
    var springConfig;
    if (rawValues) {
      springConfig = new SpringConfig(friction, tension);
    } else {
      springConfig = SpringConfig.fromQcTensionAndFriction(friction, tension);
    }
    spring.setSpringConfig(springConfig);
    spring.setCurrentValue(0);
    return spring;
  }

  window.xlat = function xlat(el, x, y) {
    el.style.mozTransform =
    el.style.msTransform =
    el.style.webkitTransform =
    el.style.transform = 'translate3d(' + x + 'px, ' + y + 'px, 0px)';
  }

  window.scale = function scale(el, val) {
    el.style.mozTransform =
    el.style.msTransform =
    el.style.webkitTransform =
    el.style.transform = 'scale3d(' + val + ', ' + val + ', 1)';
  }

  window.mapValueFromRangeToRange = function(value, fromLow, fromHigh, toLow, toHigh) {
    fromRangeSize = fromHigh - fromLow;
    toRangeSize = toHigh - toLow;
    valueScale = (value - fromLow) / fromRangeSize;
    return toLow + (valueScale * toRangeSize);
  }
	
  window.downEvt = window.ontouchstart !== undefined ? 'touchstart' : 'mousedown';
  window.upEvt = window.ontouchend !== undefined ? 'touchend' : 'mouseup';
})();

