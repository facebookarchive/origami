/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBPatchView.h"
#import "QCPatch+FBAdditions.h"
#import "QCPort+FBAdditions.h"
#import "QCIndexPort+FBAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "FBOrigamiAdditions+InlineValues.h"
#import "NSView+FBAdditions.h"
#import "FBTextObject.h"
#import "FBOLiveFilePatch.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static NSMutableDictionary *kPortNameSizes = nil; // Key: Port name, Value: NSSize
static NSDictionary *kPortNameAttributes = nil;
static NSDictionary *kValueAttributes = nil;
static NSDictionary *kScrubbingValueAttributes = nil;
static NSDictionary *kCirclePatchValueAttributes = nil;
static NSColor *kSwatchStrokeColor = nil;
static NSColor *kImageInnerStrokeColor = nil;
static NSColor *kImageOuterStrokeColor = nil;
static NSColor *kImageInnerShadowColor = nil;
static NSColor *kImageShadowColor = nil;
static CGFloat kImageEdgePadding = 5.0;
static CGFloat kImageTopPadding = 38.0;
static CGFloat kPaddingBetweenPortNameAndValue = 11.0;
static CGFloat kPaddingBetweenPortAndValue = 4.0;
static CGFloat kLongPressDuration = 0.2;

@interface FBPatchView ()
@property (strong, nonatomic) NSMapTable *valueRectsForPorts; // Key: QCPort object, Value: Boxed NSRect
@property (weak, nonatomic) QCPort *hitPort;
@property BOOL justDown;
@property NSPoint downPoint;
@property CGFloat downValue;
@property BOOL mouseInCheckbox;
@property (strong, nonatomic) NSTimer *longPressTimer;
@property BOOL longPressed;
@end

@implementation FBPatchView

+ (void)initialize {
  kPortNameAttributes = @{ NSForegroundColorAttributeName : [[NSColor whiteColor] colorWithAlphaComponent:1.0], NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:9.0] };
  kValueAttributes = @{ NSForegroundColorAttributeName : [[NSColor whiteColor] colorWithAlphaComponent:0.5], NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:9.0] };
  kScrubbingValueAttributes = @{ NSForegroundColorAttributeName : [[NSColor whiteColor] colorWithAlphaComponent:0.7], NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:9.0] };
  kCirclePatchValueAttributes = @{ NSForegroundColorAttributeName : [[NSColor whiteColor] colorWithAlphaComponent:0.5], NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:7.0] };
  kPortNameSizes = [NSMutableDictionary dictionary];

  kSwatchStrokeColor = [[NSColor blackColor] colorWithAlphaComponent:0.05];
  kImageInnerStrokeColor = [[NSColor whiteColor] colorWithAlphaComponent:0.05];
  kImageOuterStrokeColor = [[NSColor blackColor] colorWithAlphaComponent:0.1];
  kImageInnerShadowColor = [[NSColor whiteColor] colorWithAlphaComponent:0.2];
  kImageShadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.5];
  
  [super initialize];
}

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portsLayoutDidChange:) name:@"GFPortsLayoutDidChangeNotification" object:nil];
    self.valueRectsForPorts = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)portsLayoutDidChange:(NSNotification *)notif {
  QCPatch *patch = notif.object;
  [self invalidateCachedPointsForPatch:patch];
}

