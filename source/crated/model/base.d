/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 * 
 * Provides templates to create data models. There are two components that are used 
 * to represent data. Models and Items. 
 * 
 * The model is a collection of items and it usualy represents a table. The <code>ModelTemplate</code>
 * provides a standard interface for one dimension model. It can be used directly, 
 * but it does not save it's content.
 * 
 * An Item is a group of fields that usualy represents a table row. You should not create Items directly.
 * Create items using a Descriptor. 
 * 
 * A Descriptor is used to describe an Item and has a various of useful functions that helps you to get informations
 * for a particular Item type. You can create models only by having the item descriptor.
 */
module crated.model.base;

import std.stdio;
import std.string;
import std.traits;
import std.algorithm;
import std.conv;
import std.typecons;
import std.datetime;
import core.time;

import vibe.d;

import crated.tools;
import crated.view.base;
import crated.view.datetime;

/**
 * Aggregates all information about a model error status.
 */
class CratedModelException : Exception {
	/**
	 * Create the exception
	 */
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}
}

///iterate all attributes and search a view struct
template FieldByAttribute(alias EndString, L...) {

	///look for a struct UDA that ends with EndString
	template TypeFromAttributes(T...) {

		static if(T.length == 0) {
			alias TypeFromAttributes = TypeTuple!();
		} else static if(T.length == 1) {

			enum name = T[0].stringof;
			enum len = EndString.length;

			static if( ( is(T[0] == struct) || is(T[0] == class) ) && name.length > len && name[$-len..$] == EndString) {
				alias TypeFromAttributes = TypeTuple!(T[0]);
			} else {
				alias TypeFromAttributes = TypeTuple!();
			}
		} else {
			alias TypeFromAttributes = TypeTuple!(TypeFromAttributes!(T[0..$/2]), TypeFromAttributes!(T[$/2 .. $]) );
		}
	}

	static if(L.length == 0) {
		alias FieldByAttribute = TypeTuple!();
	} else static if(L.length == 1) {
		alias FieldByAttribute = TypeTuple!( TypeFromAttributes!(__traits(getAttributes, L[0])) );
	} else {
		alias FieldByAttribute = TypeTuple!( FieldByAttribute!(EndString, L[0..$/2]), FieldByAttribute!(EndString, L[$/2 .. $]) );
	}
}

///Create a descriptor from a Prototype class
template ModelDescriptor(Prototype) {
	alias ModelDescriptor = ModelDescriptor!(Prototype, "", Prototype);
}

/**
 * Create a descriptor from a Prototype and other classes that inherits the prototype.
 */
class ModelDescriptor(PrototypeCls, List...)
{
	import std.typetuple;

	alias Prototype = PrototypeCls;

	///Create the field list for every item type
	template CreateFieldList(alias Index) {
		
		static if (Index < List.length/2) {
			alias CreateFieldList = TypeTuple!([ List[Index].to!string : FieldList!( List[List.length/2 + Index] ) ], CreateFieldList!(Index+1));
		} else {
			alias CreateFieldList = TypeTuple!();
		}
	}

	enum itemTypeList = [ List[0..$/2] ];
	alias clsList = List[$/2..$];

	//TODO: rename fields to prototypeFields and fieldList to fieldListByType
	mixin("enum fieldList = [ " ~ Join!(CreateFieldList!0) ~ " ];");
	enum fields = EnumerateFieldList!( Prototype );
	enum primaryFieldName = PrimaryFieldName!(Prototype);
	mixin("enum enumValues = [ " ~ getEnumValues ~ " ];");

	///Get all classes from the descriptor
	template FindCls(string ItemType, L...) {
		static if(L.length == 0) {
			alias FindCls = TypeTuple!();
		} else {
			static if(ItemType == L[0].to!string) {
				alias FindCls = TypeTuple!(L[$/2]);
			} else {
				alias FindCls = TypeTuple!( FindCls!(ItemType, L[1..$/2] , L[$/2 +1 .. $]) );
			}
		}
	}

