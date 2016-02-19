/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

@interface FBWirelessOutPatchUI : QCInspector

@property (unsafe_unretained) IBOutlet NSPopUpButton *popUpButton;
@property (unsafe_unretained) IBOutlet NSButton *broadcastButton;

- (IBAction)popUpSelectionChanged:(NSPopUpButton *)button;
- (IBAction)viewBroadcaster:(NSButton *)button;

@end