- (BOOL)shouldShowValueForPort:(QCPort *)port {
  QCPatch *node = (QCPatch *)port.node;
  
  static Class QCLogic;
  static Class QCMath;
  static Class QCSplitter;
  static Class FBWirelessInPatch;
  
  if (!QCLogic)
    QCLogic = NSClassFromString(@"QCLogic");
  
  if (!QCMath)
    QCMath = NSClassFromString(@"QCMath");

  if (!QCSplitter)
    QCSplitter = NSClassFromString(@"QCSplitter");
  
  if (!FBWirelessInPatch)
    FBWirelessInPatch = NSClassFromString(@"FBWirelessInPatch");
  
  // Hide all values on these patches
  if ([node isMemberOfClass:QCLogic] && port.baseClass == [QCIndexPort class]) {
    return NO;
  }
  else if ([node isMemberOfClass:QCMath]) {
    if (port.baseClass == [QCIndexPort class]) {
      return NO;
    }
    else if (port.baseClass == [QCNumberPort class]) {
      double value = ((QCNumberPort *)port).doubleValue;
      if (fequalzero(value))
        return NO;
    }
  }
  else if ([node isMemberOfClass:QCSplitter] || [node isMemberOfClass:FBWirelessInPatch]) {
    return NO;
  }

  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
  if ([FBOrigamiAdditions sharedAdditions].inlineValuesDisabled)
    return;
  
  QCPatch *graph = self.graphView.graph;
  
  NSValue *transform = [self.graphView associatedValueForKey:@"fb_transform"];
  CGAffineTransform t;
  [transform getValue:&t];
  
  // Iterate through patches to draw inline values on each
  for (QCPatch *patch in graph.subpatches) {
    NSPoint position = patch.fb_actorPosition;
    
    // Get the position of the patch relative to this view
    if (transform) {
      position = CGPointApplyAffineTransform(position, t);
      position = [self convertPoint:position fromView:self.graphView.superview.superview.superview];
    }

    NSSize actorSize = patch.fb_cachedActorSize;
    NSRect actorRect = NSMakeRect(position.x, position.y, actorSize.width, actorSize.height);
    
    // Bail if the patch isn't visible in the viewport
    if (!NSIntersectsRect(actorRect, dirtyRect))
      continue;
    
    // Draw a thumbnail if this is an Image patch
    static Class QCImageLoader;
    if (!QCImageLoader)
      QCImageLoader = NSClassFromString(@"QCImageLoader");
    
    BOOL patchIsImageLoader = [patch isMemberOfClass:QCImageLoader];
    BOOL patchIsLiveImage = [patch isMemberOfClass:[FBOLiveFilePatch class]];

    if (patchIsImageLoader || patchIsLiveImage) {
      NSImage *image = patchIsImageLoader ? [FBPatchView imageForImageLoader:patch] : [(FBOLiveFilePatch *)patch cachedNSImage];
      
      if (image) {
        NSRect rect = [FBPatchView imageRectForActorSize:actorSize originalImageSize:image.size];
        rect.origin.x += position.x;
        rect.origin.y += position.y;
        [self drawThumbnail:image inRect:rect];
      }
    }
    
    // Iterate through ports to draw values next to each
    for (int portIndex = 0; portIndex < patch.inputPorts.count; portIndex++) {
      QCPort *port = patch.inputPorts[portIndex];
      
      if (![self shouldShowValueForPort:port])
        continue;
      
      NSString *valueString = [self valueStringForPort:port];
      NSPoint pos = [self cachedPointForPort:port];
      
      NSColor *valueColor = nil;
      if (port.baseClass == [QCColorPort class] && port.valueClass == [NSColor class]) {
          valueColor = port.value;
      }
      
      if (port.baseClass == [QCBooleanPort class]) {
        pos.y -= 0.5;
      }
      
      if (!valueString && !valueColor)
        continue;
      
      NSSize portNameSize = NSZeroSize;
      
      static Class QCLogic;
      static Class QCMath;
      if (!QCLogic || !QCMath) {
        QCLogic = NSClassFromString(@"QCLogic");
        QCMath = NSClassFromString(@"QCMath");
      }
      
      BOOL isCircleActor = [patch isMemberOfClass:QCLogic] || [patch isMemberOfClass:QCMath];
      
      if (isCircleActor) {
        pos.x = roundf(pos.x + position.x + kPaddingBetweenPortAndValue);
        pos.y += 1.0;
      } else {
        QCPort *publishedPort = [patch isPortPublished:port]; // This returns the published port, not a boolean.
        NSString *portName = publishedPort ? [NSString stringWithFormat:@"\"%@\"",publishedPort.fb_name] : port.fb_name;
        portNameSize = [self cachedSizeForPortName:portName];
        pos.x = pos.x + position.x + portNameSize.width + kPaddingBetweenPortNameAndValue;
      }
      
      pos.y = pos.y + position.y - 5;
      
      if (port.baseClass == [QCBooleanPort class])
        pos.x += 1.0;
      
      CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
      CGContextSaveGState(c);
      
      BOOL portIsBeingScrubbed = (self.longPressed && self.hitPort == port);
      
      if (valueString) {
        QCPort *adjacentPort = [self outputPortAdjacentToInputPort:port atIndex:portIndex];
        CGFloat outputPortWidth = 0.0;
        if (adjacentPort)
          outputPortWidth = [self cachedSizeForPortName:adjacentPort.fb_name].width + 16;
        NSRect stringRect = NSMakeRect(pos.x, pos.y, actorSize.width - portNameSize.width - kPaddingBetweenPortNameAndValue - 12.0 - outputPortWidth, 14);
        
        if (port.baseClass == [QCNumberPort class] || port.baseClass == [QCIndexPort class] || port.baseClass == [QCStringPort class]) {
          CGFloat hitPadding = 4;
          NSRect hitArea = stringRect;
          hitArea.size.width = fminf(valueString.length * 5 + hitPadding, stringRect.size.width); // Approximate string length so we don't have the perf costs from measuring
          hitArea.size.height -= 2;
          hitArea.origin.x -= hitPadding / 2.0;
          
          if (![FBOrigamiAdditions sharedAdditions].textBackgroundsDisabled) {
            NSEvent *theEvent = self.window.currentEvent;
            NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
            
            // Draw a background behind the value under the mouse, so it will respond to clicks
            if (NSPointInRect(pointInView, hitArea)) {
              NSColor *patchColor = [FBOrigamiAdditions sharedAdditions].customColorDisabled ? [NSColor whiteColor] : [[self.graphView nodeActorForNode:patch] _colorForNode:patch];
              [[patchColor colorWithAlphaComponent:0.05] set]; // Minimum alpha to trick the hit testing system into thinking its opaque
              NSRectFillUsingOperation(hitArea, NSCompositeSourceOver);
            }
          }
          
          [self.valueRectsForPorts setObject:[NSValue valueWithRect:hitArea] forKey:port];
        }
        else if (port.baseClass == [QCBooleanPort class]) {
          CGFloat checkboxSize = isCircleActor ? 5.0 : 7.0;
          CGFloat yInset = stringRect.size.height - checkboxSize;
          CGFloat yCircleOffset = isCircleActor ? -1.5 : 0.0;
          NSRect rect = NSMakeRect(stringRect.origin.x - 0.5, stringRect.origin.y + (yInset / 2.0) - 0.5 + yCircleOffset, checkboxSize, checkboxSize);
          rect.origin.x = [self fb_pixelAlignedValue:rect.origin.x];
          rect.origin.y = [self fb_pixelAlignedValueByFlooring:rect.origin.y];
          
          if (![FBOrigamiAdditions sharedAdditions].checkboxesDisabled) {
            CGFloat cornerRadius = isCircleActor ? 1.0 : 2.0;
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:cornerRadius yRadius:cornerRadius];
            CGFloat alpha = (self.hitPort == port && self.mouseInCheckbox) ? 0.4 : 0.15;
            CGContextSetGrayFillColor(c, 1.0, alpha);
            [path fill];
          }
          
          [self.valueRectsForPorts setObject:[NSValue valueWithRect:rect] forKey:port];
        }
        else if (port.baseClass == [QCColorPort class]) {
          [self.valueRectsForPorts setObject:[NSValue valueWithRect:stringRect] forKey:port];
        }
        
        // Draw scrubber background
        if (portIsBeingScrubbed) {
          CGFloat cornerRadius = 2.0;
          NSSize valueSize = [self cachedSizeForPortName:valueString];
          NSRect rect = NSMakeRect(stringRect.origin.x, stringRect.origin.y, fminf(valueSize.width, stringRect.size.width), valueSize.height);
          rect = NSInsetRect(rect, -2.0, 0.0);
          rect = [self fb_pixelAlignedOrigin:rect];
          NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:cornerRadius yRadius:cornerRadius];
          CGFloat alpha = 0.15;
          CGContextSetGrayFillColor(c, 1.0, alpha);
          [path fill];
        }
        
        CGContextSetShouldSmoothFonts(c, NO); // Disable subpixel AA to match QC rendering
        
        if (![FBOrigamiAdditions sharedAdditions].coreTextDisabled) {
          FBTextObject *textObject = [port associatedValueForKey:@"fb_textObject"];
          NSTextStorage *textStorage = textObject.textStorage;
          NSLayoutManager *layoutManager = textObject.layoutManager;
          NSTextContainer *textContainer = textObject.textContainer;
          NSRange glyphRange = textObject.glyphRange;
          
          if (!textObject) {
            NSDictionary *valueAttributes = portIsBeingScrubbed ? kScrubbingValueAttributes : kValueAttributes;
            NSDictionary *attributes = isCircleActor ? kCirclePatchValueAttributes : valueAttributes;
            NSAttributedString *as = [[NSAttributedString alloc] initWithString:valueString attributes:attributes];

            textStorage = [[NSTextStorage alloc] initWithAttributedString:as];
            layoutManager = [[NSLayoutManager alloc] init];
            textContainer = [[NSTextContainer alloc] initWithContainerSize:stringRect.size];
            textContainer.lineFragmentPadding = 0;
            [layoutManager addTextContainer:textContainer];
            [textStorage addLayoutManager:layoutManager];
            
            glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
            
            textObject = [[FBTextObject alloc] init];
            textObject.textStorage = textStorage;
            textObject.layoutManager = layoutManager;
            textObject.textContainer = textContainer;
            textObject.glyphRange = glyphRange;
            [port associateValue:textObject withKey:@"fb_textObject"];
          }
          
          if (![textStorage.string isEqualToString:valueString]) {
            NSDictionary *valueAttributes = portIsBeingScrubbed ? kScrubbingValueAttributes : kValueAttributes;
            NSDictionary *attributes = isCircleActor ? kCirclePatchValueAttributes : valueAttributes;
            NSAttributedString *as = [[NSAttributedString alloc] initWithString:valueString attributes:attributes];
            
            [textStorage setAttributedString:as];
            
            glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
            textObject.glyphRange = glyphRange;
          }

          [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:stringRect.origin];
        }
        else {
          NSDictionary *valueAttributes = portIsBeingScrubbed ? kScrubbingValueAttributes : kValueAttributes;
          NSDictionary *attributes = isCircleActor ? kCirclePatchValueAttributes : valueAttributes;
          NSAttributedString *as = [[NSAttributedString alloc] initWithString:valueString attributes:attributes];
          
          if (valueString.length < 8)
            [as drawWithRect:stringRect options:NSStringDrawingUsesLineFragmentOrigin];
          else
            [as drawWithRect:stringRect options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine];
        }
    
      }
      else if (valueColor) {
        CGFloat size = 5.0;
        NSRect rect = CGRectMake(pos.x + 1.0, pos.y + 3.0, size, size);
        rect.origin.x = [self fb_pixelAlignedValueByCeiling:rect.origin.x];
        rect.origin.y = [self fb_pixelAlignedValueByCeiling:rect.origin.y];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:1.5 yRadius:1.5];
        CGContextSetFillColorWithColor(c, valueColor.CGColor);
        CGContextSetStrokeColorWithColor(c, kSwatchStrokeColor.CGColor);
        [path fill];
        [path stroke];
        
        [self.valueRectsForPorts setObject:[NSValue valueWithRect:rect] forKey:port];
      }
      
      CGContextRestoreGState(c);
    }
  }
}