	///Get the prototype of an array type field
	template FindPrototypeTypeFor(ItemType, alias name) {

		alias Type = typeof(__traits(getMember, ItemType, name));

		static if(!isSomeString!Type && isArray!Type) {

			alias fieldPrototype = FieldByAttribute!("Prototype", __traits(getOverloads, ItemType, name));

			static if(fieldPrototype.length == 0) {
				alias FindPrototypeTypeFor = ArrayType!(typeof(__traits(getMember, ItemType, name)));
			} else {
				alias FindPrototypeTypeFor = fieldPrototype[0];
			}
		} else {
			alias FindPrototypeTypeFor = typeof(__traits(getMember, ItemType, name));
		}
	}

	template FindViewTypeFor(string ItemType, string name) {
		
		alias CLS = FindCls!(ItemType, List);
		alias originalType = OriginalFieldType!(__traits(getMember, CLS, name));

		alias FindViewTypeFor = FindView!(originalType);

		template FindView(type) {

			static if(isAssociativeArray!(type)) {
				alias View = AssociativeArrayView!(FindView!(ValueType!type), TypeView!(KeyType!type));

			} else static if(!isSomeString!(type) && isArray!(type)) {
				alias View = ArrayView!(FindView!(ArrayType!type));

			} else {

				alias viewAttribute = FieldByAttribute!("View", __traits(getOverloads, CLS, name));

				static if(viewAttribute.length > 0) 
					alias View = viewAttribute[0];

				else static if (is(type == SysTime)) 
					alias View = SysTimeView;
				
				else static if (is(type == Duration)) 
					alias View = DurationView;

				else alias View = TypeView!type;
			}
		
			alias FindView = View;
		}
	}

	mixin template CreateViewList(FIELDS...) {

		static if(FIELDS[0].length == 1) {

			enum FieldName = FIELDS[0][0];
			alias TypeName = typeof(__traits(getMember, PrototypeCls, FieldName));

			///Get field view
			static auto GetView(string itemType, string field)() if(field == FieldName) {
				alias VIEW = FindViewTypeFor!( itemType, field );
				VIEW view;

				return view;
			}
		} else static if(FIELDS[0].length > 1) {
			mixin CreateViewList!(FIELDS[0][0..$/2]);
			mixin CreateViewList!(FIELDS[0][$/2..$]);
		}
	}

	mixin CreateViewList!fields;

	/**
	 * Generate the values for the enums from the current item
	 */
	private static string getEnumValues(ulong i = 0)() {
		
		//exit condition
		static if(i >= fields.length) {
			return "";
		} else {
			enum auto field = fields[i];

			alias isEnum = IsEnum!(typeof(ItemProperty!(Prototype, field)));

			//check for D types
			static if(isEnum.check) {
				import std.traits;
				
				string vals = "";
				
				string glue = "";
				foreach(v; EnumMembers!(typeof(__traits(getMember, Prototype, field)))) {
					if(v.stringof[1..$-1] != "") {
						vals ~= glue ~ `"` ~ v.stringof[1..$-1] ~ `"`; 
						glue = ", ";
					}
				}
				
				return (i==0 ? ", ":"") ~ `"` ~ field ~ `": [` ~ vals ~ `]` ~ getEnumValues!(i + 1);
			} else {
				return getEnumValues!(i + 1);
			}
		}
	}

	static 
	{
		private 
		{
			string generateConditions(string code)(int i = 0) {
				string a;
				
				if(i < List.length/2) {
					a ~= "
				            if(type == List["~i.to!string~"].to!string) {
								alias ClsType = List[$/2 + "~i.to!string~"];
								enum string SType = List["~i.to!string~"].to!string;
								"~code~"
							}\n" ~ generateConditions!code(i+1);
				}
				
				return a;
			}
		
			string generateSetters(string type)() {
				string a;
				
				if(type in fieldList) { 
					foreach(string field; fields) {
						if(field in fieldList[type]) {
							string fieldType = fieldList[type][field]["type"][0];
							string fieldDescription = fieldList[type][field]["description"][0];
							string isBasicType = fieldList[type][field]["type"][1];
							
							if( fieldType == "string" && fieldDescription == "" ) {
								//is a string field
								a ~= "if(field == `" ~ field ~ "` && field in data) item." ~ field ~ " = data[field];";
								
							} else if (isBasicType == "true" && 
								(fieldDescription != "isArray" && fieldDescription == "isAssociativeArray")) {
								//is a basic type field
								a ~= "if(field == `" ~ field ~ "` && field in data) item." ~ field ~ " = data[field].to!"~fieldType~";";
							} else if ((fieldType == "string" || isBasicType == "true") && 
								(fieldDescription == "isArray" || fieldDescription == "isAssociativeArray")) {
								//is array of basic types
								a ~= "if(field == `" ~ field ~ "`) {
									   
									   item." ~ field ~ " = extractArray!(`"~field~"`, typeof(item." ~ field ~ ") )(data);
							}";
							}
							
						}
					}
				}
				
				return a;
			}
		}

