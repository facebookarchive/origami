---
title: Patches
layout: documentation
css: /public/css/documentation.css
weight: 300
---

* Patches

Patches are the building blocks that you’ll use to define how your prototype looks and behaves. Place and manipulate patches in the Editor Window. You can add patches to your prototype using the Patch Library window.

Patches come in three types. (Explain more.)

* Ports

Ports are elements that define aspects of a patch's behavior or represent the result of patch's calculations. There are two kinds of ports&mdash;input ports and output ports. Input ports are found on the left side of the patch and output ports are found on the right side.

Some patches, like Layer, don't have output ports. (Explain more.)

* Connections

Connections are lines that connect different patches together to define the flow of data from patch to patch. To create a connection, start dragging from one patch's output port to a different patch's input port.

When a connection is plugged into a patch's input port, that value overrides any previous hardcoded value. (Re-word.) (Write about how state does not revert when unplugged.)