- (BOOL)isFlipped {
  return YES;
}

- (QCPort *)outputPortAdjacentToInputPort:(QCPort *)port atIndex:(NSUInteger)portIndex {
  NSArray *outputPorts = port.node.outputPorts;
  
  NSMutableArray *trimmedOutputs = [NSMutableArray array];
  
  for (int i = 0; i < outputPorts.count; i++) {
    QCPort *outputPort = outputPorts[i];
    
    if (outputPort.baseClass != [QCInteractionPort class]) {
      [trimmedOutputs addObject:outputPort];
    }
    
    if (trimmedOutputs.count > portIndex)
      return trimmedOutputs[portIndex];
  }
  
  return nil;
}

- (NSArray *)cachedMenuWithoutSeparatorsForPort:(QCIndexPort *)port {
  NSArray *menuWithoutSeparators = [port associatedValueForKey:@"fb_menuWithoutSeparators"];
  
  if (!menuWithoutSeparators)
    [port associateValue:port.fb_menuByRemovingSeparators withKey:@"fb_menuWithoutSeparators"];
  
  return menuWithoutSeparators;
}

- (NSSize)cachedSizeForPortName:(NSString *)portName {
  NSValue *nameSize = kPortNameSizes[portName];
  
  if (!nameSize) {
    NSSize size = [portName sizeWithAttributes:kPortNameAttributes];
    kPortNameSizes[portName] = [NSValue valueWithSize:size];
    return size;
  }
  
  return nameSize.sizeValue;
}

