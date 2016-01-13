---
title: Device Preview
layout: documentation
css: /public/css/documentation.css
weight: 1
nav:
  prev:
    label: Sketch Import
    path: SketchImport
  next:
    label: Keyboard Shortcuts
    path: KeyboardShortcuts
---

<a class="action-button" href="http://itunes.apple.com/app/id942636206" target="_blank">Download Origami Live</a>

You can try your prototypes on your iPhone or iPad over USB with [Origami Live](http://itunes.apple.com/app/id942636206) &mdash; currently iOS only.

## Using Origami Live
After downloading Origami Live from the App Store, simply open Quartz Composer, plug in your device to your computer, and then open Origami Live. Your current prototype will automatically show up, and you can immediately interact with the prototype. You can even use your prototype while adjusting it in Quartz Composer.

## Troubleshooting
Sometimes the Origami Live may not reflect the composition you want, or any composition at all. In these situations:

<ul class="bulleted-list">
	<li>Make sure you are using the supported Origami Layer patches (Sprites, Billboards and other non-Origami blue consumer patches are not supported).</li>
	<li>Make sure you've placed all your patches/Layers inside the main Layer Group connected to the Viewer patch.</li>
	<li>Only have a single document open at a time.</li>
	<li>Force quit/restart Origami Live and Quartz Composer.</li>
</ul>

## Performance

Origami Live can run your prototypes at 60 fps by sending images from Quartz Composer on the Mac to the device only when necessary. If the images aren't frequently changing, Origami only needs to send small bits of information over USB every frame, like the positions of layers that are currently moving for example.

Some tips to get your prototypes running faster:

<ul class="bulleted-list">
	<li>Make sure the Image outputs of your Layer Groups are directly connected to Layer patches (or the Viewer patch). Passing the image of a Layer Group through another patch (like Gaussian Blur) will make it so every time that image changes - either by changing the blur or by making any change to any layer inside the group - will cause it to send a new image to the device. You can try to fake a blur animation by fading a blurred layer on top of the non-blurred one.</li>
	<li>Inline Values are helpful when you're building your prototype, but take a lot of processing power that would otherwise be used to speed up Origami Live. You can toggle Inline Values on and off in the Origami menu.</li>
	<li>Avoid using the Enable port on Layers. Each time a layer is enabled, the list of layers gets regenerated on the device which can take some time. Use the Opacity port to hide and show layers instead.</li>
	<li>Avoid animating the Color port on Layers.</li>
</ul>