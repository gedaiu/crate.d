
/**
 * Views to manage data
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.admin;

import std.conv;
import crated.model.base;
import crated.view.datetime;

import temple;

public import crated.view.base;

template AdminView(Model) {
	class AdminViewTpl : BaseView {

		alias Descriptor = Model.Descriptor;

		immutable string baseUrl;
		
		this(const string baseUrl, BaseView parent) {
			super(parent);
			this.baseUrl = baseUrl;
		}

		/**
		 * 
		 */
		ViewType editFormFieldByType(string field)(string itemType, ulong index) {
			bool required;
			string requiredIcon;

			if(Descriptor.HasField(itemType, field) && Descriptor.HasAttribute(itemType, field, "required")) required = true;

			string cls;
			
			if(index == 1) cls ~= "input-lg";

			ViewType view;

			string fieldType;
			string fieldDesc;

			if(Descriptor.HasField(itemType, field)) {
				fieldType = Descriptor.GetType(itemType, field);
				fieldDesc = Descriptor.GetDescription(itemType, field);
			} else {
				fieldType = Descriptor.GetType(field);
				fieldDesc = Descriptor.GetDescription(field);
			}

			switch(fieldType) {
				case "bool":
					view = new ViewBool;
					view.container = parent;
					
					break;
					
				case "byte": case "short": case "int": case "long": case "cent": case "ubyte": case "ushort":
				case "uint": case "ulong": case "ucent":
					view = new ViewType;
					view.container = parent;
					view.type = "number";
					
					break;
					
				case "float": case "double": case "real":
					view = new ViewType;
					view.container = parent;
					view.type = "number";
					view.step = "0.01";
					
					break;
					
				case "SysTime":
					view = new ViewSysTime;
					view.container = parent;
					
					break;
					
				case "Duration":
					view = new crated.view.datetime.ViewDuration;
					view.container = parent;
					
					break;
					
				default:
					
					if(fieldDesc == "isEnum") {
						view = new ViewList;
						view.container = parent;

						static if(is(typeof(Descriptor.enumValues) == string[][string]) && field in Descriptor.enumValues) {

							foreach(v; Descriptor.enumValues[field]) {
								static if( is(typeof(v) == string) ) {
									(cast(ViewList) view).addItem(v);
								} else {
									(cast(ViewList) view).addItem(v.to!string);
								}
							}

						}
					} else {
						view = new ViewType;
						view.container = parent;
						
						view.type = "text";
					}
			}
			
			view.cls = cls;
			view.id = "formElement" ~ index.to!string;
			view.name = field;
			
			return view;
		}

		/**
		 * 
		 */
		private ViewType getViewByAttribute(string field)(string itemType, ulong index) {
			
			ViewType view;
			
			string fieldType;

			if(Descriptor.HasField(itemType, field)) 
			{
				fieldType = Descriptor.AttributeValue(itemType, field, "type");
			}
			else
			{
				fieldType = Descriptor.AttributeValue(field, "type");
			}

			string cls;
			
			if(index == 1) cls ~= "input-lg";
			
			switch(fieldType) {
				case "color": case "date": case "datetime": case "datetime-local": case "email": case "month":
				case "number": case "range": case "tel": case "time": case "url": case "week":
					view = new ViewType;
					view.container = parent;
					view.type = fieldType;
					view.cls = cls;
					view.id = "formElement" ~ index.to!string;
					view.name = field;
					
					break;
				default:
					break;
			}
			
			return view;
		}

		/// Private: 
		private ViewType getTypeFor(string field, PrototypedItem)(PrototypedItem item, ulong index = 0) {
			ViewType inputField = getViewByAttribute!field(Descriptor.Type(item), index);
			
			//build the value based on the property type
			if(inputField is null) inputField = editFormFieldByType!field(Descriptor.Type(item), index);

			static if( is(typeof(__traits(getMember, item, field)) == std.datetime.SysTime) ) 
			{
				inputField.value = __traits(getMember, item, field).toISOExtString;
			}
			else static if( is(typeof(__traits(getMember, item, field)) == core.time.Duration) ) 
			{
				inputField.value = __traits(getMember, item, field).total!"hnsecs".to!string;
			}
			else
			{
				inputField.value = __traits(getMember, item, field).to!string;
			}
			return inputField;
		}

		/**
		 * 
		 */
		string asForm(string mode, PrototypedItem)(PrototypedItem item) {
			string a;

			useBootstrapCssCDN;

			/**
			 * 
			 */
			string editFormField(string field, PrototypedItem)(PrototypedItem item, ulong index) {
				string a;

				static if(field == Descriptor.primaryFieldName) { 
					a ~= "<input type='hidden' name='" ~ field ~ "' value='" ~ __traits(getMember, item, field).to!string ~ "' />";
					
				} else static if(field == "itemType") {
					a = "<input type='hidden' name='itemType' value='" ~ __traits(getMember, item, field).to!string ~ "' />";
				} else {
					string itemType = Descriptor.Type(item);

					if(Descriptor.HasField(itemType, field) && Descriptor.GetDescription(itemType, field) != "isConst") {
						ViewType inputField = getTypeFor!(field)(item, index);
						
						if(inputField !is null) {
							string cls;
							
							if(index == 1) cls = "class='text-primary'";
							
							a ~= `<div class="form-group">`;
							a ~= "<label "~cls~" for='formElement"~index.to!string~"'>" ~ field ~ "</label>";
							
							bool required;
							if(Descriptor.HasAttribute(itemType, field, "required")) required = true;
							
							a ~= inputField.asForm(required) ~ `</div>`;
						}
					}
				}
				
				return a;
			}

			string editFormFields(string[] fields, PrototypedItem)(PrototypedItem item, ulong index = 0) {
				
				static if(fields.length > 1) {
					return editFormFields!(fields[0..$/2])(item, index) ~ editFormFields!(fields[$/2..$])(item, index+fields.length/2);
				} else {
					return editFormField!(fields[0])(item, index);
				}
			}

			if(parent) {
				static if(mode == "edit") parent.title = "Edit " ~ Model.name;
				static if(mode == "add") parent.title = "Add " ~ Model.name;
			}


			auto tpl = compile_temple_file!"adminForm.emd";

			auto context = new TempleContext();

			static if(mode == "edit")
				context.action = baseUrl~`/save/` ~ Descriptor.PrimaryField(item);

			static if(mode == "add") 
				context.action = baseUrl~`/save/new`;

			context.fields = editFormFields!(Descriptor.fields)(item);

			static if(mode == "edit") {
				useBootstrapJsCDN;
				
				context.isGroup = true;
				context.submitText = "Save";

				static if(Descriptor.itemTypeList.length > 1) {
					string buttonList;

					buttonList = `<li class="divider"></li>`;
					foreach(type; Descriptor.itemTypeList) {
						if(type != item.itemType) {
							buttonList ~= `
								<li>
									<a href="#">
										<label for="save`~type.to!string~`">
											<span class="glyphicon glyphicon-transfer" aria-hidden="true"></span> as ` ~ type.to!string ~ `
										</label>
									</a>
									
									<input style="display: none" id="save`~type.to!string~`" name="__save" value="` ~ type.to!string ~ `" type="submit"/>
								</li>`;
						}
					}

					context.buttonList = buttonList;
				}
			}

			static if(mode == "add") {
				context.isGroup = false;
				context.submitText = "Add";
			}

			return tpl.toString(context);
		}
				
		/**
		 * 
		 */
		string asAdminTable(PrototypedItem)(PrototypedItem[] items) {
			string a;

			//build the table header
			string adminTableHeader(fields...)() 
			{
				static if(fields[0].length == 1 && fields[0][0] != Descriptor.primaryFieldName) 
				{
					return "<th>"~fields[0][0]~"</th>";
				}
				else static if (fields[0].length > 1) 
				{
					return adminTableHeader!(fields[0][0..$/2]) ~ adminTableHeader!(fields[0][$/2..$]);
				} 
				else 
				{
					return "";
				}
			}

			//build the table line
			string adminTableLine(fields...)(PrototypedItem item) 
			{
				static if(fields[0].length == 1 && fields[0][0] != Descriptor.primaryFieldName) 
				{
					ViewType inputField = getTypeFor!(fields[0][0])(item);
					
					return "<td>"~inputField.asPreview~"</td>";
				} 
				else static if (fields[0].length > 1) 
				{
					return adminTableLine!(fields[0][0..$/2])(item) ~ adminTableLine!(fields[0][$/2..$])(item);
				} else 
				{
					return "";
				}
			}

			useBootstrapCssCDN;

			if(parent) parent.title = Model.name;

			auto tpl = compile_temple_file!"adminTable.emd";

			string lines;
			foreach(item; items) 
			{
				lines ~= "<tr>";
				lines ~= adminTableLine!(Descriptor.fields)(item);
				lines ~= "<td><a class='btn btn-default' href='" ~ baseUrl ~ "/edit/" ~ Descriptor.PrimaryField(item) ~ "'>Edit</a> "~
					"<a class='btn btn-danger' href='" ~ baseUrl ~ "/delete/" ~ Descriptor.PrimaryField(item) ~ "'>Delete</a></td></tr>";
			}

			auto context = new TempleContext();

			static if(Descriptor.itemTypeList.length > 1) {
				useBootstrapJsCDN;
				context.isGroup = true;
				context.button = `<a class='btn btn-default' href='` ~ baseUrl ~ `/add/`~Descriptor.itemTypeList[0].to!string~`'>Add `~Descriptor.itemTypeList[0].to!string~`</a>`;
				
				string buttonList;
				foreach(i; 1..Descriptor.itemTypeList.length) {
					string type = Descriptor.itemTypeList[i].to!string; 
					
					buttonList ~= `<li><a href='` ~ baseUrl ~ `/add/`~Descriptor.itemTypeList[i].to!string~`'>Add ` ~ Descriptor.itemTypeList[i].to!string ~ `</a></li>`;
				}

				context.buttonList = buttonList;
			} else {	
				context.isGroup = false;
				context.button = `<a class='btn btn-default' href='` ~ baseUrl ~ `/add'>Add</a>`;
			}

			context.header = adminTableHeader!(Descriptor.fields);
			context.lines = lines;
			context.isEmpty = items.length == 0;

			return tpl.toString(context);
		}
	}
	
	alias AdminView = AdminViewTpl;
}
