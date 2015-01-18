/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 5, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.datetime;

import temple;

import core.time;
import std.datetime;
import std.conv;
import std.array;
import crated.view.base;
import crated.model.calendar;

import std.stdio; //todo: remove this

struct SysTimeView {

	string[string] attributes;
	SysTime value;

	BaseView container;
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}

	///
	string asForm(bool isRequired = false) {
		if(container is null) throw new CratedViewException("Can't find the parent container");

		container.useJqueryCDN;
		container.uses("datetime.js");

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";


		import std.stdio;

		if(isRequired) {
			return "<div class='input-group'>
			               <input class='form-control "~cls~"' id='"~id~"' min='0001-01-00T00:00:00' max='3000-01-00T00:00:00' type='datetime-local' name='"~name~"' value='"~value.toISOExtString~"' required>
			               <span class='input-group-addon'>
	                             <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
	                       </span>
			        </div>";
		} else {
			return "<input class='form-control "~cls~"' id='"~id~"'  min='0001-01-00T00:00:00' max='3000-01-00T00:00:00'  type='datetime-local' name='"~name~"' value='"~value.toISOExtString~"'>";
		}
	}

	string asPreview() {
		string text = crated.settings.dateFormat;

		text = text.replace("d", value.day.to!string).replace("m", value.month.to!string).replace("Y", value.year.to!string)
			       .replace("G", value.hour.to!string).replace("i", value.minute.to!string).replace("s", value.second.to!string);

		return text;
	}
}


struct DurationView {


	string[string] attributes;
	Duration value;
	BaseView container;
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}

	private string inputForm(bool isRequired = false) {

		string id = opDispatch!"id";
		string cls = opDispatch!"cls";
		string name = opDispatch!"name";

		string required;

		if(isRequired) {
			required = "required";
		}

		long weeks, days, hours, minutes, seconds;
		value.split!("weeks", "days", "hours", "minutes", "seconds")(weeks, days, hours, minutes, seconds);

		return "<div class='row'>
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
					</div></div>";

	}

	string asForm(bool isRequired = false) {

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

	string asPreview() {
		if(value.total!"hnsecs" == 0) return "-";

		return value.to!string;
	}
}

struct CalendarRuleView {

	string[string] attributes;
	CalendarRulePrototype value;

	BaseView container;
	
	/**
	 * Allows to access attributes using dot sintax
	 */
	@property const(string) opDispatch(string prop)() const { 
		if(prop in attributes) return attributes[prop]; 
		
		return "";
	}
	
	/// ditto
	@property ref string opDispatch(string prop)() { 
		if(prop !in attributes) attributes[prop] = ""; 
		
		return attributes[prop]; 
	}

	string asForm(bool isRequired = false) {

		//container.uses("calendarRuleViewAsForm.css");

		auto tpl = compile_temple_file!"adminRuleView.emd";

		auto context = new TempleContext();
		if("name" in attributes) context.name = attributes["name"];
			else context.name = "";

		if(value is null) {
			context.monday = "";
			context.tuesday = "";
			context.wednesday = "";
			context.thursday = "";
			context.friday = "";
			context.saturday = "";
			context.sunday = "";
			
			context.startTime = "";
			context.endTime = "";
			context.repeatAfterWeeks = "0";
		} else {
			context.monday = value.monday ? "checked":"";
			context.tuesday = value.tuesday ? "checked":"";
			context.wednesday = value.wednesday ? "checked":"";
			context.thursday = value.thursday ? "checked":"";
			context.friday = value.friday ? "checked":"";
			context.saturday = value.saturday ? "checked":"";
			context.sunday = value.sunday ? "checked":"";

			context.startTime = value.startTime.toISOExtString;
			context.endTime = value.endTime.toISOExtString;
			context.repeatAfterWeeks = value.repeatAfterWeeks.to!string;
		}

		string field = tpl.toString(context).to!string;

		if(isRequired) {
			return "<div class='input-group'><!--
			               "~field~" 
			               <span class='input-group-addon'>
	                             <span class='glyphicon glyphicon-fire' aria-hidden='true'></span>
	                       </span>
			        </div>";
		} else {
			return "<!--"~field;
		}
	}
	
	string asPreview() {
		return "rule?";
	}
}

unittest {
	CalendarRuleView view;
	auto rule = new CalendarRule;

	view.value = rule;

	assert(view.value == rule);
}

unittest {
	alias ArrayRuleView = ArrayView!CalendarRuleView;

	auto view = new ArrayRuleView;
	CalendarRule[] list;
	list ~= new CalendarRule;

	view.value = list;

	assert(view.value.length == 1);
}