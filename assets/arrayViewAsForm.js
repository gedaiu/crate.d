$(function() {
	initArrayViewAsForm();
});


function initArrayViewAsForm() {
	///select uninitialized lists
	var arrays = $(".arrayViewAsForm:not(.init)");

	//init each list
	arrays.each(function() {
		var currentList = $(this);

		var sample = currentList.children(".sample").html().trim();

		//add before an item
		$(this).on("click", "ol > li > .btn-add", function() {
			$(this).parent().before("<li>" + sample + "</li>");
			updateIndex();

			return false;
		});

		//add at the end of the list
		$(this).find(".footer .btn-add").click(function() {
			currentList.find("ol").append("<li>" + sample + "</li>");
			updateIndex();

			return false;
		});

		//remove an item
		$(this).on("click", "ol > li > .btn-remove", function() {
			
			$(this).parent().remove();
			updateIndex();

			return false;
		});

		//update the _index_ place holder inside each list item
		function updateIndex() {
			var items = currentList.children("ol").children("li");

			items.each(function(index) {
				$(this).find(":input[name]").each(function() {
					var name = $(this).attr("data-name");

					if(name == undefined) {
						name = $(this).attr("name");
						$(this).attr("data-name", name);
					}

					//set the field index
					name = name.replace("[_index_]", "["+index+"]");
					$(this).attr("name", name);
				});
			});

			if(items.length == 0) currentList.addClass("empty");
				else currentList.removeClass("empty");
		};

		updateIndex();
	});
}
