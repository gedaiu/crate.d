// the default implementation for the array forms
function initArrayForm(currentList, updateIndexCallback) {

	var sample = currentList.children(".sample").html().trim();
	var self = this;

	//add at the end of the list
	currentList.children(".footer").find(".btn-add").click(function() {
		addItem.apply(self);
		return false;
	});

	//attach initial handlers
	initItemHandler(currentList.children("ol").children("li"));

	//add an item in list
	function addItem(item) {
		var li = $("<li>" + sample + "</li>");

		if(item) item.parent().parent().before(li);
			else currentList.children("ol").append(li);

		initItemHandler(li);

		try {
			updateIndex();
		} catch(err) {
			console.log(err);
		}
	}

	//add function handlers
	function initItemHandler(li) {
		//add item before
		li.children(".head").on("click", ".btn-add", function() {
			addItem($(this));

			return false;
		});

		//remove the item
		li.children(".head").on("click", ".btn-remove", function() {
			
			$(this).parent().parent().remove();
			updateIndex();

			return false;
		});

		//attach key value handker
		currentList.find(":input.arrayKeyField").on("change", function() {
			updateIndex();	
		});

		//add get index function for the item list DOM node
		li.each(function() {
			this.getIndex = function() {
				return updateIndexCallback($(this).index(), this);
			}
		});

		//add updateKey method for all inputs that can be found in the item
		li.find(":input[name]").each(function() {
			this.updateKey = function() {
				var key = getItemLevelIndexes(this);

				var name = $(this).attr("data-name");
				var nameAttr = $(this).attr("name");

				if(nameAttr == "") return;

				if(name == undefined) {
					name = $(this).attr("name");
					$(this).attr("data-name", name);
				}

				name = name.split("_index_");

				//set the field index
				for(var i = 0; i<key.length; i++) {
					name.splice(i+1, 0, key[i]);
				}

				$(this).attr("name", name.join(""));
			}
		});
	}


	function getItemLevelIndexes(item) {
		var key = [];

		item = $(item).closest("li");

		do {
			if(item[0].getIndex)
				key.push(item[0].getIndex());

			item = $(item).parent().closest("li");
		} while(item.length > 0);
			
		return key.reverse();
	}

	//update the input indexes from the name attribute
	function updateIndex() {
		
		var items = currentList.children("ol").children("li");

		items.each(function(i) {
			//set the index
			$(this).find(":input[name]").each(function() {
				this.updateKey();
			});
		});

		if(items.length == 0) currentList.addClass("empty");
			else currentList.removeClass("empty");

		//check if we have lists inside
		var aaLists = currentList.children("ol").find(".associativeArrayViewAsForm:not(.init)").length;
		var siLists = currentList.children("ol").find(".arrayViewAsForm:not(.init)").length;

		if(aaLists > 0) initAssociativeArrayViewAsForm();
		if(siLists > 0) initArrayViewAsForm();
	}


	setTimeout(function() { updateIndex(); } , 10);
}
