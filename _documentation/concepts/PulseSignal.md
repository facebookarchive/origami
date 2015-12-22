---
title: Pulse & Signal
layout: documentation
css: /public/css/documentation.css
weight: 3
nav:
  prev:
    label: Progress Values
    path: ../Progress
  next:
    label: Iterators
    path: ../Iterators
---

Pulses and signals are a core concept in Origami, especially for representing and toggling states. To understand them you must first understand how [States](../../basics/States) are represented by On/Off (also known as a boolean, shown in the interface as a checkbox, with a &#10003; when it's on).

## Signals = On or Off
A signal represents an on/off state. A good example of a signal is the [Switch](../../patches/Switch) patch's On/Off output.

Below, the Switch is off, and it passes that Off signal to the Layer's Enable port:

 <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch</h3>
          <ul class="inputs">
            <li>Flip</li>
            <li>Turn On</li>
            <li>Turn Off</li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
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
            <li>Enable</li>
            <li>X Position</li>
            <li>Y Position</li>
            <li>Width</li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

Then, if we turn the Switch on, it then passes that On &#10003; signal to the Layer's Enable port:

 <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch</h3>
          <ul class="inputs">
            <li>Flip</li>
            <li>Turn On</li>
            <li>Turn Off</li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
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
            <li>Enable <span class="patch-value">&#10003;</span></li>
            <li>X Position</li>
            <li>Y Position</li>
            <li>Width</li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

## Signals persist over time
A key attribute of a signal is that it persists over time. If we look at a signal as it changes over time, it might look something like this:

<div class="pulse-graph">
<div class="pulse-graph-line" style="bottom: 10%; left: 40px; width: 130px;"></div>
<div class="pulse-graph-line" style="top: 10%; bottom: 10%; left: 170px; height: 80%;"></div>
<div class="pulse-graph-line" style="top: 10%; left: 171px; width: 130px;"></div>
<div class="pulse-graph-x-axis"><h6>Time<h6></div>
<div class="pulse-graph-y-axis-label top">
  <h6>On</h6>
</div>
<div class="pulse-graph-y-axis-label bottom">
  <h6>Off</h6>
</div>
</div>

It's off consistently until it's turned on. You can see a signal goes from off to on **immediately**. That split second is known as a **frame**.

<div class="frame-reel">
<div class="frame off">Off</div>
<div class="frame off">Off</div>
<div class="frame selected">On</div>
<div class="frame">On</div>
<div class="frame">On</div>
</div>

A frame in computing is similar to a movie: multiple frames are strung together to show animations. Typically Quartz Composer will run at 30-60 frames per second (FPS), which means the signal change happens anywhere from 1/30 to 1/60 of a second, feeling instantaneous.

## Pulses are On &#10003; signals in a single frame
While signals persist over time, Pulses are On &#10003; for a single frame.

If we look at a pulse over time, it looks like this:

<div class="pulse-graph">
<div class="pulse-graph-line" style="bottom: 10%; left: 40px; width: 130px;"></div>
<div class="pulse-graph-line" style="top: 10%; bottom: 10%; left: 170px; height: 80%;"></div>
<div class="pulse-graph-line" style="bottom: 10%; left: 171px; width: 130px;"></div>
<div class="pulse-graph-x-axis"><h6>Time<h6></div>
<div class="pulse-graph-y-axis-label top">
  <h6>On</h6>
</div>
<div class="pulse-graph-y-axis-label bottom">
  <h6>Off</h6>
</div>
</div>

You can see that pulses are only On &#10003; for a single frame.

<div class="frame-reel">
<div class="frame off">Off</div>
<div class="frame off">Off</div>
<div class="frame selected">On</div>
<div class="frame off">Off</div>
<div class="frame off">Off</div>
</div>

They are useful when telling a patch to **do something once**, like telling a Switch to turn on or turn off.

Why not use signals? Let's look at the Switch example again. If you pass an On signal continuously to a Switch's Turn On port, it will turn on, as expected:

 <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch</h3>
          <ul class="inputs">
            <li>Flip</li>
            <li>Turn On <span class="patch-value">&#10003;</span></li>
            <li>Turn Off</li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
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
            <li>Enable <span class="patch-value">&#10003;</span></li>
            <li>X Position</li>
            <li>Y Position</li>
            <li>Width</li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

However, if you wanted to tell it to turn off at a later time (by passing an On signal to the Turn Off port), you'd be giving it conflicting instructions. If you try this in Quartz Composer, you'll see that the Enable port will flicker on and off continuously &mdash; because it's not sure what to do with the conflicting instructions.

 <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch</h3>
          <ul class="inputs">
            <li>Flip</li>
            <li>Turn On <span class="patch-value">&#10003;</span></li>
            <li>Turn Off <span class="patch-value">&#10003;</span></li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
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
            <li>Enable <span class="patch-value flicker">&#10003;</span></li>
            <li>X Position</li>
            <li>Y Position</li>
            <li>Width</li>
            <li>Height</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

To fix this, you could manually make sure to turn off the Turn On signal, but to simplify, you should **pulse** each port (pass On &#10003; for a single frame).


## Creating pulses
How do you create pulses? Most situations where you need a pulse are with [interactions](../../basics/Interactions), e.g. a single tap, or a key press. The [Interaction 2](../../patches/Interaction-2) patch, for example, will output a single pulse from the Tap port when you tap on the viewer (whereas the Down port will output a continous signal depending on how long your finger is down).

Another common situation is when you want to know when a Signal changes, e.g. if you want to turn on a Switch after another Switch turns off. In this case, you'd use a [Pulse](../../patches/Pulse) <span class="key letter inline">U</span> patch.

In this example below, when Switch 1 turns off, Switch 2 will turn on:

 <ul class="patch-chain">
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch 1</h3>
          <ul class="inputs">
            <li>Turn On</li>
            <li>Turn Off</li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Pulse</h3>
          <ul class="inputs">
            <li>Input Signal <span class="patch-value repeating-signal">&#10003;</span></li>
            <li>Detection mode <span class="patch-value">Trailing</span></li>
          </ul>
          <ul class="outputs">
            <li>Pulse</li>
            <div class="cable"></div>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Switch 2</h3>
          <ul class="inputs">
            <li>Turn On <span class="patch-value repeating-pulse">&#10003;</span></li>
            <li>Turn Off</li>
          </ul>
          <ul class="outputs">
            <li>On / Off</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
  </ul>

You can even combine Pulse with [Delay](../../patches/Delay) <span class="key letter inline">D</span> patches to create a Switch that turns itself off a few seconds after it's turned on.