$(function() {

	$(".menuButton").on("click touchstart", function() {
		
		$("body").toggleClass("showMenu");

		return false;
	});

});