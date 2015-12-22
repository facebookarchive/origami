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

Animation patches in Origami are designed to be fluid and reversible: they take any changing number and tween it to be smooth.

## Animation patches
  <ul class="bulleted-list">
    <li>
      [Pop Animation &rarr;](../../patches/Pop-Animation) <span class="key letter inline">A</span>
      <br>
      Pop Animation allows you to use the natural bouncy animations that power Paper, and easily pass values to your developers with the the [Pop](https://github.com/facebook/pop) framework for iOS, [Rebound](http://facebook.github.io/rebound/) for Android, and [Rebound JS](https://github.com/facebook/rebound-js) for the web.
      <br><br>
    <li>
      [Classic Animation &rarr;](../../patches/Classic-Animation)
      <br>
      Classic Animation allows you to specify a duration, provides more traditional curves, like linear, ease-in, and ease-out.
    </li>
  </ul>

## Animating values
In combination with an [Interaction](../../patches/Interaction-2) or a [Switch](../../patches/Switch) patch, which output 0 or 1, an Animation patch can tween that value so it smoothly animates from 0 to 1, and vice versa.

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
        <div class="patch processor">
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

[Transition](../../patches/Transition) <span class="key letter inline">T</span> patches let you transform that 0/1 into any start/end value:

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

For example, if you want to animate a Layer's width from 100px to 200px. You would specify a Start Value of 100, and an End Value of 200. In combination with the animated 0 to 1 value from above, you can easily animate a Layer's width.

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
        <div class="patch processor">
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