/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 11 23, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.view.adminmenu;

import std.conv;
import crated.model.base;
public import crated.view.base;

class AdminMenuView : BaseView {

	shared static string dataUrls[string][string];

	override string toString() {
		useJqueryCDN();
		uses("adminmenu.css");
		uses("adminmenu.js");

		string content =  `
		<div class="topBar">
			<div class="menuButton outside"><span class="glyphicon glyphicon-asterisk" aria-hidden="true"></span></div>
			<div class="container">
				<div class="menuButton inside"><span class="glyphicon glyphicon-asterisk" aria-hidden="true"></span></div>
				<h1>`~title~`</h1>
			</div>
		</div>
		
		<div class="menu">`;

		foreach(category, list; dataUrls) {
			content ~= `<h2>`~category~`</h2><ul>`;

			auto sortedKeys = list.keys.sort;

			foreach(key; sortedKeys) {
				content ~= `<li><a href="`~list[key]~`">` ~ key ~ `</a></li>`;
			}

			content ~= `</ul>`;
		}

		content ~= `</div>`;


		return wrapWithBaseContainer(content ~ super.content);
	}

}

