---
title: Introduction
layout: documentation
css: /public/css/documentation.css
weight: -1
---

Origami is built on Quartz Composer. This section will give you an introduction to its interface and the building blocks: patches and cables.

## Interface

  There are four main windows:
  <ul class="bulleted-list">
  <li>**Editor**: The editor is where you define all the interactions, logic, and layers (via Patches) for how your prototype behaves and looks.</li>
  <li>**Viewer**: The viewer is where you see and interact with your prototype. You can mirror the viewer on your iOS device over USB with [Origami Live](http://itunes.apple.com/app/id942636206) (Android support in progress).</li>
  <li>**Patch Inspector** (&#8984; + i): The inspector lets you change parameters or settings (&#8984; + 2) for a selected patch. You can also use the docked Parameters view (accessible from the toolbar).</li>
  <li>**Patch Library** (&#8984; + &crarr;): The library lets you quickly find and add a patch.</li>
  </ul>

  A good way to organize your windows is **Window > Resize to Thirds** (&#8984; + &#8997; + &#8963; + 0) to dock your Editor to the left and Viewer to the right, and only bring up the Inspector/Library when you need them.

## Patches
  Patches are the building blocks of Origami. They are used to capture interactions, compute logic, and draw to the viewer. They take and give information with Ports, and use Cables to pass that information to other Patches. You can add patches from the Patch Library (&#8984; + &crarr;).

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

## Ports
  Ports allow patches to take information in and spit information back out. The ports on the left side of a patch are **inputs**, and the ones on the right are **outputs**. You can edit **Inputs** with the **Patch Inspector** (&#8984; + i) or double-clicking the port.
  
  Each port has a different type of information it can take &mdash; the important types of values used in Origami are:
  <ul class="bulleted-list">
    <li>**Number**: Any number, with decimals</li>
    <li>**Boolean**: Also known as On/Off, and represented with a checkmark. Can be turned into a Number with 0 being Off and 1 being On.</li>
    <li>**String**: Also known as text.</li>
    <li>**Image**: Any image that you drag, paste, or create.</li>
    <li>**Color**: Any color.</li>
    <li>**Index**: Any non-negative, round numbers. i.e. 0, 1, 2,...</li>
    <li>**Structure**: Stores any number of values within, labeled by indexes or keys (see Structure Creator). Similar to an Object/Dictionary in programming.</li>
    <li>**Interaction**: Ties patches together for interactions. Mostly used in Interaction 2 and Layer patches, and displayed unlabeled in the top right/left respectively.</li>
  </ul>

## Cables
  Cables pass information (values) from patch to patch via their ports. Think of values like water and electricity, and cables as the pipes and cables that move them from place to place. The values flow in one direction: **left-to-right from an output to an input** of the same value type.

  To create a cable, drag from an output port (on the right of a patch) to an input port (on the left of a patch). Hold &#8997; and click to connect an Output to multiple Inputs quickly. To disconnect a cable, drag the right end out of the Input port.

  An Output may provide multiple cables, but an Input can only accept one cable at a time. Use patches like Math, Logic, Transition, or Multiplexer to combine or select from multiple cables.

## Connecting them together
  An example of a typical setup of patches is shown below, where 3 different patches pass values to each other with cables through their ports in order to create an Interaction that Switches a Layer on and off.

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
          <h3>Switch</h3>
          <ul class="inputs">
            <li>Flip <span class="patch-value">&#10003;</span></li>
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

  A note on the different colors of patches:
  <ul class="bulleted-list">
    <li>Purple (Producer) and black (Processor) are similar in that they both have inputs and outputs, but producers typically provide [interactions](../../basics/Interactions) (e.g. Interaction 2, Swipe, Keyboard...).</li>
    <li>Blue (Consumer) patches are what's displayed in the viewer.</li>
    <li>Patches must be connected to a Consumer (like a Layer) to work. This is due to performance optimizations.</li>
  </ul>

