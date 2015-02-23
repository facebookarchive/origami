---
title: Layer Hierarchy
layout: documentation
css: /public/css/documentation.css
weight: 350
---

Layers are a special kind of patch that draws content to the screen. Layers show up only in the Layer List sidebar.

<h2 class="studio">Sub-Layers</h2>

Layers can now have sub-layers without making a macro patch. This allows you to easily see your Layer hierarchy without having to peek inside a bunch of macros.

<h2 class="studio">Layer Bindings</h2>

 To connect a value to a layer, a Layer Binding patch is created with the name of the layer and a single input port that writes a value to that port.

 If a property, such as Position, has multiple coordinates, you can bind a different layer binding to each of X or Y coordinates by clicking on the X or Y label on the port. If you want to set both X and Y together (with the output of a patch of type Point), click on the name ie Position.

## Ports

Layers have input Ports like regular patches. The values of these input ports determine the appearance of the Layer on screen.
