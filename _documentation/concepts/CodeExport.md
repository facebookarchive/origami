---
title: Code Export
layout: documentation
css: /public/css/documentation.css
---

Code Export is a new feature in Origami 2.0 that exports animations in Origami prototypes as code snippets that you can send to your engineers. It can export Objective-C for iOS, Java for Android, and JavaScript for the web. 

The goal of code export is to improve the workflow between design and engineering by enabling designers to quickly export animation constants, so their engineers can achieve exactly the same effects with minimal effort.

Code Export relies on the [Pop](https://github.com/facebook/pop) framework for iOS, [Rebound](http://facebook.github.io/rebound/) for Android, and [Rebound JS](https://github.com/facebook/rebound-js) for the web to deliver the exact same Origami animations across platforms.

## What it exports

This feature currently exports the names and values of:
<ul class="bulleted-list">
<li>Pop Animation patches</li>
<li>Transition patches connected to Pop Animation patches</li>
<li>The connections between those Transition patches and Layers</li>
</ul>

<br>This is the majority of what you need when you&rsquo;re implementing an animation in a product that was designed in Origami.

## What it doesn&rsquo;t

Code Export intentionally doesn&rsquo;t export the entire prototype to code. Prototypes are meant to be quick and dirty design explorations, where designers can rapidly try and evaluate a number of ideas. Prototypes usually contain images that have fake data (like in a news feed) or represent standard system components. They&rsquo;re also usually only in one language, not built to resize to different screen sizes, not built to optimize for performance, handle accessibility modes, etc. They exist to help you make design decisions, not to be a final product to ship to users.

We built Code Export to focus only on exporting the parts of your prototype that make sense to integrate into an actual product.

## How to use it

In the Origami menu, select Code Export and then choose the platform you'd like to export to. Origami will generate code that an engineer can integrate into the project.

For examples of how to integrate the exported code, check out these projects created by [Will Bailey](https://twitter.com/will_bailey) that use the code exported from the [Tap to Zoom](https://www.dropbox.com/s/xcmzr6sefn13abf/Introduction%20to%20Origami.zip?dl=0) example. 

The [web project](http://wsb.im/origami-code-export-tap-to-zoom/index.html) uses the exported code on a webpage. It includes the [Rebound JS](https://github.com/facebook/rebound-js) library and the JavaScript file exported by Origami. The rest of the code sets up the DOM elements and hooks them up to the Origami layers.

The [Android project](https://github.com/willbailey/origami_code_export_tap_to_zoom_android) uses the exported code in an Android project. It includes the [Rebound](http://facebook.github.io/rebound/) library and Java file exported by Origami. Download the project from GitHub to see how the code is integrated.

## More on the way

We&rsquo;re just getting started with Code Export. We have many things on the list that we plan to build support for like Classic Animation patches and Delay patches, and even more on our wish list for the future. Post suggestions for what you&rsquo;d like to see supported in our [community group](https://www.facebook.com/groups/origami.community/).