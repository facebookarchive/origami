---
title: Keyboard Shortcuts
layout: documentation
css: /public/css/documentation.css
weight: 1000
---

Origami provides a variety of keyboard shortcuts for common functions.

{% comment %} Once we ship keyboard shortcuts:
	## Insert Patch
	{% include shortcut-list.html items=site.data.shortcuts.patches %}
{% endcomment %}

## Hover and Press

These keyboard shortcuts can be used when hovering over the canvas and/or a port.

{% include shortcut-list.html items=site.data.shortcuts.patches %}

<br>These keyboard shortcuts can be used when hovering over particular patches.
<ul class="bulleted-list">
  <li>Hover over an Image patch and hit 'g' to embed it in a Layer Group.
  <li>Hover over any patch with an Opacity port and press 0-9 to change the opacity</li>
  <li>Hover over a Keyboard patch and type a character to get that key</li>
</ul>

## Select and Press

These keyboard shortcuts can be used by selecting patches and pressing the shortcut.

{% include shortcut-list.html items=site.data.shortcuts.select %}

## Viewer

{% include shortcut-list.html items=site.data.shortcuts.viewer %}

## Editor

{% include shortcut-list.html items=site.data.shortcuts.app %}

## Inspector Panel

{% include shortcut-list.html items=site.data.shortcuts.inspector %}

