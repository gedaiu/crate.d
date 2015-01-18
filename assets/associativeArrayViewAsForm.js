$(function() {
	initAssociativeArrayViewAsForm();
});

function initAssociativeArrayViewAsForm() {
	///select uninitialized lists
	var arrays = $(".associativeArrayViewAsForm:not(.init)");

	//init each list
	arrays.each(function() {
		var currentList = $(this).addClass("init");

		initArrayForm(currentList, updateIndex);

		//update the _index_ place holder inside each list item
		function updateIndex(index, item) {
			return $(item).children(".key").find(":input.arrayKeyField").val();
		};

		updateIndex();
	});
}
