/**
 * Manage models easily
 * 
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: November 3, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module crated.controller.datamanager;

import crated.view.adminmenu;

import crated.controller.base;
import crated.controller.admin;
import vibe.d;

template DataManager(string baseUrl, EL...)
{

	class DataManagerTemplate  {

		/**
		 * Init the router
		 */
		void addOtherRoutes(ref URLRouter router) {

			void addModelRoutes(Models...)() {

				static if(Models.length == 1) {

					AdminMenuView.dataUrls["Models"][Models[0].name] = baseUrl ~ "/" ~ Models[0].name;

					alias T = Controller!(AdminController!(baseUrl ~ "/" ~ Models[0].name, Models[0], AdminMenuView));

					auto admin = new T;

					admin.addRoutes(router);

				} else if(Models.length > 1) {
					addModelRoutes!(EL[0..$/2]);
					addModelRoutes!(EL[$/2..$]);
				}
			}

			addModelRoutes!EL;
		}
	}

	alias DataManager = DataManagerTemplate;
}

