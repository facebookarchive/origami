var springSystem = new rebound.SpringSystem();

// Utilities

transition = function(progress, startValue, endValue) {
	return startValue + (progress * (endValue - startValue));
}

progressInRange = function(value, startValue, endValue) {
	return (value - startValue) / (endValue - startValue);
}

radiansToDegrees = function(radians) {
	return radians * (180/Math.PI);
}

angleForLine = function(deltaX, deltaY) {
	return Math.atan2(deltaY, deltaX);
}

lengthForLine = function(deltaX, deltaY) {
	return Math.sqrt(Math.pow(deltaX,2) + Math.pow(deltaY,2));
}