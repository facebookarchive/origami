var springSystem = new rebound.SpringSystem();

// Utilities

transition = function(progress, startValue, endValue) {
	return startValue + (progress * (endValue - startValue));
}