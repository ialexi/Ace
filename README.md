There are two concept PSDs: Light and Dark. Dark doesn't receive as much attention, and it shows.

Ace Theme
=========
(from themes/ace/README.md)

The theme should already be generated. To actually regenerate the theme
(which you have to do if you are adjusting it), you need rmagick. To install 
rmagick, first install imagemagick (easiest way I know of is through MacPorts),
and then install the rmagick gem.

To generate the theme, you run the following from the theme folder:

	ruby generate_theme.rb ace.light

Right now, the ace.light argument is not used, but it is still a required argument.
Silly, I know, but supposedly we'll have differently-named themes at some point, so...

Sample Controls
===============
I have been rewriting the sample controls app. You can see a somewhat recent version here:

http://create.tpsitulsa.com/static/sample_controls/

Known issues/partially implemented controls:

- FormView has a bug that causes RadioViews to disappear if you visit, leave, and come back to them.
- No indeterminate progress bar design.
- No capsule buttons.
- No alternate control sizes.
- Some corners/edges appear weird (possible the path edges are not pixel-aligned)


There are many more completely unimplemented controls, but those are easier to notice than partially-implemented ones.



Build Tools
===========
I think if it were easier to really modify Ace and create all the sprites and such,
it would be improved more often. (Perhaps it is easily updated and I am missing how?)

The operation works inside the theme folder, and generates the "resources" folder used
by SproutCore. There are various options that can be seen by calling with the --help argument.

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
you need to perform slicing (do not talk to me about my nemesis, Photoshop slicing).

However, I do not want to parse CSS, so I use regular expressions.

Here is the current syntax:

	@view(view-name) .more-rules {
		/*
		 Input file, repeat, anchor, slice rect
		*/
		background: sprite("progress_view_track.png" repeat-x [12 1]);
		background: sprite("progress_view_track.png" anchor-right [-8])
		background: sprite("progress_view_track.png" anchor-right [1 1 5 1]) /* 1,1; size: 5, 1 */
	}

The build tools would just search for sprite(, and then parse the contents, and replace @view(view-name)
with .sc-view.view-name.theme.name (where theme.name is specified via an argument to the build tool).
Note: right now, it does not do anything with the theme name; this may change in future.

The syntax is:

	sprite(<sprite name> [<repeat method>] [clear] [<anchor method>] [<rect or partial rect>])
	
	Sprite name: 		the name of the image (quotes required only for images with spaces)
	
	Repeat Method:		repeat-x or repeat-y
	
	clear:				Whether to ensure there are no more images on the row after this one.
						Use with anchor-left to ensure a lonely item.
	
	Anchor Method:		anchor-left or anchor-right (forces the image to be on left or right side of image;
						see below)
						
	Partial Rectangle: 	\[ left [width] \]			// left can be positive or negative.
	Rectangle:		   	\[ left top width height \]

It is rather trivial to parse, yet also easy to read.

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

	