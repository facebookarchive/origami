---
title: Layers
layout: documentation
css: /public/css/documentation.css
weight: 1
nav:
  prev:
    label: Introduction
    path: ../index
  next:
    label: Interactions
    path: Interactions
---

[Layers](../patches/Layer.html) show content, like images, in the viewer. They work like layers in Sketch and Photoshop: every layer has style attributes (e.g. position, size, an Image or Color to show...), can be different types (see list below), and can be layered on top of each other.

Add a layer with the patch library <span class="key modifier inline">&#8984;</span><span class="key letter inline">&#9166;</span>, or their [keyboard shortcuts](../workflow/KeyboardShortcuts.html). Quickly add an image as a layer by dragging and dropping the image on to the Editor.

## Layer patches
  <ul class="bulleted-list">
    <li>
      [Layer &rarr;](../patches/Layer.html) <span class="key letter inline">L</span>
      <br>
      Display a rectangle or image. For non-rectangle shapes, use patches like Circle Image or Rounded Rectangle that create an image to plug into a Layer.
      <br><br>
      In most situations, you'll be working with an image from your designs by copy-pasting or drag-and-dropping into the editor. This will automatically create a layer patch for you with the image connected.
    </li>
    <li>
      [Text Layer &rarr;](../patches/Text-Layer.html) <span class="key modifier inline">&#8679;</span><span class="key letter inline">T</span>
      <br>
      Display text with adjustable font settings.
    </li>
    <li>
      [Fill Layer &rarr;](../patches/Fill-Layer.html)
      <br>
      Completely fill the containing Layer Group with a color.
    </li>
  </ul>
## Layer position
Layers in Origami are positioned in the center by default. You can easily position the layer in different corners of the layer group by changing the Anchor Position. Be aware that some patches (like Scroll) expect Layers to have a center anchor position.

<div class="coord-example">
  <div class="dot dot-center dot-center-y dot-center-x"></div>
  <div class="label dot-center dot-center-y dot-center-x">0, 0</div>

  <div class="dot dot-top-right dot-top dot-right"></div>
  <div class="label dot-top-right dot-top dot-right">150, 200</div>

  <div class="dot dot-bottom-left dot-bottom dot-left"></div>
  <div class="label dot-bottom-left dot-bottom dot-left">-150, -200</div>
</div>

X Position behaves like Sketch and Photoshop, where increasing it moves right, and decreasing moves left. Y Position is reversed: increasing it moves up, and decreasing moves down.

Read more about the [Coordinate System](../concepts/Coordinates.html).

## Layer order
Unlike the other attributes of a Layer, the order is specified with a dropdown at the top right of the Patch. You can also change the order by selecting the layer and hitting <span class="key modifier inline">&#8984;</span><span class="key letter inline">[</span> or <span class="key modifier inline">&#8984;</span><span class="key letter inline">]</span>.

To change the order of a Layer using patches, simply tweak the Z Position by a small amount (like 0.0001 pixels).

## Layer Groups
[Layer Groups](../patches/Layer-Group.html) help you organize your Layers together. Create one from the patch library or simply hit <span class="key letter inline">G</span> (tip: you can do this while hovered over an image patch to quickly group it). You can double-click or <span class="key modifier inline">&#8984;</span><span class="key letter inline">&#9660;</span> to get into a Layer Group, and click **Edit Parent** in the toolbar or <span class="key modifier inline">&#8984;</span><span class="key letter inline">&#9650;</span> to exit a Layer Group.

Make sure to group layers whenever you want to animate multiple layers together. For example, if you're sliding up a window with multiple layers inside of it, putting those layers in a layer group will let you just animate up that one group up instead of needing to have cables connected to several different layers. 