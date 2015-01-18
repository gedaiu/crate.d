$(function() {
	initArrayViewAsForm();
});


function initArrayViewAsForm() {
	///select uninitialized lists
	var arrays = $(".arrayViewAsForm:not(.init)");

	//init each list
	arrays.each(function() {
		var currentList = $(this).addClass("init");

		initArrayForm(currentList, updateIndex);

		//update the _index_ place holder inside each list item
		function updateIndex(index, item) {
			return index;
		};

		updateIndex();
	});
}