// Returns the position of a port in the coordinate system of the node actor.
- (NSPoint)cachedPointForPort:(QCPort *)port {
  NSValue *positionValue = [port associatedValueForKey:@"fb_positionInNode"];
  
  if (!positionValue) {
    NSRect bounds = NSZeroRect;
    QCPatch *node = (QCPatch *)port.node;
    QCPatchActor *nodeActor = [self.graphView nodeActorForNode:node];
    bounds.size = [nodeActor sizeForNode:node];
    NSPoint position = [nodeActor pointForPort:port inNode:node bounds:bounds];
    [port associateValue:[NSValue valueWithPoint:position] withKey:@"fb_positionInNode"];
    return position;
  }
  
  return positionValue.pointValue;
}

- (void)invalidateCachedPointsForPatch:(QCPatch *)patch {
  for (QCPort *port in patch.inputPorts) {
    [port associateValue:nil withKey:@"fb_positionInNode"];
  }
}

#pragma mark Thumbnails

+ (NSRect)imageRectForActorSize:(NSSize)actorSize originalImageSize:(NSSize)originalImageSize {
  NSSize destinationSize = NSMakeSize(actorSize.width - kImageEdgePadding * 2, actorSize.height - kImageTopPadding - kImageEdgePadding * 2);
  NSSize imageSize = [self aspectFitSizeForImageSize:originalImageSize inDestinationSize:destinationSize];
  
  return NSMakeRect(roundf(actorSize.width / 2 - imageSize.width / 2), kImageEdgePadding + kImageTopPadding, imageSize.width, imageSize.height);
}

