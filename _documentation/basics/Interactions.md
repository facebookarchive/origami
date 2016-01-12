---
title: Interactions
layout: documentation
css: /public/css/documentation.css
weight: 2
nav:
  prev:
    label: Layers
    path: Layers
  next:
    label: States
    path: States
---

Interaction patches give you information about user interactions like touches, clicks, swipes, and key presses in the viewer.

## Interaction patches
  <ul class="bulleted-list">
    <li>
      [Interaction 2 &rarr;](../patches/Interaction-2.html) <span class="key letter inline">I</span>
      <br>
      This is the bread and butter of interaction in Origami. It can tell you when a user touches down, touches up, taps (a touch down and up in quick succession), and drags (a touch down that moves). It works well with Layer Groups.
      <br><br>
    </li>
    <li>
      [Scroll &rarr;](../patches/Scroll.html)
      <br>
      Lets you scroll a Layer (center-anchored) with momentum and rubberbanding. All it needs to know is the size of the Image you are scrolling, and the type of scrolling you want (Free, Paging, or Wheel of Fortune). Also, see [Desktop Scroll &rarr;](../patches/Desktop-Scroll.html)
      <br><br>
    <li>
      [Swipe &rarr;](../patches/Swipe.html)
      <br>
      This helps you quickly prototype swiping a layer between two positions. Some examples of UIs you can build with this: swiping down to close a dialog, pull-to-refresh, swiping up to reveal a list of options (like 3D Touch Peek and Pop), swiping right to go back, and swiping horizontally to switch between a camera's photo and video modes.
      <br><br>
    </li>
    <li>
      [Keyboard &rarr;](../patches/Keyboard.html) <span class="key letter inline">K</span>
      <br>
      Lets you know when a specific key on your Mac's keyboard is pressed in the viewer. For mobile prototypes, this lets you set up hot keys that configure your prototype into specific states for easy demoing. Assign it to a key using the settings inspector, or by hovering over the patch and pressing a key on your keyboard.
    </li>
  </ul>

## Interaction ports
One thing you'll notice with some interaction patches (Interaction 2, Scroll, Swipe) is they have an extra unlabeled port at the top right. That allows you to specify a specific layer to get interactions from, rather than anywhere on screen. Just connect it to the interaction port at the top left of a Layer.

## Layer order and grouping affects touch detection
Once you've tied an interaction to a Layer, you will only get interactions if that Layer is the front-most layer at that position. Change layer order with the dropdown in the top-right of a Layer patch, or select the layer and hit <span class="key modifier inline">&#8984;</span><span class="key letter inline">[</span> or <span class="key modifier inline">&#8984;</span><span class="key letter inline">]</span>.

Likewise, if you have Layers inside a Layer Group, you will only get interactions for the front-most Layer you are touching. To get interactions on an entire Layer Group itself, simply add Interaction 2 patches to each Layer within, and toggle their Enable ports off. This tells Origami that you don't want those layers to be interactive.