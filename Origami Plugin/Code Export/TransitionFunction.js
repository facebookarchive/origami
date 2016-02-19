var transition = function(progress, startValue, endValue) {
  return rebound.MathUtil.mapValueInRange(progress, 0, 1, startValue, endValue);
};