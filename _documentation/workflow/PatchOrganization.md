---
title: Patch Organization
layout: documentation
css: /public/css/documentation.css
weight: 4
---

It's easy to get lost in all the crossing cables. Here are some tips to help you organize your document.

## Adding notes/renaming patches
As your compositions get more complicated, you may have problems understanding patches you've placed previously. Prevent this by grouping related patches into Macros, and naming them appropriately or adding a note.

Easily rename a patch by selecting it and pressing Enter/Return. Explain what the patch does, e.g. instead of "Conditional", use something more descriptive like "If scroll is at top".

Add a node by right-clicking on the document and hitting "Add Note...".

## Organize patches left to right
Since patches take inputs from the left and output to the right, it makes sense to order them from left to right. Generally purple/black patches on the right, and blue patches always on the right (since they never have outputs).

Organizing all Layers so they are vertically stacked in their Layer order will help make the document more readable. Use &#8984; + &larr; or &#8984; + &rarr; to easily left/right align patches.

## Group related Layers to reduce cable clutter
Use [Layer Groups](../../patches/Layer-Group) to hold multiple Layers that move, scale, or rotate together. A great example is a News Feed with multiple feed stories. Instead of having a Scroll patch Y Position connected to 5 different stories, move all the Layers into a Layer Group, and connect the Scroll patch directly to the Layer Group's Layer.

Note of [performance](../Performance): One thing to watch out for, especially with the Origami Live app, is using too many Layer Groups can cause performance issues. The larger a Layer Group, the more rendering cost there is for each frame.

## Wireless patches to minimize cables
An easy way to avoid cable mess is to use [Wireless Receiver](../../patches/Wireless-Receiver) and [Wireless Broadcaster](../../patches/Wireless-Broadcaster). A Broadcaster will make a value available anywhere in the same document. A Receiver can receive any value from any Broadcaster.

Create a Broadcaster by pressing 'w' while hovering on an output, or on a blank space in the document. A Broadcaster made from an output will automatically inherit the type, whereas a Broadcaster on a blank space will default to Virtual (which means you need to manually change it to a different type with Patch Settings (&#8984; + 2) if you want to assign it a value directly).

Create a Receivers by pressing 'w' while hovering on an input. It will automatically be connected to the last-placed Wireless Broadcaster (however the name may not be reflected until you deselect the Receiver). You can change the Broadcaster in the Patch Settings (&#8984; + 2) in the dropdown.

## Macros to hide complex logic
Similarly to grouping Layers, you can use **Create Macro** in the toolbar to group purple provider/black processor patches. Generally you should group logic that is related to each other, e.g. "Scroll Speed Detector". You can make Macros within Macros as well.

Often when you group, the labels of the ports are unhelpful and generic. Rename the ports by selecting the Macro and pressing &#8984; + 3 to access **Input & Output Settings**. Double-click on a port to rename.

Sometimes you may have a Macro that you keep using over and over again. In these cases it may make sense to add it to your **Patch Library**. Once you've made a Macro, go into the Macro, select all the patches and hit Add to Library. Fill in the information (the patch preview will show incorrect names for the inputs/outputs at first). Once you've added it, you can re-use it anywhere &mdash; even share it with teammates.

## Publishing inputs/outputs 
With Layer Groups and Macros, it maybe confusing at first how to pass cables inside/outside. You can publish inputs/outputs up a level by right-clicking on a patch and selecting the port you want to publish.

However, right-clicking does not work to send inputs **from the outside** into a Layer Group/Macro. Instead, you can drag any cable onto a Layer Group/Macro, and it will automatically create a splitter within that is published with the name you enter.

You can reorder the ports on a Layer Group/Macro by accessing Input & Output Settings (select the patch, &#8984; + 3). Drag the port names to reorder.

