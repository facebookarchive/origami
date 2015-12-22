---
title: Coordinates
layout: documentation
css: /public/css/documentation.css
weight: 1
nav:
  prev:
    label: Code Export
    path: ../workflow/CodeExport
  next:
    label: Progress Values
    path: Progress
---

In contrast to built-in Quartz Composer patches, the Origami patches (eg. Layer / Text Layer / Layer Group) use pixel coordinates.

The origin, or location of the (x = 0, y = 0) coordinate, is in the center of the device screen. Coordinates increase upwards and to the right. Points downward and leftward of the center have negative coordinates.

For illustration, below is a Layer Group of height 400 pixels and width 300 pixels:

<div class="coord-example">
	<div class="dot dot-center dot-center-y dot-center-x"></div>
	<div class="label dot-center dot-center-y dot-center-x">0, 0</div>

	<div class="dot dot-top-right dot-top dot-right"></div>
	<div class="label dot-top-right dot-top dot-right">150, 200</div>

	<div class="dot dot-bottom-left dot-bottom dot-left"></div>
	<div class="label dot-bottom-left dot-bottom dot-left">-150, -200</div>

</div>

## Anchor Point

Some patches take an _Anchor Point_ input. This input changes the origin of the coordinate system, but only for that patch.

<div class="coord-example">
	<div class="dot dot-top-left dot-top dot-left"></div>
	<div class="label dot-top-left dot-top dot-left">Top Left</div>

	<div class="dot dot-top-center dot-top dot-center-x"></div>
	<div class="label dot-top-center dot-top dot-center-x">Top Center</div>

	<div class="dot dot-top-right dot-top dot-right"></div>
	<div class="label dot-top-right dot-top dot-right">Top Right</div>

	<div class="dot dot-center-left dot-center-y dot-left"></div>
	<div class="label dot-center-left dot-center-y dot-left">Center Left</div>

	<div class="dot dot-center dot-center-y dot-center-x"></div>
	<div class="label dot-center dot-center-y dot-center-x">Center</div>

	<div class="dot dot-center-right dot-center-y dot-right"></div>
	<div class="label dot-center-right dot-center-y dot-right">Center Right</div>

	<div class="dot dot-bottom-left dot-bottom dot-left"></div>
	<div class="label dot-bottom-left dot-bottom dot-left">Bottom Left</div>

	<div class="dot dot-bottom-center dot-bottom dot-center-x"></div>
	<div class="label dot-bottom-center dot-bottom dot-center-x">Bottom Center</div>

	<div class="dot dot-bottom-right dot-bottom dot-right"></div>
	<div class="label dot-bottom-right dot-bottom dot-right">Bottom Right</div>
</div>

Here's an example of a Text Layer positioned from the "Top Left" Anchor Point:

<div class="coord-example">
	<div class="dot dot-top-left dot-top dot-left"></div>
	<div class="box dot-top-left dot-top dot-left">Button Text</div>
</div>

From the bottom right:

<div class="coord-example">
	<div class="dot dot-bottom-right dot-bottom dot-right"></div>
	<div class="box dot-bottom-right dot-bottom dot-right">Button Text</div>
</div>

Notice that if you position a Layer by its Bottom Right, it positions its right edge to the right of the screen and bottom edge to the bottom of the screen, not its center. This makes it convenient to quickly move a layer to a corner of the screen, or position it within its parent.

If you want to inset it left by 40 pixels and up by 40 pixels, give it an X Position of -40 and a Y Position of 40.

<div class="coord-example">
	<div class="dot dot-bottom-right dot-bottom dot-right"></div>
	<div class="box inset-40 dot-bottom-right dot-bottom dot-right">Button Text</div>
	<div class="label dot-bottom-right dot-bottom dot-right">-40, 40</div>
</div>