+ (NSSize)aspectFitSizeForImageSize:(NSSize)imageSize inDestinationSize:(NSSize)size {
  CGFloat aspect = imageSize.width / imageSize.height;
  if (size.width / aspect <= size.height) {
    return NSMakeSize(roundf(size.width), roundf(size.width / aspect));
  } else {
    return NSMakeSize(roundf(size.height * aspect), roundf(size.height));
  }
}

+ (NSImage *)imageForImageLoader:(QCPatch *)patch {
  NSImage *image = [patch associatedValueForKey:@"fb_NSImage"];
  
  if (!image) {
    NSData *imageData = [patch performSelector:@selector(imageData)];
    
    if (imageData) {
      image = [[NSImage alloc] initWithData:imageData];
      
      if (image)
        [patch associateValue:image withKey:@"fb_NSImage"];
    }
  }
  
  return image;
}

- (void)drawThumbnail:(NSImage *)image inRect:(NSRect)rect {
  [[[NSColor whiteColor] colorWithAlphaComponent:0.75] set];
  NSRectFillUsingOperation(rect, NSCompositeSourceOver);
  
  [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
  
  [NSGraphicsContext saveGraphicsState];
  
  [kImageInnerStrokeColor set];
  NSFrameRectWithWidthUsingOperation(rect, 1.0, NSCompositeSourceOver);
  
  NSRect outerRect = NSInsetRect(rect, -1.0, -1.0);
  [kImageOuterStrokeColor set];
  NSFrameRectWithWidthUsingOperation(outerRect, 1.0, NSCompositeSourceOver);
  
  NSRect lineRect = rect;
  lineRect.size.height = 1.0;
  [kImageInnerShadowColor set];
  NSRectFillUsingOperation(lineRect, NSCompositeSourceOver);
  
  lineRect.origin.y += rect.size.height;
  [kImageShadowColor set];
  NSRectFillUsingOperation(lineRect, NSCompositeSourceOver);
  
  [NSGraphicsContext restoreGraphicsState];
}

#pragma mark Value Strings

- (NSString *)valueStringForPort:(QCPort *)port {
  NSString *valueString;
  QCPatch *patch = port.parentPatch;
  
  if (port.baseClass == [QCNumberPort class]) {
    QCNumberPort *numberPort = (QCNumberPort *)port;
    double number = numberPort.doubleValue;
    
    valueString = [self stringFromNumber:number];
  }
  else if (port.baseClass == [QCStringPort class]) {
    QCStringPort *stringPort = (QCStringPort *)port;
    valueString = stringPort.stringValue;
  }
  else if (port.baseClass == [QCBooleanPort class]) {
    QCBooleanPort *booleanPort = (QCBooleanPort *)port;
    BOOL value = booleanPort.booleanValue;
    
    valueString = value ? @"\u2713" : @"  ";
  }
  else if (port.baseClass == [QCIndexPort class]) {
    static Class QCConditional;
    if (!QCConditional) {
      QCConditional = NSClassFromString(@"QCConditional");
    }
    
    if ([patch isMemberOfClass:QCConditional]) {
      valueString = [self stringForConditionPort:port];
    }
    else {
      NSNumber *value = port.value;
      NSInteger index = value.intValue;
      
      if (port.attributes[@"menu"]) {
        NSArray *trimmedMenu = [self cachedMenuWithoutSeparatorsForPort:(QCIndexPort *)port];
        
        if (trimmedMenu.count > index)
          valueString = trimmedMenu[index];
      }
      else {
        valueString = [self stringFromNumber:index];
      }
      
      static Class QCPulse;
      if (!QCPulse) {
        QCPulse = NSClassFromString(@"QCPulse");
      }
      
      if ([patch isMemberOfClass:QCPulse]) {
        valueString = [valueString componentsSeparatedByString:@" "][0];
      }
    }
  }
  else if (port.baseClass == [QCColorPort class]) {
    if (port.valueClass == [NSColor class]) {
      NSColor *valueColor = port.value;
      
      if (fequalzero(valueColor.alphaComponent)) {
        valueString = @"Clear";
      }
      else if (fequal(valueColor.redComponent, 1.0) && fequal(valueColor.greenComponent, 1.0) && fequal(valueColor.blueComponent, 1.0)) {
        valueString = @"White";
      }
      else if (fequalzero(valueColor.redComponent) && fequalzero(valueColor.greenComponent) && fequalzero(valueColor.blueComponent)) {
        valueString = @"Black";
      }
    }
  }
  else if (port.baseClass == [QCStructurePort class]) {
    QCStructurePort *structurePort = (QCStructurePort *)port;
    QCStructure *structure = structurePort.structureValue;
    
    if (structure)
      valueString = [NSString stringWithFormat:@"(%lu)",structure.count];
  }
  
  return valueString;
}

- (NSString *)stringFromNumber:(double)number {
  number = number * 1000;
  number = roundf(number);
  number = number / 1000;
  
  if (fequalzero(number))
    number = 0;
  
  return [NSString stringWithFormat:@"%.4g",number];
}

- (NSString *)stringForConditionPort:(QCPort *)port {
  NSNumber *value = port.value;
  NSInteger index = value.intValue;
  NSString *valueString = nil;

  if (index == 0) {
    valueString = @"Equals";
  } else if (index == 1) {
    valueString = @"Not Equal";
  } else if (index == 2) {
    valueString = @"Greater";
  } else if (index == 3) {
    valueString = @"Lower";
  } else if (index == 4) {
    valueString = @"Greater / Equal";
  } else if (index == 5) {
    valueString = @"Lower / Equal";
  }
  
  return valueString;
}

#pragma mark Value Scrubbing

- (void)mouseDown:(NSEvent *)theEvent {
  // If the cursor is a hand cursor, the user is panning and clicks shouldn't adjust inline values
  NSCursor *cursor = ((NSClipView *)self.graphView.superview).documentCursor;
  if (cursor == [NSCursor openHandCursor] || cursor == [NSCursor closedHandCursor])
    return;
  
  NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
  self.hitPort = nil;
  self.longPressTimer = nil;
  
  for (QCPort *port in NSAllMapTableKeys(self.valueRectsForPorts)) {
    NSValue *rectValue = [self.valueRectsForPorts objectForKey:port];
    NSRect rect = rectValue.rectValue;
    
    if (NSPointInRect(pointInView, rect)) {
      self.hitPort = port;
      self.justDown = YES;
      self.downPoint = pointInView;

      if (!self.longPressTimer && self.hitPort.baseClass != [QCBooleanPort class] && self.hitPort.baseClass != [QCStringPort class])
        self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:kLongPressDuration target:self selector:@selector(longPress:) userInfo:nil repeats:NO];
      
      if (self.hitPort.baseClass == [QCIndexPort class]) {
        self.downValue = ((QCIndexPort *)self.hitPort).indexValue;
      }
      else if (self.hitPort.baseClass == [QCNumberPort class]) {
        self.downValue = ((QCNumberPort *)self.hitPort).doubleValue;
      }
      else if (self.hitPort.baseClass == [QCBooleanPort class]) {
        self.downValue = ((QCBooleanPort *)self.hitPort).booleanValue;
        self.mouseInCheckbox = YES;
      }
      else if (self.hitPort.baseClass == [QCColorPort class]) {
        QCColorPort *colorPort = (QCColorPort *)self.hitPort;
        
        CGFloat h, s, b, a;
        NSColor *color = [NSColor colorWithCalibratedRed:colorPort.redComponent green:colorPort.greenComponent blue:colorPort.blueComponent alpha:colorPort.alphaComponent];
        [color getHue:&h saturation:&s brightness:&b alpha:&a];
        self.downValue = b;
      }
      
      break;
    }
  }
  
  // Forward clicks on unsupported value types
  if (!self.hitPort)
    [self.graphView mouseDown:theEvent];
}

