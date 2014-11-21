/**
 * Basic view tools
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.base;

import crated.settings;

class BaseView {

	private string[] cssFiles;
	private string[] jsFiles;

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

	void useBootstrapCssCDN() {
		cssFiles ~= [ BootstrapCssCDN ];
	}

	string html5Container(string content) {

		string page = `<!DOCTYPE html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <title></title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">`;

		foreach(i;0..cssFiles.length) {
			page ~= "\n\t<link rel='stylesheet' href='" ~ cssFiles[i] ~ "'>";
		}
	
	page~=`
</head>
<body>
	` ~ content;

		foreach(i;0..jsFiles.length) {
			page ~= "\n\t<script src='" ~ jsFiles[i] ~ "'></script>";
		}

	page ~= `
</body>
</html>`;



		return page;
	}

}