		string GenerateItemConditions(string code, int i = 0)() {
			string a;

			static if(i < List.length/2) {
				a ~= "
			            if(type == `" ~ List[i].to!string ~ "`) {
							 enum string SType = `" ~ List[i].to!string ~ "`;
							" ~ code ~ "
						}\n" ~ GenerateItemConditions!(code, i+1);
			}
			
			return a;
		}


		protected T FillBasicFields(string type, T)(T item, string[string] data) {

			foreach(string field; fields) {
				mixin(generateSetters!type);
			}

			return item;
		}

		Prototype CreateItemFrom(T)(T data) {
			return CreateItemFrom("", data);
		}

		Prototype CreateItemFrom(T)(string type, T data) {
			Prototype item = CreateItemType(type);
			string[string] dataAsString = toStringDictionary(data);

			if(type == "")
				item = FillBasicFields!""(item, dataAsString);
			
			mixin(generateConditions!"item = FillBasicFields!SType(item, dataAsString);");
			
			return item;
		}
		
		///
		Prototype CreateItem(string type, string[string] data) {
			Prototype item = CreateItemType(type);

			if(type == "")
				item = FillBasicFields!""(item, data);

			mixin(generateConditions!"item = FillBasicFields!SType(item, data);");

			return item;
		}

		Prototype CreateItemType(string type) {
			Prototype item;

			if(type == "") {
				alias ClsType = List[$/2];
				item = new ClsType();
			}

			mixin(generateConditions!"item = new ClsType;");

			if(item is null)
				throw new CratedModelException("CreateItem Can't create item of type `"~type~"`");
				
			return item;
		}

		///
		ref PrimaryFieldType!(Prototype) PrimaryField(Prototype item) {
			return __traits(getMember, item, PrimaryFieldName!(Prototype));
		}

		///
		void RemovePrimaryField(Prototype item) {
			PrimaryFieldType!(Prototype) blankId;
			__traits(getMember, item, PrimaryFieldName!(Prototype)) = blankId;
		}

		///
		bool HasField(Prototype item, string field) {
			auto type = Type(item);

			mixin(generateConditions!"return HasField(type, field);");

			throw new CratedModelException("HasField Can't find `" ~ field ~ "` type");
		}
		
		///
		bool HasField(string type, string field) {
			if(field !in fieldList[type]) return false;
			return true;		
		}

		///
		bool HasAttribute(Prototype item, string field, string attribute) {
			auto type = Type(item);
			mixin(generateConditions!"return HasAttribute(type, field, attribute);");

			throw new CratedModelException("HasAttribute Can't find `" ~ field ~ "` type");
		}

		///
		bool HasAttribute(string type, string field, string attribute) {
			if(!HasField(type, field)) throw new CratedModelException("HasAttribute Can't find `" ~ field ~ "` for `" ~ type ~ "`");
			
			foreach(attr; fieldList[type][field]["attributes"]) {
				if(attr == attribute || attr.indexOf(attribute ~ ":") == 0) {
					return true;
				}
			}
			
			return false;
		}

