//
//  RMGalleryViewCotroller.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 12/11/14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RMGalleryWrongViewCotrollerDelegate;

@interface RMGalleryWrongViewCotroller : UIViewController

@property (nonatomic) id <RMGalleryWrongViewCotrollerDelegate> delegate;

@end

@protocol RMGalleryWrongViewCotrollerDelegate <NSObject>
@optional
- (void)galleryWrongViewCotrollerTimerDidFire:(RMGalleryWrongViewCotroller *)galleryWrongViewCotroller;

@end