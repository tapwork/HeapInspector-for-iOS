//
//  TWDebugWindow.h
//  TT
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HINSPRecordButton.h"

@interface HINSPDebugWindow : UIWindow

@property (nonatomic, readonly) HINSPRecordButton *recordButton;
@property (nonatomic, readonly) UILabel *infoLabel;
@property (nonatomic, readonly) UIButton *recordedButton;
@property (nonatomic, readonly) UIButton *activeButton;

@end
