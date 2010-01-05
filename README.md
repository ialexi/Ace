There are two PSDs: Light and Dark.

Dark doesn't receive as much attention, and it shows.


Build Tools
===========
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

Here is a possible syntax:

	{
		/*
		 What is the bare minimum to specify? input file, repeat (if any), and slice rectangle
		*/
		background: sprite("progress_view_track.png" repeat-x [12 1]);
	}

The build tools would just search for sprite(, and then parse the contents.

The syntax is:

	sprite(<sprite name> [<repeat method>] [<rect or partial rect>])
	
	Sprite name: 		the name of the image (quotes required only for images with spaces)
	Partial Rectangle: 	\[ left [width] \]			// left can be positive or negative.
	Rectangle:		   	\[ left top width height \]

It should be rather trivial to parse, yet also easy to read.
