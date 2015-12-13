origami-website
===============

Origami 2.0 Website


To set up your local machine for editing this website, you need Jekyll and LiveReload.

### Set up Jekyll

To install Jekyll, you'll need Ruby and RubyGems (which you probably have). Follow these instructions:

1. `sudo gem install jekyll`
2. `sudo gem install jekyll-paginate`

Then start jekyll in Terminal by cd'ing into the repo and running:

`jekyll serve --baseurl /origami --watch`

To generate the internal documentation, mount your devserver with ExpanDrive, then:

`jekyll serve --baseurl /~yourusername/origami -d /Volumes/dev/public_html/origami`

### View the site

After you run `jekyll serve` successfully, one of its output lines will look like:

`    Server address: http://127.0.0.1:4000/origami/`

Copy that URL into your browser to view the site.

### LiveReload

Get [LiveReload](https://itunes.apple.com/us/app/livereload/id482898991?mt=12) from the Mac App Store ($10). To set it up, drag the `_site` folder from the repo into the LiveReload app or menubar. LiveReload will automatically refresh the page when you edit it. This happens on both desktop and mobile.
