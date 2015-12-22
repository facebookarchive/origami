---
title: Interactions
layout: documentation
css: /public/css/documentation.css
weight: 2
nav:
  prev:
    label: Layers
    path: ../Layers
  next:
    label: States
    path: ../States
---

Interaction patches pass information about user interactions (touches, swipes, key presses) in the viewer.

## Interaction patches
  <ul class="bulleted-list">
    <li>
      [Interaction 2 &rarr;](../../patches/Interaction-2) <span class="key letter inline">I</span>
      <br>
      This is the bread and butter of interaction in Origami. It can tell you when a user touches down, touches up, taps (a touch down and up in quick succession), and drags (a touch down that moves). It's optimized for mobile interactions (for desktop/web, use the built-in Interaction patch) and works with Origami Live.
      <br><br>
    </li>
    <li>
      [Scroll &rarr;](../../patches/Scroll)
      <br>
      This is another common interaction in Origami. It lets you scroll a Layer (center-anchored) with iOS style rubberbanding. All it needs to know is the size of the Image you are scrolling, and the type of scrolling you want (Free, Paging, or Wheel of Fortune). Also, see [Desktop Scroll &rarr;](../../patches/Desktop-Scroll)
      <br><br>
    <li>
      [Keyboard &rarr;](../../patches/Keyboard) <span class="key letter inline">K</span>
      <br>
      This shows whenever a key is pressed in the viewer. Use the patch inspector settings to set a specific key.
      <br><br>
    </li>
    <li>
      [Swipe &rarr;](../../patches/Swipe)
      <br>
      This helps you quickly prototype a two-state, swipeable interaction (think swiping a card up and down). Heavily used when designing Paper, it can be combined with Interaction 2 to toggle the state with taps in addition to swipes.
    </li>
  </ul>

## Interaction ports
One thing you'll notice with some interaction patches (Interaction 2, Scroll, Swipe) is they have an extra unlabeled port at the top right. That allows you to specify a specific layer to get interactions from, rather than global interactions. Just connect it to the interaction port at the top left of a Layer.

## Layer order/grouping affects touch detection
Once you've tied an interaction to a Layer, you will only get interactions if that Layer is the topmost layer at that position. Change layer order with the dropdown in the top-right of a Layer patch, or select the layer and hit <span class="key modifier inline">&#8984;</span><span class="key letter inline">[</span> or <span class="key modifier inline">&#8984;</span><span class="key letter inline">]</span>

Likewise, if you have Layers inside a Layer Group, you will only get interactions for the innermost/topmost Layer you are touching. To get interactions on a Layer Group, simply add Interaction 2 patches to each Layer within, and toggle the Enable port off.