		///
		bool HasAttribute(string type, string field, string attribute)() {

			bool has(list...)() {

				static if(list[0].length == 1) {
					static if(attribute == list[0][0]) {
						return true;
					} else static if(attribute.length < list[0][0].length) {
						enum attr = attribute ~ ":";

						static if(list[0][0][0..attr.length] == attr) {
							return true;
						} else {
							return false;
						}

					} else {
						return false;
					}

				} else static if(list[0].length > 1) {
					auto r1 = has!(list[0][0..$/2]);
					auto r2 = has!(list[0][$/2..$]);

					return r1 || r2;
				} else {
					return false;
				}
			}

			static if( (field in fieldList[type]) !is null) {
				return has!(fieldList[type][field]["attributes"]);
			} else {
				return false;
			}
		}	

		///
		string AttributeValue(Prototype item, string field, string attribute) {

			auto type = Type(item);
			mixin(generateConditions!"return AttributeValue(type, field, attribute);");
			
			throw new CratedModelException("AttributeValue Can't find `" ~ field ~ "` type");
		}

		///
		string AttributeValue(string type, string field, string attribute) {
			if(!HasField(type, field)) throw new CratedModelException("AttributeValue Can't find `" ~ field ~ "` for `" ~ type ~ "`");
			
			foreach(attr; fieldList[type][field]["attributes"]) {
				if(attr.indexOf(attribute ~ ":") == 0) {
					auto pos = attr.indexOf(":");
					
					return attr[pos+1..$].strip;
				}
			}
			
			return "";
		}

		///
		string AttributeValue(string field, string attribute) {

			foreach(type; fieldList) {
				if(field in type) {
					foreach(attr; type[field]["attributes"]) {
						if(attr.indexOf(attribute ~ ":") == 0) {
							auto pos = attr.indexOf(":");
							
							return attr[pos+1..$].strip;
						}
					}
				}
			}

			return "";
		}

		///
		string GetDescription(Prototype item, string field) {

			auto type = Type(item);
			mixin(generateConditions!"return GetDescription(type, field);");

			throw new CratedModelException("GetDescription Can't find `" ~ field ~ "` type");
		}
		
		///
		string GetDescription(string type, string field) {
			if(!HasField(type, field)) throw new CratedModelException("GetDescription Can't find `" ~ field ~ "` for `" ~ type ~ "`");
			
			return fieldList[type][field]["description"][0];
		}

		///
		string GetDescription(string field) {
			foreach(type; fieldList) {
				if(field in type) return type[field]["description"][0];
			}
			
			return "";
		}
		
		///
		string GetType(Prototype item, string field) {

			auto type = Type(item);
			mixin(generateConditions!"return GetType(type, field);");

			throw new CratedModelException("GetType Can't find `" ~ field ~ "` type");
		}
		
		///
		string GetType(string type, string field) {
			return fieldList[type][field]["type"][0];
		}

		///
		string GetType(string field) {
			foreach(type; fieldList) {
				if(field in type) return type[field]["type"][0];
			}

			return "";
		}

		///
		string Type(Prototype item) {
			static if(__traits(hasMember, Prototype, "itemType")) {
				return (item.itemType).to!string;
			} else {
				return "";
			}
		}

		///
		string[string] ToDic(Prototype item) {
			Json data = Json.emptyObject;

			FillFields!(Json, Prototype, fields)(data, item);

			string[string] dataAsString = toStringDictionary(data);

			return dataAsString;
		}

		T Convert(T)(Prototype item) if(is(T==Json) || is(T==Bson)) {
			T data = T.emptyObject;
			
			FillFields!(T, Prototype, [__traits(allMembers, Prototype)])(data, item);

			return data;
		}

		///
		BsonObjectID GetAndUpdateBsonId(ref string val) {
			BsonObjectID id;

			if(val == "") {
				id = BsonObjectID.generate;
				val = id.to!string;
			} else {
				id = BsonObjectID.fromString(val);
			}

			return id;
		}