- (void)longPress:(id)sender {
  self.longPressed = YES;
  
  if (self.hitPort.baseClass != [QCBooleanPort class])
    [[NSCursor resizeLeftRightCursor] push];
}

- (void)mouseDragged:(NSEvent *)theEvent {
  [self.longPressTimer invalidate];
  
  BOOL shouldScrub = self.hitPort && self.longPressed;
  
  if (!shouldScrub) {
    self.hitPort = nil;
    [self.graphView mouseDown:theEvent];
    [self.graphView mouseDragged:theEvent];
    return;
  }
  
  CGFloat deltaX = theEvent.deltaX;
  
  if (self.justDown) {
    self.justDown = NO;
    
    if (self.hitPort.baseClass != [QCBooleanPort class]) {
      [self deleteInputConnectionsOnPort:self.hitPort];
      [self.hitPort.parentPatch __setValue:self.hitPort.value forPortKey:self.hitPort.key]; // Insert the current value into the undo stack
    }
  }
  
  CGFloat multiplier = 1.0;
  
  if ([NSEvent modifierFlags] & NSAlternateKeyMask)
    multiplier *= 0.1;
  else if ([NSEvent modifierFlags] & NSShiftKeyMask)
    multiplier *= 10;
  
  if (self.hitPort.baseClass == [QCNumberPort class]) {
    QCNumberPort *numberPort = (QCNumberPort *)self.hitPort;
    BOOL isRangedSlider = (numberPort.minDoubleValue > -0.001 && numberPort.minDoubleValue < 0.001) && (numberPort.maxDoubleValue > 0.999 && numberPort.maxDoubleValue < 1.001);
    
    if (isRangedSlider || // Ranged slider from 0-1
        [self.hitPort.parentPatch portForKey:@"Scale"] == self.hitPort || // Name is "Scale"
        [self.hitPort.parentPatch portForKey:@"Progress"] == self.hitPort || // Name is "Progress"
        [self.hitPort.parentPatch portForKey:@"01_Value"] == self.hitPort || // Name is "0-1 Value"
        (fabsf(self.downValue - roundf(self.downValue))) > 0.00001) { // Number has a decimal component
      multiplier *= 0.01;
    }
    
    numberPort.doubleValue = numberPort.doubleValue + (deltaX * multiplier);
  }
  else if (self.hitPort.baseClass == [QCIndexPort class]) {
    QCIndexPort *indexPort = (QCIndexPort *)self.hitPort;

    NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
    multiplier *= 0.05;
    indexPort.indexValue = fmax(0, self.downValue + (pointInView.x - self.downPoint.x) * multiplier);
  }
  else if (self.hitPort.baseClass == [QCBooleanPort class]) {
    NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSValue *rectValue = [self.valueRectsForPorts objectForKey:self.hitPort];
    NSRect rect = rectValue.rectValue;
    
    self.mouseInCheckbox = NSPointInRect(pointInView, rect);
  }
  else if (self.hitPort.baseClass == [QCColorPort class]) {
    QCColorPort *colorPort = (QCColorPort *)self.hitPort;
    
    CGFloat hue, sat, brightness, hsbAlpha;
    NSColor *color = [NSColor colorWithCalibratedRed:colorPort.redComponent green:colorPort.greenComponent blue:colorPort.blueComponent alpha:colorPort.alphaComponent];
    [color getHue:&hue saturation:&sat brightness:&brightness alpha:&hsbAlpha];
    
    multiplier *= 0.01;
    
    brightness -= (deltaX * multiplier);
    
    CGFloat red, green, blue, rgbAlpha;
    NSColor *newColor = [NSColor colorWithCalibratedHue:hue saturation:sat brightness:brightness alpha:hsbAlpha];
    [newColor getRed:&red green:&green blue:&blue alpha:&rgbAlpha];
    
    [colorPort setRed:red green:green blue:blue alpha:rgbAlpha];
  }

}

