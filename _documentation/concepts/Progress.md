---
title: Progress
layout: documentation
css: /public/css/documentation.css
---

Values in the range of 0.0 to 1.0 are a very common concept in Origami prototyping. By expressing your animations in this range, you can connect one underlying animation value to many transition patches, whose ranges may be in pixels, units of scale, rotations, etc.

You can consider the output of a Switch, which is True or False to be 1 or 0, then plug its result into the input of Pop Animation, then connect Transition patches to the output of Pop Animation. This will give you the most basic type of animation, where there are two states: switch is on and switch is off. For each transition patch, toggling the switch will animate between its start and end value, but the overall animation can stil be described in terms of 0.0 to 1.0 or a percent completed.