/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 5, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.datetime;

import core.time;
import std.datetime;
import std.conv;
import std.array;
import crated.view.base;

class ViewSysTime : ViewType {

	override string asForm(bool isRequired = false) {

		container.useJqueryCDN;
		container.uses("datetime.js");

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		string value = opDispatch!"value";

		SysTime date = SysTime.fromISOExtString(value);
		date = date.toUTC;

		if(isRequired) {
			return "<div class='input-group'>
			               <input class='form-control "~cls~"' id='"~id~"' min='0001-01-00T00:00:00' max='3000-01-00T00:00:00' type='datetime-local' name='"~name~"' value='"~date.toISOExtString~"' required>
			               <span class='input-group-addon'>
	                             <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
	                       </span>
			        </div>";
		} else {
			return "<input class='form-control "~cls~"' id='"~id~"'  min='0001-01-00T00:00:00' max='3000-01-00T00:00:00'  type='datetime-local' name='"~name~"' value='"~date.toISOExtString~"'>";
		}
	}

	override string asPreview() {
		string value = opDispatch!"value";
		
		SysTime date = SysTime.fromISOExtString(value);
		date = date.toOtherTZ(PosixTimeZone.getTimeZone(crated.settings.defaultTZ));


		string text = crated.settings.dateFormat;

		text = text.replace("d", date.day.to!string).replace("m", date.month.to!string).replace("Y", date.year.to!string)
				   .replace("G", date.hour.to!string).replace("i", date.minute.to!string).replace("s", date.second.to!string);

		return text;
	}
}


class ViewDuration : ViewType {


	private string inputForm(bool isRequired = false) {

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";
		Duration value;

		try {
			value = dur!"hnsecs"(opDispatch!"value".to!long);
		} catch(Exception e) {
			value = dur!"hnsecs"(0);
		}

		string required;

		if(isRequired) {
			required = "required";
		}

		long weeks, days, hours, minutes, seconds;
		value.split!("weeks", "days", "hours", "minutes", "seconds")(weeks, days, hours, minutes, seconds);

		return "
				<div class='row'>
					<div class='col-xs-2'>
						<label class='text-info' for='"~id~"weeks'>weeks</label>
						<input class='form-control "~cls~"' id='"~id~"weeks'   type='number' name='"~name~"[weeks]'   value='" ~ weeks.to!string   ~ "' "~required~">
					</div>
					<div class='col-xs-2'>
						<label class='text-info' for='"~id~"days'>days</label>
						<input class='form-control "~cls~"' id='"~id~"days'    type='number' name='"~name~"[days]'    value='" ~ days.to!string    ~ "' "~required~">
					</div>
					<div class='col-xs-2'>
						<label class='text-info' for='"~id~"hours'>hours</label>
						<input class='form-control "~cls~"' id='"~id~"hours'   type='number' name='"~name~"[hours]'   value='" ~ hours.to!string   ~ "' "~required~">
					</div>
					<div class='col-xs-2'>
						<label class='text-info' for='"~id~"minutes'>minutes</label>
						<input class='form-control "~cls~"' id='"~id~"minutes' type='number' name='"~name~"[minutes]' value='" ~ minutes.to!string ~ "' "~required~">
					</div>
					<div class='col-xs-2'>
						<label class='text-info' for='"~id~"seconds'>seconds</label>
						<input class='form-control "~cls~"' id='"~id~"seconds' type='number' name='"~name~"[seconds]' value='" ~ seconds.to!string ~ "' "~required~">
					</div></div>
		";

	}

	override string asForm(bool isRequired = false) {

		if(isRequired) {

			return "<div class='input-group'>
			               " ~ inputForm ~ "
			               <span class='input-group-addon'>
	                             <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
	                       </span>
			        </div>";
		} else {
			return inputForm;
		}
	}

	override string asPreview() {
		Duration value;
		
		try {
			value = dur!"hnsecs"(opDispatch!"value".to!long);
		} catch(Exception e) {
			value = dur!"hnsecs"(0);
		}

		if(value.total!"hnsecs" == 0) return "-";

		return value.to!string;
	}
}
