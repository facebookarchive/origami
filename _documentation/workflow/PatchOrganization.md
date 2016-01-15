---
title: Patch Organization
layout: documentation
css: /public/css/documentation.css
weight: 3
nav:
  prev:
    label: Keyboard Shortcuts
    path: KeyboardShortcuts
  next:
    label: Performance
    path: Performance
---

It's easy to get lost in all the crossing cables. Here are some tips to help you organize your document.

## Name patches
You can give any patch a custom name by double clicking the title or selecting the patch and pressing <span class="key letter inline">&#9166;</span>. It's often helpful to give patches names that describe what they're doing in the context of your prototype. For example, if you had a Switch patch responsible for switching a photo between a thumbnail (off) and full screen state (on), you could name the Switch "Photo is Fullscreen". It would be clear immediately what that chain of patches is responsible for and what the on state of the Switch represents.

## Create notes

Notes can be useful to describe what sections of patches are responsible for in your prototype. Add a node by right-clicking on the document and selecting **Add Note...**.

## Organize patches left to right
Since patches take inputs from the left and output to the right, it makes sense to arrange them from left to right. Generally blue patches always on the right, since they don't have outputs.

Organizing all Layers so they are vertically stacked in their Layer order will help make the document more readable. Use <span class="key modifier inline">&#8984;</span><span class="key letter inline">&#9664;</span> or <span class="key modifier inline">&#8984;</span><span class="key letter inline">&#9654;</span> to align patches arranged in a column.

## Group related Layers to reduce cable clutter
Use [Layer Groups](../patches/Layer-Group.html) to hold multiple Layers that animate together. For example, if you're sliding up a window with multiple layers inside of it, putting those layers in a layer group will let you just animate up that one group up instead of needing to have cables connected to several different layers.

## Use wireless patches to broadcast common values

[Wireless Broadcaster](../patches/Wireless-Broadcaster.html) and [Wireless Receiver](../patches/Wireless-Receiver.html) can send values across your composition without the use of cables. A Broadcaster will make a value available anywhere in the same document. A Receiver can receive a value from any Broadcaster.

There are a couple types of values that are particularly useful to broadcast:
<ul class="bulleted-list">
<li>**Static values** used in different places across your prototype. For example, say you had a padding value that you used to lay out a bunch of different parts of your UI. You'd just need to change one broadcaster and the different elements of your prototype would adjust accordingly.</li>
<li>**State values** from patches like Switch, Index Switch, Counter, Conditional, etc. It's common to use the same state value in several different places in your composition - so it's often helpful to name it through the wireless system and have access to it anywhere on the graph.</li>

Create a Broadcaster by pressing <span class="key letter inline">W</span> while hovering on an output, or on a blank space in the document. A Broadcaster made from an output will automatically inherit the type, whereas a Broadcaster on a blank space will default to Virtual (which means you need to manually change it to a different type with Patch Settings <span class="key modifier inline">&#8984;</span><span class="key letter inline">2</span> if you want to assign it a value directly).

Create a Receiver by pressing <span class="key letter inline">W</span> while hovering on an input. It will automatically be connected to the last-placed Wireless Broadcaster (however the name may not be reflected until you deselect the Receiver). You can change the Broadcaster in the **Patch Settings** <span class="key modifier inline">&#8984;</span><span class="key letter inline">2</span> in the dropdown.

## Macros to hide complex logic
Similarly to grouping Layers, you can use **Create Macro** to create bundles of logic. Generally you should group logic that when combined has an easily described purpose, for example "Scroll Speed Detector". You can make Macros within Macros as well.

Often when you group, the labels of the ports are unhelpful and generic. Rename the ports by selecting the Macro and pressing <span class="key modifier inline">&#8984;</span><span class="key letter inline">3</span> to access **Input & Output Settings**. Double-click on a port to rename.

Sometimes you may have a Macro that you keep using over and over again. In these cases it may make sense to add it to your **Patch Library**. Once you've made a Macro, go into the Macro, select all the patches and hit **Add to Library**. Fill in the information (the patch preview will show incorrect names for the inputs/outputs at first). Once you've added it, you can re-use it anywhere &mdash; even share it with teammates.

## Publishing inputs and outputs 
With Layer Groups and Macros, it maybe confusing at first how to send values in or out of the group. You can publish inputs/outputs up a level by right-clicking on a patch and selecting the port you want to publish, or by hovering on a port and pressing <span class="key letter inline">P</span>.

However, right-clicking does not work to send inputs **from the outside** into a Layer Group/Macro. Instead, you can drag any cable onto a Layer Group/Macro, and it will automatically create a splitter within that is published with the name you enter.

You can reorder and rename the ports on a Layer Group/Macro by accessing **Input & Output Settings** (select the patch, <span class="key modifier inline">&#8984;</span><span class="key letter inline">3</span>). Drag the port names to reorder.

