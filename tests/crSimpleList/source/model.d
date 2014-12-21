﻿/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module model;

import crated.model.calendar;
import crated.model.base;

import tests.descriptor;
import tests.model;

import prototypes.book;
import prototypes.events;


//Test the event model descriptor
alias EventsModel = Model!EventDescriptor;
mixin ModelDescriptorTest!EventsModel;


//Test the book prototype using the default model
alias BookModel = Model!BookDescriptor;
mixin BasicModelTest!BookModel;