- (void)mouseUp:(NSEvent *)theEvent {
  [self.longPressTimer invalidate];

  if (!self.hitPort) {
    [self.graphView mouseUp:theEvent];
    return;
  }
  
  if (self.hitPort) {
    if (self.hitPort.baseClass == [QCBooleanPort class]) {
      if (self.mouseInCheckbox) {
        [self deleteInputConnectionsOnPort:self.hitPort];
        [self.hitPort.parentPatch __setValue:self.hitPort.value forPortKey:self.hitPort.key];
        
        QCBooleanPort *port = (QCBooleanPort *)self.hitPort;
        port.booleanValue = !port.booleanValue;
      }
    } else {
      if (theEvent.clickCount == 2) {
        NSValue *rectValue = [self.valueRectsForPorts objectForKey:self.hitPort];
        NSRect rect = rectValue.rectValue;
        [self.hitPort.parentPatch __setValue:self.hitPort.value forPortKey:self.hitPort.key]; // Put the current value in the undo stack
        id oldValue = self.hitPort.value;
        [self.hitPort editValueWithEvent:theEvent inView:self.graphView atPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
        if (![oldValue isEqual:self.hitPort.value])
          [self deleteInputConnectionsOnPort:self.hitPort];
      }
      
      [NSCursor pop];
    }
    
    self.hitPort = nil;
    self.mouseInCheckbox = NO;
    self.longPressed = NO;
  }
}

- (void)scrollWheel:(NSEvent *)theEvent {
  [self.graphView scrollWheel:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
  [self.graphView rightMouseDown:theEvent];
}

- (void)deleteInputConnectionsOnPort:(QCPort *)port {
  for (QCLink *connection in self.hitPort.parentPatch.parentPatch.connections) {
    if (connection.destinationPort == self.hitPort) {
      [self.hitPort.parentPatch.parentPatch deleteConnection:connection];
    }
  }
}

@end