		T ConvertField(T, P, U)(U value) {

			static if(isBasicType!U) {
				alias isEnum = IsEnum!U;
				
				static if(isEnum.check) {
					return T(value.to!string);
				} else { 
					return T(value);
				}
				
			} else static if (is(U == string)) {
				return T(value);
				
			} else static if (is(U == SysTime)) {
				static if( is(T == Bson) ) {
					return T(BsonDate(value));
				} else {
					return T(value.toISOExtString);
				}
			} else static if (is(U == Duration)) {
				return T(value.total!"hnsecs");

			} else static if ( is(U == TimeOfDay)) {
				return T(value.toISOExtString);
			} else static if(!isSomeString!U && isArray!U) {
				T[] array;
				
				foreach(i; 0..value.length ) {
					T listItem;
					
					listItem = ConvertField!(T, P)(value[i]);
					
					array ~= [ listItem ];
				}
				
				return T(array);
			} else static if(isAssociativeArray!U) {
				
				T obj = T.emptyObject;
				
				foreach(key, item; value) {
					auto listItem = T.emptyObject;
					
					obj[key] = ConvertField!(T, P)(item);
				}
				
				return obj;
				
			} else if( is(U == class) || is(U == struct) ) {
				T data = T.emptyObject;

				enum fullName = fullyQualifiedName!U;
				enum pos = fullName.lastIndexOf(".")+1;
				enum name = fullName[pos..$];

				FillFields!(T, U, [__traits(allMembers, P)])(data, value);

				return data;

			} else {
				return T(value.to!string);
			} 
		}

		///Private:
		void FillFields(T, U, FIELDS...)(ref T data, U item) {
			import std.traits;
			import crated.tools;

			static if(FIELDS[0].length == 1) {
				static if( FIELDS[0][0] == "duration")
					writeln(FIELDS[0][0], " =", CanGetValue!(FIELDS[0][0], U) );

				static if(CanGetValue!(FIELDS[0][0], U)) {
					alias CurrentType = FindPrototypeTypeFor!(U, FIELDS[0][0]);

					//if is a bson id
					static if(PrimaryFieldName!(Prototype) == FIELDS[0][0] && is(T == Bson) && is(CurrentType == string)) {
						auto id = GetAndUpdateBsonId(__traits(getMember, item, FIELDS[0][0]));
						data[FIELDS[0][0]] = id;
					} else static if( !is(CurrentType == void) ) {
						data[FIELDS[0][0]] = ConvertField!(T, CurrentType)(__traits(getMember, item, FIELDS[0][0]));
					}
				}

			} else static if(FIELDS[0].length > 1) {
				FillFields!(T, U, FIELDS[0][0..$/2])(data, item);
				FillFields!(T, U, FIELDS[0][$/2..$])(data, item);
			}
		}
	}
}

/// Abstract model definition
template AbstractModel(ModelDescriptor) {

	alias Prototype = ReturnType!(ModelDescriptor.CreateItem);

	/**
	 * Abstract model definition
	 */
	abstract class Model {
					
		alias Descriptor = ModelDescriptor;

		static {

			/**
			 * Add or update an element
			 */
			void save(Prototype item);

			/**
			 * Add or update a list of elements
			 */
			void save(Prototype[] items);

			/**
			 * Remove an existing item
			 */
			void remove(T)(T item);

			/**
			 * Remove one item
			 */
			void remove(Prototype item);

			/**
			 * Remove a list of items
			 */
			void remove(Prototype[] items);

			/**
			 * Remove an item by field name
			 */
			void remove(string field, T)(T value);

			/**
			 * Remove all items
			 */
			void truncate();

			/**
			 * Retrieve all items
			 */
			Prototype[] all();

			/**
			 * Count all items
			 */
			ulong length();

			/**
			 * Create a new item. The returned item will not be 
			 * automatically added to the model. If you want to add it to a model
			 * call Item.save()
			 */
			static Prototype CreateItem(string type = "")();			

			/**
			 * Create an item from some dictionary
			 */
			static Prototype CreateItem(T)(T data) if(!is(T == string));

			/**
			 * Find all items that match the search criteria 
			 */
			Prototype[] getBy(string fieldName, T)(T value);

			/**
			 * Retrieve the first item that match the search
			 * criteria
			 */
			Prototype getOneBy(string fieldName, T)(T value);

			/**
			 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
			 * you should implement this method in your model.
			 */
			Prototype[] query(T)(T query);
		}
	}

	alias AbstractModel = Model;
}

/**
 * A basic model implementation without any persistence
 */
