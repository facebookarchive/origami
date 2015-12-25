var pluginPath = [[NSBundle mainBundle] bundlePath] + "/Export for Origami.sketchplugin";
var pluginCode = [NSString stringWithContentsOfFile:pluginPath
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
// Feed in script directly due to sandboxing
log([[[COScript app:"Sketch"] delegate] runPluginScript:pluginCode  ]);