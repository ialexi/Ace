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


Growing Todo List:

- SliderView
- List Views
	- bg color for selected items—currently is gray, should probably be blue
	- Anything special needed to make icons, checkboxes, unread count or whatever indicator show up properly?
- Grid View? (doesn't appear to have much of a style at the moment—should that be changed?)
- Disclosure Buttons
- Capsule buttons
- Indeterminate progress bar
	- May be impossible to do with rounded corners unless pattern fades at edges
- SegmentedView
	- Start with PSDs for Button; they should use very similar (if not the same) styles.
- WellView
- PickerPane, especially PickerPane.pointer
- AlertPane
	- Set up icons (redesign some for new Ace?)
- Alternate control sizes? (I'm not sure what the alternate sizes are supposed to be at the moment)
- Checkbox corners look rough; can this be fixed?
- Progress bar tracks are too dark
- Selected style for menu items (for instance, in SelectView)
- Testing of buttons, radio buttons, and checkboxes with icons

Optional goodies:

- Revise ButtonView so it will have the option of creating true three-part buttons
  where the PIECES DON'T OVERLAP!!! This would allow semitransparent borders, which
  would help buttons work on a variety of backgrounds.
- Make things use semitransparent borders (see above); test on many backgrounds.

Needing Discussion:

- Icons. Keep same? Make sedate? Some of each?

There may be other things too...

Build Tools
===========
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

	