template Model(alias ModelDescriptor, string modelName = "Unknown") {

	/// Add helper methods for the basic model
	mixin ModelHelper!ModelTemplate;

	/// The basic model implementation
	class ModelTemplate : AbstractModel!ModelDescriptor {

		///An alias to the item class type.
		alias Prototype = ReturnType!(ModelDescriptor.CreateItem);

		static {
			ulong idIndex = 0;

			///The model name.
			enum string name = modelName;

			///Protected: item container
			protected Prototype[] items;

			/**
			 * Add or update an element
			 */
			void save(Prototype item) {
				auto itemId = ModelDescriptor.PrimaryField(item);
				bool added = false;

				foreach(i; 0..items.length) {
					auto currentId = ModelDescriptor.PrimaryField(items[i]);

					if(itemId == currentId) {
						items[i] = item;
						return;
					}
				}

				idIndex++;

				Descriptor.PrimaryField(item) = idIndex.to!(typeof(itemId));
				items ~= [item];
			}

			/**
			 * Add or update a list of elements
			 */
			void save(Prototype[] items) {
				foreach(item; items) {
					save(item);
				}
			}

			/**
			 * Remove an existing item
			 */
			void remove(Prototype item) {
				if(items.length == 0) return; 

				if(item == items[0]) {
					items = items[1..$];
					return;
				}

				if(item == items[items.length-1]) {
					items = items[0..$-1];
					return;
				}

				foreach(i; 1..items.length-1) {
					if(items[i] == item) {
						
						items = items[0..i-1] ~ items[i+1..$];
						
						return;
					}
				}
			}

			/**
			 * Remove an existing item
			 */
			void remove(Prototype[] items) {
				foreach(i;0..items.length) {
					remove(items[i]);
				}
			}

			/**
			 * Remove an item by field name
			 */
			void remove(string field, T)(T value) {
				foreach(item; items) {
					if(__traits(getMember, item, field) == value) {
						remove(item);
					}
				}
			}
		
			/**
			 * Remove all items
			 */
			void truncate() {
				items = [];
				idIndex = 0;
			}

			/**
			 * Create a new item. The returned item will not be 
			 * automatically added to the model. If you want to add it to a model
			 * call Item.save()
			 */
			static Prototype CreateItem(string type = "")() {
				string[string] data;
				
				Prototype item = ModelDescriptor.CreateItem(type, data);
				
				return item;
			}

			/**
			 * Create an item from some dictionary
			 */
			static Prototype CreateItem(T)(T data) if(!is(T == string)) {
				string type = "";
				if("type" in data) type = data["type"].to!string;
				
				string[string] dataAsString = toStringDictionary(data);
				auto itm = ModelDescriptor.CreateItem(type, dataAsString);
				
				return itm;
			}

			/**
			 * Retrieve all items
			 */
			Prototype[] all() {
				return items;
			}

			/**
			 * Query the model. This is unsupported for the base model, but if you want to use a database as storage,
			 * you should implement this method in your model.
			 */
			Prototype[] query() {
				throw new CratedModelException("unsupported method");
			}

			/**
			 * Count an item set 
			 */
			ulong length(string fieldName, T)(T value) {
				ulong sum = 0;

				auto list = all;

				foreach(i; 0..list.length) {
					sum += __traits(getMember, list[i], fieldName) == value ? 1 : 0;
				}

				return sum;
			}

			/**
			 * Count all items
			 */
			ulong length() {
				return all.length;
			}

			/**
			 * Find all items that match the search criteria 
			 */
			Prototype[] getBy(string fieldName, T)(T value) {
				Prototype[] r;

				auto list = all;

				foreach(i; 0..list.length) {
					if(__traits(getMember, list[i], fieldName) == value) {
						r ~= [ list[i] ];
					}
				}

				return r;
			}

			/**
			 * Retrieve the first item that match the search criteria
			 */
			Prototype getOneBy(string fieldName, T)(T value) {
				auto list = all;

				foreach(i; 0..list.length) {
					if(__traits(getMember, list[i], fieldName) == value) {
						return list[i];
					}
				}

				return null;
			}

			/**
			 * Convert the items to a Json string
			 */
			string toString() {
				return items.to!string;
			}

		}
	}

	alias Model = ModelTemplate;
}

