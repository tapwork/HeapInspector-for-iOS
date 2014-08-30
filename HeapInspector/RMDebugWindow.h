//
//  TWDebugWindow.h
//  TT
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMRecordButton.h"

@interface RMDebugWindow : UIWindow

@property (nonatomic, readonly) RMRecordButton *recordButton;
@property (nonatomic, readonly) UILabel *infoLabel;
@property (nonatomic, readonly) UIButton *recordedButton;
@property (nonatomic, readonly) UIButton *activeButton;

@end
