/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 12 21, 2014
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module source.model;

import crated.model.calendar;
import crated.model.base;

import source.tests.descriptor;
import source.tests.model;

import source.prototypes.book;
import source.prototypes.events;


//Test the event model descriptor
alias EventsModel = Model!EventDescriptor;
mixin ModelDescriptorTest!EventsModel;


//Test the book prototype using the default model
alias BookModel = Model!BookDescriptor;
mixin BasicModelTest!BookModel;