/**
 *	Misc functions model access 
 */
mixin template ModelHelper(Model) {

	void save(ref Model.Prototype item) {
		Model.save(item);
	}

	void save(ref Model.Prototype[] itemList) {
		Model.save(itemList);
	}

	void remove(Model.Prototype item) {
		Model.remove(item);
	}
	
	void remove(Model.Prototype[] itemList) {
		Model.remove(itemList);
	}

	///
	T convert(T)(Model.Prototype item) if(is(T==Json) || is(T==Bson)) {
		return Model.Descriptor.Convert!T(item);
	}
}

/**
 * Convert a string[string] array where the key is encoded as a 
 */
Type extractArray(string keyName, Type)(string[string] data) {
	Type array;

	template GetDeph( T ) {

		static if( isAssociativeArray!T ) {
			enum cnt = 1 + GetDeph!( ValueType!T );
		} else static if(!isSomeString!(T) && isArray!(T)) {
			enum cnt = 1 + GetDeph!(ArrayType!T);
		} else {
			enum cnt = 0;
		}

		alias GetDeph = cnt;
	}

	void item(T)(ref T data, string[] keyList, string value) {

		string[] list;
		if(keyList.length > 1) list = keyList[1..$];

		static if( isAssociativeArray!T ) {
			if(keyList[0] !in data) {
				ValueType!T tmp;
				data[ keyList[0] ] = tmp;
			}

			item!( ValueType!T )(data[keyList[0]], list, value);

		} else static if(!isSomeString!(T) && isArray!(T)) {
			auto index = keyList[0].to!ulong;

			if(data.length <= index) data.length = index + 1;

			item!( ArrayType!T )(data[ index ], list, value);

		} else {
			data = value;
		}
	}

	enum baseString = keyName ~ "[";
	enum ArrayTypeDeph = GetDeph!Type;

	foreach(key, value; data) {
		if(key.indexOf(baseString) == 0) {
			auto keyList = key.split("[");
			keyList = keyList[1..$];

			foreach(i;0..keyList.length) {

				assert(keyList[i][keyList[i].length - 1] == ']');
				keyList[i] = keyList[i][0..$-1];
			}

			if(keyList.length == ArrayTypeDeph) {
				item!Type(array, keyList, value);
			}
		}
	}
	
	return array;
}

unittest {
	//no item to split
	string[string] data;
	data["key"] = "test1";
	
	auto array = extractArray!("key", string[])(data);
	
	assert(array.length == 0);
}

unittest {
	//split array
	string[string] data;
	data["key[0]"] = "test1";
	data["key[1]"] = "test2";
	
	auto array = extractArray!("key", string[])(data);
	
	assert(array.length == 2);
	assert(array[0] == "test1");
	assert(array[1] == "test2");
}

unittest {
	//split assoc array
	string[string] data;
	data["item[key1]"] = "test1";
	data["item[key2]"] = "test2";
	
	auto array = extractArray!("item", string[string])(data);
	
	assert(array.length == 2);
	assert(array["key1"] == "test1");
	assert(array["key2"] == "test2");
}


unittest {
	//split assoc array
	string[string] data;
	data["item[key1][0]"] = "test10";
	data["item[key2][0]"] = "test20";
	data["item[key2][1]"] = "test21";
	
	auto array = extractArray!("item", string[][string])(data);
	
	//checks
	assert(array.length == 2);
	assert(array["key1"].length == 1);
	assert(array["key2"].length == 2);
	
	assert(array["key1"][0] == "test10");
	
	assert(array["key2"][0] == "test20");
	assert(array["key2"][1] == "test21");
	
}

unittest {
	string[string] data;
	data["item[1][key1][0]"] = "test";
	auto array = extractArray!("item", string[][string][])(data);
	
	//checks
	assert(array.length == 2);
	assert(array[1].length == 1);
	assert(array[1]["key1"].length == 1);
	
	assert(array[1]["key1"][0] == "test");
	
}
