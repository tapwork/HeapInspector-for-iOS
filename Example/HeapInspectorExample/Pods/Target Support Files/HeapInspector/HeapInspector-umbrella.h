#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HINSPClassDumpTableViewController.h"
#import "HINSPDebug.h"
#import "HINSPDebugWindow.h"
#import "HINSPHeapStackDetailTableViewController.h"
#import "HINSPHeapStackInspector.h"
#import "HINSPHeapStackTableViewController.h"
#import "HINSPRecordButton.h"
#import "HINSPRefHistoryTableViewController.h"
#import "HINSPResponderChainViewController.h"
#import "HINSPShowViewController.h"
#import "HINSPTableViewCell.h"
#import "HINSPTableViewController.h"
#import "NSObject+HeapInspector.h"

FOUNDATION_EXPORT double HeapInspectorVersionNumber;
FOUNDATION_EXPORT const unsigned char HeapInspectorVersionString[];

