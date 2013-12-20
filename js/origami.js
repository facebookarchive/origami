window.onscroll = function() {
	
	if (window.scrollY > 1280) {
		document.getElementById('get-started-drawer').style.bottom = '-410px';
	} else {
		document.getElementById('get-started-drawer').style.bottom = '';
	}
	
}