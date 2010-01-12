There are two PSDs: Light and Dark.

Dark doesn't receive as much attention, and it shows.

Build Tools
===========
**Current Test**: controls/progress/progress_view

I think if it were easier to really modify Ace and create all the sprites and such,
it would be improved more often. (Perhaps it is easily updated and I am missing how?)

A build tool which does not yet exist (but which maybe I can create with Ruby and
some library; RMagick, perhaps?) would be run using a command, or possibly as part
of SproutCore's own build tools.

The operation would work on a single "theme folder", and create one CSS file and a
handful of image files out of all of the individual CSS and image files.

The theme packaging operation is recursive (much like SproutCore's build tools), so
any folder depth may be used. The suggested folder layout is this:

* Theme Folder
	* View Category Folders (controls, containers, etc.)
		* Views (button\_view, progress\_view, etc.)
			* 1 CSS file
			* 0+ images (PSDs, usually)

Each CSS file will reference images relative to itself. So, controls/progress\_view/progress_view.css
could reference "progress\_view.png".

CSS Syntax
----------
Normal CSS won't work too well for accessing Sprites. It will work even less when
you need to perform slicing (do not talk to me about Photoshop slicing).

However, I do not want to parse CSS.

Here is the current syntax:

	@view(view-name) .more-rules {
		/*
		 Input file, repeat, anchor, slice rect
		*/
		background: sprite("progress_view_track.png" repeat-x [12 1]);
		background: sprite("progress_view_track.png" anchor-right [-8])
	}

The build tools would just search for sprite(, and then parse the contents, and replace @view(view-name)
with .sc-view.view-name.theme.name (where theme.name is specified via an argument to the build tool).

The syntax is:

	sprite(<sprite name> [<repeat method>] [<anchor method>] [<rect or partial rect>])
	
	Sprite name: 		the name of the image (quotes required only for images with spaces)
	
	Repeat Method:		repeat-x or repeat-y
	
	Anchor Method:		anchor-left or anchor-right (forces the image to be on left or right side of image;
						see below)
						
	Partial Rectangle: 	\[ left [width] \]			// left can be positive or negative.
	Rectangle:		   	\[ left top width height \]

It should be rather trivial to parse, yet also easy to read.

Anchoring
---------
Anchoring an image to the left or right side allows you to effectively create controls that have left,
right, and middle parts. Such controls are usually easy to make, but not if the control can shrink to
0px (like ProgressView).

For ProgressView, the control is created like this:

container w/left portion
	inner-head with right portion: anchor-right, left: 8, right: 0
		The left:8 right:0 allows it to never overlap the left edge.
	inner-tail with middle portion: left: 8, right: 8
		Writes over any junk that comes before the right-anchored part.

	