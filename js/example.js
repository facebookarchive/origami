var example1 = function() {
  var springSystem = new SpringSystem();
  var spring = createSpring(springSystem, 37, 6);
  var springConfig = spring.getSpringConfig();
  var photo = document.getElementById('example-photo');
  spring.addListener({
    el: null,
    onSpringUpdate: function(spring) {
      this.el = this.el || photo;
      var val = spring.getCurrentValue();
      val = mapValueFromRangeToRange(val, 0, -1, 1, 0.6);
      scale(this.el, val);
    }
  });

  var scalingExample = document.getElementById('scaling-example');
	
  var time = 0;
  var zoomed = false;

  photo.addEventListener(downEvt, function() {
	document.getElementById('example-photo').style.opacity = (zoomed ? '1' : '0.7');
    spring.setEndValue(zoomed ? 0 : -1);
    zoomed = !zoomed;
  });

}

document.addEventListener('DOMContentLoaded', example1);
