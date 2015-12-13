---
title: Sketch Import
layout: documentation
css: /public/css/documentation.css
weight: 0
---

New in Origami 2.1, you can now import a file from Sketch to start prototyping in seconds. Just hit **File > Import Sketch File...** and it will import the currently open Sketch document and place all the Layers in the correct, center-anchored position in the appropriate Layer Groups (supports multiple Artboards as well).

Watch the [Sketch + Origami tutorial](../../tutorials) for a detailed walkthrough (at the bottom).

## Updating an imported document
The import will place each image as a Live Image, which means that any updates to an asset will be reflected immediately. This is handy if you are tweaking copy, images, or appearances.

To update the assets, simply run the [Export for Origami](https://github.com/tarngerine/sketch-origami-export/archive/master.zip) plugin from Sketch that was available prior to 2.1. It will not update positions/layer hierarchies.

## Limitations
Sketch import is meant for the initial transition into Origami. It will not update positions/layer hierarchies. Each time you run Import Sketch File it will create a new file. Use the plugin mentioned above to update layer images.