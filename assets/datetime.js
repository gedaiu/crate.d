$(function() {

	console.log($(":input[type=datetime-local]"));

	//fix datetimes with timezones
	$(":input[type=datetime-local]").each(function() {
		
		var dateText = $(this).attr("value");
		var date = new Date(dateText);

		if(dateText.indexOf("Z") > 0 || dateText.indexOf("+") > 0) {

			var m = (date.getMonth() + 1);
			var d = date.getDate();
			var h = date.getHours();
			var i = date.getMinutes();
			var s = date.getSeconds();

			var txt = date.getFullYear() + "-" + ((m < 9) ? "0"+m:m) + "-" + ((d < 9) ? "0"+d:d) + "T" +
					  ((h < 9) ? "0"+h:h) + ":" + ((i < 9) ? "0"+i:i) + ":" + ((s < 9) ? "0"+s:s);

			$(this).attr("value", txt);
		}

		$(this).after('<input type="hidden" name="'+$(this).attr("name")+'[tzOffset]" value="'+date.getTimezoneOffset()+'">');
	});

});