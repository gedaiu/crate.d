
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
import std.traits;
import std.stdio;//todo: remove this

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
		string asForm(string mode, PrototypedItem)(PrototypedItem item) {
			string a;

			useBootstrapCssCDN;

			BaseView parentContainer = parent;

			/**
			 * 
			 */
			string editFormField(string itemType, string field)(ulong index) {
				string a;

				static if(field == Descriptor.primaryFieldName) { 
					a = "<input type='hidden' name='" ~ field ~ "' value='" ~ __traits(getMember, item, field).to!string ~ "' />";
				} else static if(field == "itemType") {
					a = "<input type='hidden' name='itemType' value='" ~ __traits(getMember, item, field).to!string ~ "' />";
				} else {

					if(Descriptor.HasField(itemType, field) && Descriptor.GetDescription(itemType, field) != "isConst") {
						auto inputField = Descriptor.GetView!(itemType, field);
						inputField.container = parentContainer;
						inputField.value = __traits(getMember, item, field);
						inputField.name = field;
						string cls;

						if(index == 1) cls = "class='text-primary'";

						a ~= `<div class="form-group">`;
						a ~= "<h3><label "~cls~" for='formElement"~index.to!string~"'>" ~ field ~ "</label></h3>";

						bool required;
						if(Descriptor.HasAttribute(itemType, field, "required")) required = true;

						a ~= inputField.asForm(required) ~ `</div>`;
					}
				}

				return a;
			}

			string editFormFields(string itemType, string[] fields)(ulong index = 0) {

				static if(fields.length > 1) {
					return editFormFields!(itemType, fields[0..$/2])(index) ~ editFormFields!(itemType, fields[$/2..$])(index+fields.length/2);
				} else {
					return editFormField!(itemType, fields[0])(index);
				}

				return "";
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

			auto type = Descriptor.Type(item);

			mixin(Descriptor.GenerateItemConditions!`context.fields = editFormFields!(SType, Descriptor.fields);`);

			static if(mode == "edit") {
				useBootstrapJsCDN;
				
				context.isGroup = true;
				context.submitText = "Save";

				static if(Descriptor.itemTypeList.length > 1) {
					string buttonList;

					buttonList = `<li class="divider"></li>`;
					foreach(itemType; Descriptor.itemTypeList) {
						if(itemType != item.itemType) {
							buttonList ~= `
								<li>
									<a href="#">
										<label for="save`~itemType.to!string~`">
											<span class="glyphicon glyphicon-transfer" aria-hidden="true"></span> as ` ~ itemType.to!string ~ `
										</label>
									</a>
									
									<input style="display: none" id="save`~itemType.to!string~`" name="__save" value="` ~ itemType.to!string ~ `" type="submit"/>
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
			string adminTableLine(string itemType)(PrototypedItem item) 
			{
				string previewLine(L...)() 
				{
					static if(L[0].length == 1 && (L[0][0] in Model.Descriptor.fieldList[itemType]) !is null && !Model.Descriptor.HasAttribute!(itemType, L[0][0], "primary")) {
						auto view = Descriptor.GetView!(itemType, L[0][0]);

						view.value = __traits(getMember, item, L[0][0]);

						return `<td>` ~ view.asPreview ~ `</td>`;
					} else static if (L[0].length > 1) {
						return previewLine!(L[0][0..$/2]) ~ previewLine!(L[0][$/2..$]);
					} else static if ( !Descriptor.HasAttribute!(itemType, L[0][0], "primary") ){
						return `<td>-</td>`;
					} else {
						return ``;
					}
				}

				return previewLine!(Model.Descriptor.fields);
			}

			///create the code for selecting the right line type
			string createLines() {
				string code;

				foreach(type; Model.Descriptor.itemTypeList) {
					code ~= "if(item.itemType.to!string == `" ~ type.to!string ~ "`) lines ~= adminTableLine!`" ~ type.to!string ~ "`(item);";
				}

				return code;
			}

			useBootstrapCssCDN;

			if(parent) parent.title = Model.name;

			auto tpl = compile_temple_file!"adminTable.emd";

			string lines;
			foreach(item; items) 
			{
				lines ~= "<tr>";

				static if(__traits(hasMember, PrototypedItem, "itemType")) {
					mixin(createLines());
				} else {
					lines ~= adminTableLine!""(item);
				}

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
