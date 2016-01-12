---
title: Animations
layout: documentation
css: /public/css/documentation.css
weight: 4
nav:
  prev:
    label: States
    path: States
  next:
    label: Sketch Import
    path: ../workflow/SketchImport
---

Animating in Origami is simple. Just connect an Animation patch to any value you want to animate. There are two main options to choose from:

## Animation patches
  <ul class="bulleted-list">
    <li>
      [Pop Animation &rarr;](../patches/Pop-Animation.html) <span class="key letter inline">A</span>
      <br>
      Pop Animation is the preferred way to animate in Origami. It gives you an easy to use spring animation that you can customize to be bouncy, fast, slow, or not bouncy at all. These animations are interruptible, reversible, and retain velocity for fluid interactions.
      <br>
    <li>
      [Classic Animation &rarr;](../patches/Classic-Animation.html)
      <br>
      Classic Animation allows you to specify a duration and provides more traditional curves like linear, ease-in, and ease-out.
    </li>
  </ul>

## Animating values
When connected to an [Interaction](../patches/Interaction-2.html) or a [Switch](../patches/Switch.html) patch, which output 0 or 1, an Animation patch will output an animation over time between 0 and 1, rather than flip between them immediately.

This example below will scale a Layer from 0 to 1 (or 0% to 100%) when you touch down, with a reversible and bouncy animation:


  <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch producer">
          <h3>Interaction</h3>
          <ul class="inputs">
            <li>Enable</li>
          </ul>
          <ul class="outputs">
            <li>Down</li>
            <li>Up</li>
            <li>Tap</li>
            <li>Drag</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch producer">
          <h3>Pop Animation</h3>
          <ul class="inputs">
            <li>Number <span class="patch-value">1</span></li>
            <li>Bounciness</li>
            <li>Speed</li>
          </ul>
          <ul class="outputs">
            <li>Progress</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch consumer">
          <h3>Layer</h3>
          <ul class="inputs">
            <li>Scale <span class="patch-value">1</span></li>
            <li>Opacity</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

## Specifying Transitions
Animating from 0 to 1 is simple, but what about animating between other values?

[Transition](../patches/Transition.html) <span class="key letter inline">T</span> patches let you transform that 0/1 into any start/end value:

  <div class="patch-block">
    <div class="patch processor">
      <h3>Transition</h3>
      <ul class="inputs">
        <li>Progress</li>
        <li>Start Value</li>
        <li>End Value</li>
      </ul>
      <ul class="outputs">
        <li>Value</li>
      </ul>
      <hr>
    </div>
  </div>

For example, if you want to animate a Layer's width from 100px to 200px, you would specify a Start Value of 100, and an End Value of 200. The animated 0 to 1 (or Progress) value from the animation patch will get converted to go from 100 to 200. 

With a Progress of 0:

  <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Transition</h3>
          <ul class="inputs">
            <li>Progress <span class="patch-value">0</span></li>
            <li>Start Value <span class="patch-value">100</span></li>
            <li>End Value <span class="patch-value">200</span></li>
          </ul>
          <ul class="outputs">
            <li>Value</li>
            <div class="cable">
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch consumer">
          <h3>Layer</h3>
          <ul class="inputs">
            <li>Width <span class="patch-value">100</span></li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>


With a Progress of .5:

  <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Transition</h3>
          <ul class="inputs">
            <li>Progress <span class="patch-value">.5</span></li>
            <li>Start Value <span class="patch-value">100</span></li>
            <li>End Value <span class="patch-value">200</span></li>
          </ul>
          <ul class="outputs">
            <li>Value</li>
            <div class="cable">
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch consumer">
          <h3>Layer</h3>
          <ul class="inputs">
            <li>Width <span class="patch-value">150</span></li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>


With a Progress of 1:

  <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Transition</h3>
          <ul class="inputs">
            <li>Progress <span class="patch-value">1</span></li>
            <li>Start Value <span class="patch-value">100</span></li>
            <li>End Value <span class="patch-value">200</span></li>
          </ul>
          <ul class="outputs">
            <li>Value</li>
            <div class="cable">
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch consumer">
          <h3>Layer</h3>
          <ul class="inputs">
            <li>Width <span class="patch-value">200</span></li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>


In combination with an animation patch, you can now animate between any two values easily:


  <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch producer">
          <h3>Interaction</h3>
          <ul class="inputs">
            <li>Enable</li>
          </ul>
          <ul class="outputs">
            <li>Down</li>
            <li>Up</li>
            <li>Tap</li>
            <li>Drag</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch producer">
          <h3>Pop Animation</h3>
          <ul class="inputs">
            <li>Number <span class="patch-value">1</span></li>
            <li>Bounciness</li>
            <li>Speed</li>
          </ul>
          <ul class="outputs">
            <li>Progress</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Transition</h3>
          <ul class="inputs">
            <li>Progress <span class="patch-value">1</span></li>
            <li>Start Value <span class="patch-value">100</span></li>
            <li>End Value <span class="patch-value">200</span></li>
          </ul>
          <ul class="outputs">
            <li>Value</li>
            <div class="cable">
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch consumer">
          <h3>Layer</h3>
          <ul class="inputs">
            <li>Width <span class="patch-value">200</span></li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>
  
  You can even connect the same Progress value from your animation patch to several Transition patches to animate a whole bunch of different properties (like scale, opacity, position) on the same animation timing.