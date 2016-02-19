/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

@interface FBWirelessInPatchUI : QCInspector

@property (unsafe_unretained) IBOutlet NSPopUpButton *popUpButton;

- (IBAction)popUpSelectionChanged:(id)sender;

@end
