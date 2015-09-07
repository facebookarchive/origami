origami-website
===============

Origami 2.0 Website


To set up your local machine for editing this website, you need Jekyll and LiveReload.

Get LiveReload from the Mac App Store. It's $10. To set it up, drag the _site folder from the repo into the LiveReload app. LiveReload will automatically refresh the page when you edit it. This happens on both desktop and mobile.

To install Jekyll follow these instructions: https://www.andrewmunsell.com/tutorials/jekyll-by-example/installing-jekyll

Then start jekyll in Terminal by cd'ing into the repo and running jekyll serve —baseurl /origami —watch

To generate the internal documentation, mount your devserver with ExpanDrive, then
jekyll serve --baseurl /~yourusername/origami -d /Volumes/dev/public_html/origami

Go to http://localhost:4000 in your browser and you should see the site.