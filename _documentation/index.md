---
title: Introduction
layout: documentation
css: /public/css/documentation.css
weight: -1
---

Origami is built on Quartz Composer. This section will give you an introduction to its interface and the building blocks: patches and cables.

## Interface

  There are four main windows:
  <div class="interface-preview">
    <div class="interface-editor interface-window">
      <div class="interface-toolbar full">Editor</div>
      <div class="cable" style="top: 49px; left: 120px; width: 120px; height: 1px;"></div>
      <div class="patch producer" style="top: 40px; left: 110px;"></div>
      <div class="patch processor" style="top: 40px; left: 160px; width: 60px; height: 30px;"></div>
      <div class="patch consumer" style="top: 40px; left: 230px; height: 60px;"></div>
    </div>
    <div class="interface-viewer interface-window">
      <div class="interface-toolbar full">Viewer</div>
      <div class="interface-viewer-phone">
      <div class="interface-viewer-phone-screen"></div>
      </div>
    </div>
    <div class="interface-inspector interface-window">
      <div class="interface-toolbar">Inspector</div>
      <div class="interface-inspector-input interface-input"></div>
      <div class="interface-inspector-input interface-input"></div>
      <div class="interface-inspector-input interface-input"></div>
      <div class="interface-inspector-input interface-input"></div>
      <div class="interface-inspector-input interface-input"></div>
    </div>
    <div class="interface-library interface-window">
      <div class="interface-toolbar">Library</div>
      <div class="interface-library-list interface-input"></div>
      <div class="interface-library-docs interface-input"></div>
      <div class="interface-library-search interface-input"></div>
    </div>
  </div>
  <ul class="bulleted-list">
  <li>**Editor**
    <br>
    Also known as the graph. The editor is where you define all the layers, interactions, and logic for your prototype, using blocks called "patches".</li>
  <li>**Viewer**
    <br>
    The viewer is where you see and interact with your prototype. You can [preview and interact](../workflow/DevicePreview) with your prototypes on your device over USB with [Origami Live](http://itunes.apple.com/app/id942636206).
  </li>
  <li>**Patch Inspector** (&#8984; + i)
    <br>
    The inspector lets you change parameters for a selected patch. You can also use the docked Parameters view (accessible from the toolbar). The inspector contains three modes you can toggle with the dropdown at the top: Input Parameters (&#8984; + 1), Settings (&#8984; + 2), and Published Inputs & Outputs (&#8984; + 3).
  </li>
  <li>**Patch Library** (&#8984; + &crarr;)
    <br>
    The library lets you quickly find and add a patch.
  </li>
  </ul>

  A good way to organize your windows is **Window > Resize to Thirds** (&#8984; + &#8997; + &#8963; + 0) to dock your Editor to the left and Viewer to the right, and only bring up the Inspector/Library when you need them.

## Patches
  Patches are the building blocks of Origami. They are used to capture interactions, compute logic, and draw to the viewer. Each patch passes and receives information to other patches via its ports and cables. You can add patches from the Patch Library (&#8984; + &crarr;).

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

  Patch types:
  <ul class="bulleted-list">
    <li>**Black (Processor)** patches are take inputs and process them to create various outputs. Think of it like a function in programming.</li>
    <li>**Purple (Producer)** patches have are similar to processors, but typically provide [interactions](../../basics/Interactions) (e.g. Interaction 2, Swipe, Keyboard...) from the viewer.</li>
    <li>**Blue (Consumer)** patches are what's displayed in the viewer.</li>
    <li>Patches must be connected to a Consumer (like a Layer) to work. This is helps optimize performance for your prototype.</li>
  </ul>

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

  To create a cable, drag from an output port (on the right of a patch) to an input port (on the left of a patch). To disconnect a cable, drag the right end out of the Input port.

  An Output may provide multiple cables, but an Input can only accept one cable at a time. Use patches like Math, Logic, Transition, or Multiplexer to combine or select from multiple cables. To quickly connect an ouput to multiple inputs, drag from the output and hold &#8997; while clicking on the inputs.

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

Next: [Layers &rarr;](../basics/Layers)
