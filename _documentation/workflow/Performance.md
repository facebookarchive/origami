---
title: Performance
layout: documentation
css: /public/css/documentation.css
weight: 4
nav:
  prev:
    label: Patch Organization
    path: PatchOrganization
  next:
    label: Code Export
    path: CodeExport
---

Here are some tips for improving the performance of your prototypes.

## Origami for Mac

<ul class="bulleted-list">
  <li>
    Inline Values are helpful when you're building your prototypes, but take a lot of processing power that would otherwise be used to speed up Origami and Origami Live. You can toggle Inline Values on and off in the Origami menu. It's best to turn them off if you're recording a video or giving a demo of your prototype. Quickly toggle it on and off with the keyboard shortcut <span class="key modifier inline">&#8984;</span><span class="key modifier inline">&#8997;</span><span class="key modifier inline">&#8963;</span><span class="key letter inline">V</span>.
  </li>
  <li>
    Avoid animating certain graphically intensive patches. Some patches, like Disc Blur for example, can produce nice effects but take a lot of computing power. You can get away with changing their inputs occasionally, but you might notice your composition slow down if you animate their inputs, even on fancy new computers.
  </li>
  <li>
    If you're not using Origami Live, there are some specific optimizations you can make to your compositions. If you turn off the Render port on Layer Groups that aren't visible, or turn off Enable for layers that aren't visible, you'll stop Quartz Composer from processing those patches, and ones that are linked or contained by them, every frame.
  </li>
</ul>


## Origami Live

Origami Live can run your prototypes at 60 fps by sending images from Quartz Composer on the Mac to the device only when necessary. If the images aren't frequently changing, Origami only needs to send small bits of information over USB every frame, like the positions of layers that are currently moving for example.

<ul class="bulleted-list">
  <li>
    Make sure the Image outputs of your Layer Groups are directly connected to Layer patches (or the Viewer patch). Passing the image of a Layer Group through another patch (like Gaussian Blur) will make it so every time that image changes - either by changing the blur or by making any change to any layer inside the group - will cause it to send a new image to the device. You can try to fake a blur animation by fading a blurred layer on top of the non-blurred one.
  </li>
  <li>
    Avoid using the Enable port on Layers. Each time a layer is enabled, the list of layers gets regenerated on the device which can take some time. Use the Opacity port to hide and show layers instead.
  </li>
  <li>
    Avoid animating the Color port on Layers. This requires special blending to happen on the device.
  </li>
</ul>
