var springSystem = new rebound.SpringSystem();

// Utilities

transition = function(progress, startValue, endValue) {
	return startValue + (progress * (endValue - startValue));
}

progressInRange = function(value, startValue, endValue) {
	return (value - startValue) / (endValue - startValue);
}

clampedProgress = function(progress) {
	if (progress < 0)
		progress = 0;
	else if (progress > 1)
		progress = 1;
		
	return progress;
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