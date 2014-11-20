﻿/**
 * Basic view tools
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.base;



class BaseView {
	/**
	 * Parse a dh file
	 */
	string parseDhContent(string content) {
		string code;
		
		bool parsingCode = false;
		ulong textPos = 0;
		ulong codePos = 0;
		
		foreach(i; 0..content.length) {
			
			//looking for code start
			if(content.length-1 > i && content[i] == '<' && content[i+1] == '?') {
				//append the discovered code
				code ~= "write(`" ~ content[textPos..i] ~ "`);";
				
				parsingCode = true;
				codePos = i+2;
			}
			
			//looking for code end
			if(content.length-1 > i && content[i] == '?' && content[i+1] == '>') {
				code ~= content[codePos..i];
				
				parsingCode = false;
				textPos = i+2;
			}
		}
		
		if(!parsingCode) code ~= "write(`" ~ content[textPos..$] ~ "`);";
		else code ~= content[codePos..$];
		
		
		return code;
	}
	
	
	/**
	 * Render a dh file 
	 */
	string renderDh(string file, T)(T data, string url = "") {
		import std.stdio;
		
		//store the stdout file
		auto tmpStdout = stdout;
		stdout = File.tmpfile();
		
		//process the template
		mixin(parseDhContent(import(file)));
		
		string result;	
		
		stdout.rewind();
		auto range = stdout.byLine();
		foreach (line; range)
			result ~= line;
		
		//restore the stdout file
		stdout = tmpStdout;
		
		return result;
	}

}


