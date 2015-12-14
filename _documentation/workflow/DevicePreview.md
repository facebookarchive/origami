---
title: Device Preview
layout: documentation
css: /public/css/documentation.css
weight: 1
---

You can try your prototypes on your device over USB with [Origami Live](http://itunes.apple.com/app/id942636206) — currently iOS only.

## Using Origami Live
After downloading Origami Live from the app store, simply open Quartz Composer, plug in your device to your computer with USB, and then open Origami Live. Your current prototype will automatically show up, and you can immediately interact with the prototype.

## Troubleshooting
Sometimes the Origami Live may not reflect the composition you want, or any composition at all. In these situations:

<ul class="bulleted-list">
	<li>Make sure you are using the supported Origami Layer patches (Sprites, Billboards and other non Origami blue consumer patches are not supported).</li>
	<li>Make sure you've placed all your patches/Layers inside the main Layer Group connected to the Viewer patch.</li>
	<li>Make sure you've selected the device from the correct Viewer window if you have multiple open.</li>
	<li>Force quit/restart Origami Live.</li>
</ul>

## Performance
At its core, Origami and Quartz Composer are based around prototyping via moving, transforming, and creating images. Origami Live mirrors those images onto the device and caches them heavily, but sometimes due to large image size or intensive operations (e.g. any time you change something inside a Layer Group, the whole Layer Group re-renders), the performance may suffer.