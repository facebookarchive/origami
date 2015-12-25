// %@ transition

var %@Spring = springSystem
  .createSpringWithBouncinessAndSpeed(%@, %@)
  .addListener({
    onSpringUpdate: function(spring) {
      set%@Progress(spring.getCurrentValue());
    }
  });

var %@ = function(on) {
  %@Spring.setEndValue(on ? 1 : 0);
};