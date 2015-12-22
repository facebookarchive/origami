---
title: Performance
layout: documentation
css: /public/css/documentation.css
weight: 4
nav:
  prev:
    label: Patch Organization
    path: ../PatchOrganization
  next:
    label: Code Export
    path: ../CodeExport
---

One of the problems you may run into often is lag. Quartz Composer is a heavyweight application that depends on transforming and creating images on a frame-by-frame basis, and may not run at full speed all the time. These are a few tips to help.

## Simple Editor and Viewer tweaks
The fastest way to boost performance is to disable Inline Value preview. You can easily toggle it off from the **Origami bird menu > Display Inline Values** <span class="key modifier inline">&#8984;</span><span class="key modifier inline">&#8997;</span><span class="key modifier inline">&#8963;</span><span class="key letter inline">V</span>.

You can also put a limit on the frames per second (FPS) of the Viewer in **Preferences > Viewer**. 30FPS is reasonable for most prototypes.

## Rendering load minimization
At a technical level, QC/Origami is the display and animation of images. Every time you update a Layer, QC renders it with the appropriate attributes (color, position, etc), which in turn requires the parent Layer Group to update with the newly updated Layer(s) within. Minimizing the amount of rendering QC does will provide a huge performance boost in the Viewer and Origami Live.

The two main ways to do this are:

  <ul class="bulleted-list">
    <li>
      **Toggling Layers**
      <br>
      Toggling the Enable port on a Layer will cause it to not be displayed in the Viewer/Origami Live. This is handy for when a Layer is off the screen. Due to the way QC optimizes patches to only run if they are connected to an enabled blue consumer patch, this will also disable all the patches that are connected to it (unless they are connected to another Layer), including Layer Groups, which gives a performance boost.
      <br><br>
      Tip: Use a [Delay](../../patches/Delay) patch connected to Enable (with Delay Decreasing) to delay the disabling of a Layer if you are animating it off the screen.
      <br><br>
    </li>
    <li>
      **Toggling "Render" on Layer Groups**
      <br>
      This will freeze all updates within the Layer Group, including any Interactions. Toggle it when you are sure a Layer Group will not be updated (e.g. disabling Layer Groups inside a tab that isn't active, and enabling it when the parent tab is active).
      <br><br>
      Tip: Make sure Layer Groups are as small as possible. By default, Layer Groups created are the same size as the total canvas size. However, if you are only utilizing a small portion of the Layer Group, it may make sense to reduce the Layer Group size to the smallest it can be.
    </li>
  </ul>

