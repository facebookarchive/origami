Origami
=======

Origami is a free toolkit for Quartz Composer that makes interactive design prototyping easy and doesn’t require programming.

Most designers today create static mockups to communicate app ideas. But increasingly apps are anything but static, which means as designers we need a better tool for interaction design—this is where Origami comes in.

Getting Origami
---------------

You can download the Origami installer from http://facebook.github.io/origami. You'll need a free Apple Developer account to download Quartz Composer first. Links to create an account and get QC are also available on the Origami page.

If you'd prefer to stay up-to-date with the bleeding edge, you can clone this repository to your computer, and link the `Origami` directory and `Origami.plugin` files to `/Library/Graphics/Quartz Composer Patches`.

```sh
mkdir ~/Workspace
cd ~/Workspace
git clone https://github.com/facebook/origami.git
mkdir -p "~/Library/Graphics/Quartz Composer Patches"
ln -s origami/Origami.plugin "~/Library/Graphics/Quartz Composer Patches"
ln -s origami/Origami "~/Library/Graphics/Quartz Composer Patches"
```

Feedback
--------
Your feedback is important in making Origami better – feel free to open an Issue here on GitHub or send us a tweet @facebookorigami.

We hope you enjoy using Origami, happy prototyping!
