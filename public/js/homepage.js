var totalBackgrounds = 13;
var backgroundIndex = 8;

$(document).ready(function($) {
	console.log("homepage loaded");

	changeBackgroundToIndex(backgroundIndex);
	setupPresentationKeys();
	setupPresentationSprings();
	
	setupSwipeDemo();
});

setupPresentationKeys = function() {
	$("#keys li").each(function(i, val) {
		$(val).click(function() {
			if (i === 0)
				toggleFullscreen();
			else if (i === 1)
				prevBackground();
			else if (i === 2)
				nextBackground();
			else if (i === 3)
				toggleHand();
		});
	});
	
	$(document).keydown(function(e){
		if (e.keyCode === 70) { // 'F'
			$("#fullscreen-key").addClass("active");
		}
		else if (e.keyCode === 187) { // '='
			$("#plus-key").addClass("active");
		}
		else if (e.keyCode === 189) { // '-'
			$("#minus-key").addClass("active");	
		}
		else if (e.keyCode === 72) { // 'H'
			$("#hand-key").addClass("active");
		}
	});
	
	$(document).keyup(function(e){
		if (e.keyCode === 70) { // 'F'
			$("#fullscreen-key").removeClass("active");
			toggleFullscreen();
		}
		else if (e.keyCode === 187) { // '='
			$("#plus-key").removeClass("active");
			nextBackground();
		}
		else if (e.keyCode === 189) { // '-'
			$("#minus-key").removeClass("active");
			prevBackground();
		}
		else if (e.keyCode === 72) { // 'H'
			$("#hand-key").removeClass("active");
			toggleHand();
		}
	});
}

var handVisible = true;
var isFullscreen = false;
var handSpring = springSystem.createSpring();
var fullscreenSpring = springSystem.createSpring();

setupPresentationSprings = function () {
	var hand = $("#screen .hand").get(0);
	handSpring.setSpringConfig(rebound.SpringConfig.fromQcTensionAndFriction(30, 8));
	handSpring.addListener({
	    onSpringUpdate: function (spring) {
	    	var progress = spring.getCurrentValue();
			hand.style['opacity'] = progress;     
		}
	});
	handSpring.setCurrentValue(handVisible);
	
	var phone = $("#screen .phone").get(0);
	var mockup = $("#screen .mockup").get(0);
	var darkening = $("#screen .darkening").get(0);
	fullscreenSpring.setSpringConfig(rebound.SpringConfig.fromQcTensionAndFriction(30, 8));
	fullscreenSpring.addListener({
	    onSpringUpdate: function (spring) {
	    	var progress = spring.getCurrentValue();
	    	var scale = transition(progress, 0.628, 1);
			phone.style['webkitTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			phone.style['MozTransform'] = 'scale3d('+scale+', '+scale+', 1.0)'; 
			hand.style['webkitTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			hand.style['MozTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			mockup.style['webkitTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			mockup.style['MozTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			darkening.style['webkitTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			darkening.style['MozTransform'] = 'scale3d('+scale+', '+scale+', 1.0)';
			darkening.style['opacity'] = progress;
		}
	});
	fullscreenSpring.setCurrentValue(isFullscreen);
}

toggleHand = function() {
	handVisible = !handVisible;
	handSpring.setEndValue(handVisible);
}

toggleFullscreen = function() {
	isFullscreen = !isFullscreen;
	fullscreenSpring.setEndValue(isFullscreen);
}

nextBackground = function() {
	if (backgroundIndex === totalBackgrounds)
		backgroundIndex = 0;
	else
		backgroundIndex++;
	
	changeBackgroundToIndex(backgroundIndex);
}

prevBackground = function() {
	if (backgroundIndex > 0)
		backgroundIndex--;
	else
		backgroundIndex = totalBackgrounds;
		
	changeBackgroundToIndex(backgroundIndex);
}

changeBackgroundToIndex = function(index) {
	$('#screen').css('background-image', 'url(../public/images/backgrounds/' + index + '.jpg)');
}

// Animation for Swipe Demo

var swipeDemoSpring = springSystem.createSpring();
var swipeDemoState = false;

setupSwipeDemo = function () {
	var feed = $("#swipe-feed").get(0);
	var list = $("#swipe-list").get(0);
	var touchpoint = $("#swipe-gesture .touchpoint").get(0);
	var yInlineValue = $("#swipe-y-value").get(0);
	
	swipeDemoSpring.setSpringConfig(rebound.SpringConfig.fromQcTensionAndFriction(10, 6));
	swipeDemoSpring.addListener({
	    onSpringUpdate: function(spring) {
	    	var progress = spring.getCurrentValue();
	    	var yDelta = transition(progress,0,275);
			feed.style['webkitTransform'] = 'translate3d(0,' + yDelta + 'px, 0)';
			feed.style['MozTransform'] = 'translate3d(0,' + yDelta + 'px, 0)';
			
			var yValue = transition(progress,0,-1238);
			yValue = yValue|0;
			yInlineValue.innerHTML = yValue;
			
			var touchPointYOffset = swipeDemoState ? 80 : 0;
			yDelta += touchPointYOffset;
			touchpoint.style['webkitTransform'] = 'translate3d(0,' + yDelta + 'px, 0)';
			touchpoint.style['MozTransform'] = 'translate3d(0,' + yDelta + 'px, 0)';
			
			var listScale = transition(progress,0.98,1);
			list.style['webkitTransform'] = 'scale3d('+listScale+', '+listScale+', 1.0)';
			list.style['MozTransform'] = 'scale3d('+listScale+', '+listScale+', 1.0)';
			
			var touchPointOpacity = swipeDemoState ? progressInRange(progress,0.5,0) : progressInRange(progress,0,0.5);
			touchpoint.style['opacity'] = touchPointOpacity;
		}
	});
	
	flipSwipeDemoState();
	setupCableDragging();
}

setupCableDragging = function() {
	var isDraggingCable = false;
	var downX;
	var downY;
	var cable = $("#progress-cable").get(0);

	$("#progress-hit-area").mousedown(function(e) {
		downX = e.pageX;
		downY = e.pageY;
		console.log("mouse down. x: "+e.pageX+" y: "+e.pageY);
		isDraggingCable = true;
	});
	
	$("#section-gestures").mousemove(function(e) {
		if (isDraggingCable) {
			var deltaX = e.pageX - downX;
			var deltaY = e.pageY - downY;
			var angle = angleForLine(deltaX, deltaY);
			angle = radiansToDegrees(angle);
			length = lengthForLine(deltaX, deltaY);
			cable.style['webkitTransform'] = 'rotate('+angle+'deg) scale3d('+length+', 1.0, 1.0)';
		}
	});
	
	$("#section-gestures").mouseup(function(e) {
		if (isDraggingCable) {
			cable.style['webkitTransform'] = 'scale3d(1.0, 1.0, 1.0)';
			isDraggingCable = false;
		}
	});
	
	$("#section-gestures").mouseleave(function(e) {
		if (isDraggingCable) {
			isDraggingCable = false;
			cable.style['webkitTransform'] = 'scale3d(1.0, 1.0, 1.0)';
		}
	});
}

flipSwipeDemoState = function() {
	swipeDemoState = !swipeDemoState;
	var endValue = swipeDemoState ? 1.0 : 0.0;
	swipeDemoSpring.setEndValue(endValue);
	
	var delay = swipeDemoState ? 1100 : 1700;
	setTimeout(flipSwipeDemoState,delay);
}