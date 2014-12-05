/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 5, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.datetime;


import crated.view.base;

class ViewSysTime : ViewType {



	override string asForm(bool isRequired = false) {

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		string value = opDispatch!"value";

		if(isRequired) {
			return "<div class='input-group'>
			               <input class='form-control "~cls~"' id='"~id~"' type='datetime-local' name='"~name~"' value='"~value~"' required>
			               <span class='input-group-addon'>
	                             <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
	                       </span>
			        </div>";
		} else {
			return "<input class='form-control "~cls~"' id='"~id~"' type='datetime-local' name='"~name~"' value='"~value~"'>";
		}
	}

}
