---
title: Progress Values
layout: documentation
css: /public/css/documentation.css
weight: 2
nav:
  prev:
    label: Coordinates
    path: Coordinates
  next:
    label: Pulse & Signal
    path: PulseSignal
---

Values in the range of 0 to 1 are a common concept in Origami prototyping. By animating values in this range, you are keeping your animations generic so they can be translated to specific layer properties using the Transition patch.

Usually you will have a Switch that is flipping between 0 and 1. That feeds into a Pop Animation patch which animates the change between 0 and 1 called a progress value. Then you generally connect that progress value to multiple Transition patches to adjust potentially many different layer properties of many different layers. All of the animations will be synchronized on the same animation curve.