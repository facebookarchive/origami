---
title: Keyboard Shortcuts
layout: documentation
css: /public/css/documentation.css
weight: 2
---

Origami provides a variety of keyboard shortcuts for common functions. Mastering these will enable you build sophisticated prototypes incredibly fast.

{% comment %} Once we ship keyboard shortcuts:
	## Insert Patch
	{% include shortcut-list.html items=site.data.shortcuts.patches %}
{% endcomment %}

## Hover and Press

These keyboard shortcuts can be used when hovering over the canvas and/or a port.

{% include shortcut-list.html items=site.data.shortcuts.patches %}

<br>These keyboard shortcuts can be used when hovering over particular patches:
<ul class="bulleted-list">
  <li>Hover over an Image patch and hit 'g' to embed it in a Layer Group.
  <li>Hover over any patch with an Opacity port and press 0-9 to change the opacity</li>
  <li>Hover over a Keyboard patch and type a character to get that key</li>
</ul>

## Select and Press

These keyboard shortcuts can be used by selecting patches and pressing the shortcut.

<h6>All Patches</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-all %}

<h6>Blue Patches</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-blue %}

<h6>Patches with Adjustable Numbers of Ports</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-port-count %}

<h6>Typed Patches</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-typed %}

<h6>Math Patch</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-math %}

<h6>Logic Patch</h6>
{% include shortcut-list.html items=site.data.shortcuts.select-logic %}

## Viewer

{% include shortcut-list.html items=site.data.shortcuts.viewer %}

## Editor

{% include shortcut-list.html items=site.data.shortcuts.app %}

## Inspector Panel

{% include shortcut-list.html items=site.data.shortcuts.inspector %}

