---
title: Layers
layout: documentation
css: /public/css/documentation.css
weight: 1
---

[Layers](../../patches/Layer) help draw to the viewer. They work like layers in Sketch and Photoshop: every layer has style attributes (e.g. position, size, an Image or Color to show...), can be different types (see list below), and can be layered on top of each other.

## Layer patches
  <ul class="bulleted-list">
    <li>
      [Layer &rarr;](../../patches/Text-Layer)
      <br>
      Display a rectangle or image. For non-rectangle shapes, use patches like Circle Image or Rounded Rectangle that create an image to plug into a Layer.
      <br><br>
    </li>
    <li>
      [Text Layer &rarr;](../../patches/Text-Layer)
      <br>
      Display text with adjustable font settings.
    <br><br>
    </li>
    <li>
      [Fill Layer &rarr;](../../patches/Text-Layer)
      <br>
      Completely fill the containing Layer Group with a color. Similar to paint bucket in Photoshop.
    </li>
  </ul>
## Layer position
Layers in Origami are positioned relative to the center of the viewer by default, where the center of the viewer is (x: 0, y: 0). You can change the Anchor Position from center to top left, but be aware most patches (like Scroll) expect Layers to remain centered.

<div class="coord-example">
  <div class="dot dot-center dot-center-y dot-center-x"></div>
  <div class="label dot-center dot-center-y dot-center-x">0, 0</div>

  <div class="dot dot-top-right dot-top dot-right"></div>
  <div class="label dot-top-right dot-top dot-right">150, 200</div>

  <div class="dot dot-bottom-left dot-bottom dot-left"></div>
  <div class="label dot-bottom-left dot-bottom dot-left">-150, -200</div>
</div>

X Position behaves like Sketch/Photoshop, where increasing it moves right, and decreasing moves left. Y Position, however, behaves differently: increasing it moves up, and decreasing moves down.

Read the [Coordinates concept](../../concepts/Coordinates) for more.

## Layer order
Unlike the other attributes of a Layer, the order is determined with a dropdown at the top right of the Patch (instead of with an input). To dynamically change the order of a Layer, simply tweak the Z Position by a fraction (e.g. +/-0.0001).

## Layer Groups
[Layer Groups](../../patches/Layer-Group) help you organize your Layers together. You can double-click (or &#8984; + &darr;) to get into a Layer Group, and click "Edit Parent" in the toolbar (or &#8984; + &uarr;) to exit a Layer Group.

<br>

Read the [Layer patch documentation](../../patches/Layer) for more.