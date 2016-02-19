---
title: States & Pulses
layout: documentation
css: /public/css/documentation.css
weight: 3
nav:
  prev:
    label: Progress Values
    path: Progress
  next:
    label: Iterators
    path: Iterators
---

States help remember information in your prototype. Pulses are used to tell patches to perform an action. Understanding how these work together will help you be more effective at building Origami prototypes.

## States

A state is a value that persists over time. The simplest version of state is in the Switch patch. Switches are either on or off, and they remain that way until you tell them otherwise.

If we look at a state as it changes over time, it might look something like this:

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

A switch is off until you turn it on. You can see the state goes from off to on immediately in a single frame. A frame is usually 1/60th of a second.

<div class="frame-reel">
<div class="frame off">Off</div>
<div class="frame off">Off</div>
<div class="frame selected">On</div>
<div class="frame">On</div>
<div class="frame">On</div>
</div>

## Pulses

While state persists over time, pulses are On &#10003; only for a single frame. The value of the cable sending the pulse is otherwise off.

A pulse over time looks like this:

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

They're used to tell patches to **perform an action**, like telling a Switch to turn on or turn off. They're also useful for passing along user interactions like tapping on the screen or pressing a key on the keyboard.

## Examples of State & Pulses

<ul class="bulleted-list">
  <li>The <strong>Switch</strong> patch outputs the <strong>state</strong> of the switch (on / off) and accepts <strong>pulses</strong> to flip the switch, turn it on, or turn it off.</li>
  <li>The <strong>Interaction 2</strong> patch has Down and Up outputs. Down represents the <strong>state</strong> of whether the finger is currently down on the screen. The Up port outputs a <strong>pulse</strong> when the finger is released from the screen.</li>
  <li>The <strong>Counter 2</strong> patch outputs the <strong>state</strong> of the counter (the number value) and accepts <strong>pulses</strong> to increase it or decrease it.</li>
  <li>The <strong>Scroll</strong> patch outputs the <strong>state</strong> of the scroller like its current position and page, and accepts <strong>pulses</strong> to have it jump to a specific position.</li>
</ul>

## Creating Pulses from State

There are a couple ways to create a pulse from state. The more explicit way is to use the Pulse patch. The Pulse patch accepts a state called Input Signal. If the Detection Mode is set to Leading, it will output a pulse when the state changes from off to on. If the mode is set to Trailing, it will output a pulse when the state changes from on to off.

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
            <div class="cable"></div>
            <li>Up</li>
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
            <li>Detection Mode <span class="patch-value">Leading</span></li>
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
  
Another way is to infer a state change is to connect a state directly to a port accepting a pulse. What'll happen is the port that accepts a pulse will look to when the state changes from off to on, and at that moment infer a pulse. So if you wanted a switch to flip the moment the users finger went down on the screen, you could connect the Down port directly to the Switch's Flip port, without needing to use a Pulse patch.


## Transient State with the Delay patch

Sometimes you need a state to go from off to on for a few moments and then back to off. For example, say you were making a confirmation window appear for a couple seconds after the user pressed a button. You could do this using a Switch, but then you'd need to build logic that turns the switch off after some time. A simpler way to do this is to use the [Delay](../patches/Delay.html) <span class="key letter inline">D</span> patch.

The Delay patch can take state that's changing and delay the change by an amount of time you specify. You can also tell it whether to only delay increasing (off to on) or decreasing (on to off) changes. If you give a Delay patch a pulse as input, you can delay the change from on to off, extending the pulse for any amount of time you'd like.

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
            <div class="cable"></div>
            <li>Up</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
    <li>
      <div class="patch-block">
        <div class="patch processor">
          <h3>Delay</h3>
          <ul class="inputs">
            <li>Value <span class="patch-value repeating-pulse">&#10003;</span></li>
            <li>Duration <span class="patch-value">2</span></li>
            <li>Style <span class="patch-value">Delay Decreasing</span></li>
          </ul>
          <ul class="outputs">
            <li>Value</li>
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
            <li>Number</li>
            <li>Bounciness <span class="patch-value">5</span></li>
            <li>Speed <span class="patch-value">10</span></li>
          </ul>
          <ul class="outputs">
            <li>Progress</li>
          </ul>
          <hr>
        </div>
      </div>
    </li>
</ul>
