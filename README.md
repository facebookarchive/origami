Origami
=======

Origami is a free toolkit for Quartz Composer that makes interactive design prototyping easy and doesn’t require programming.

Most designers today create static mockups to communicate app ideas. But increasingly apps are anything but static, which means as designers we need a better tool for interaction design—this is where Origami comes in.

Getting Origami
---------------

You can download the Origami installer from http://facebook.github.io/origami. You'll need a free Apple Developer account to download Quartz Composer first. Links to create an account and get QC are also available on the Origami page.

If you'd prefer to stay up-to-date with the bleeding edge, you can clone this repository to your computer, and link the `Origami` directory and `Origami.plugin` files to `~/Library/Graphics/Quartz Composer Patches`.

```sh
mkdir ~/Workspace
cd ~/Workspace
git clone https://github.com/facebook/origami.git
mkdir -p ~/Library/Graphics/Quartz\ Composer\ Patches
ln -s `pwd`/origami/Origami.plugin ~/Library/Graphics/Quartz\ Composer\ Patches
ln -s `pwd`/origami/Origami ~/Library/Graphics/Quartz\ Composer\ Patches
```

Troubleshooting
--------

If you continually get the following error:

```
Origami has been installed to the wrong location (local library). Please uninstall Origami using the uninstaller and reinstall from origami.facebook.com
```

Please manually move everything in `/Library/Graphics` to `~/Library/Graphics`. Open both folders in Terminal by pasting the following command:

```
open /Library/Graphics
open ~/Library/Graphics
```

Feedback
--------
Your feedback is important in making Origami better – feel free to open an [Issue](https://github.com/facebook/origami/issues) here on GitHub or post in our [community](https://www.facebook.com/groups/origami.community/).

We hope you enjoy using Origami, happy prototyping!
