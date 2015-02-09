# HeapInspector
## Find memory issues & leaks in your iOS app
[![Build Status](https://api.travis-ci.org/tapwork/HeapInspector-for-iOS.svg?style=flat)](https://travis-ci.org/tapwork/HeapInspector-for-iOS)
[![Cocoapods Version](http://img.shields.io/cocoapods/v/HeapInspector.svg?style=flat)](https://github.com/tapwork/HeapInspector-for-iOS/blob/master/HeapInspector.podspec)
[![](http://img.shields.io/cocoapods/l/HeapInspector.svg?style=flat)](https://github.com/tapwork/HeapInspector-for-iOS/blob/master/LICENSE.md)
[![CocoaPods Platform](http://img.shields.io/cocoapods/p/HeapInspector.svg?style=flat)]()

HeapInspector is an iOS debug tool that **monitors the memory heap** in your app. You can discover memory leaks, no longer needed living objects and more issues directly on your device without ever starting Instruments.

#### Memory heap snapshots
Basically you can inspect the entire heap and see all living objects of your iOS app. <br>
To be more precise you can record the heap for a specific part of the app. For instance when navigating through the menu. Like in Apple's Instruments the snapshot compares the heap before you started recording. For instance you can start the snapshot before you push a new `UIViewController` onto your `UINavigationController` stack and stop after popping the `UIViewController`.
With HeapInspector and heap snapshots you can identify:
* Leaking objects
* Retain cycles
* Living objects that are no longer needed
* static objects like singletons or cached `UIImage`
* Dirty memory and your objects on the heap

HeapInspector gives you detailed information for the living objects:

* Reference history (see who called retain, strong, release) for NSObject subclasses
* Responder chain for recorded objects
* Screenshots of the inspected UIView, UIViewController, UIImage
* Detailed information about the object (Description, frame, properties, iVars, methods)

# In Action

![HeapInspector](README_Xtras/screencast.gif)


# Why
Since ARC has been introduced we don't need to manage the `retain` & `release` anymore. ARC is very powerful and makes Objective C more stable. ARC decreased the number of crashes and improves the memory footprint.<br> ARC is technically doing a powerful job. It knows when to `retain`, `autorelease` and `release`.
<br>But ARC doesn't think about the overall architecture how to design for low memory usage. You should be aware that you can still do a lot of things wrong with your memory (even with ARC). You can still get memory pressures or peaks with ARC.
* You can still create Retain Cycles
* The `strong` property lifetime qualifier can be misused (i.e. holding an object twice and longer than needed.)
* Memory peaks through loops (if you're not using a proper `@autoreleasepool`)
* Wrong caching with `static`

And that's why we introduced HeapInspector to find those issues.

# Installation
### CocoaPods

Just add the HeapInspector to your `Podfile`.
```objc
pod 'HeapInspector'
```
and run `pod install` afterwards.

### Without CocoaPods
Download the repository into your project via git or just as zip.
Drag it the `HeapInspector` folder into your Xcode project. See following image.

Disable ARC for `NSObject+HeapInspector.m` by adding `-fno-objc-arc` to XCode's Build Phases -> Compile Source. See example images here: [Drag](README_Xtras/drag.png) and [disable ARC](README_Xtras/no_arc.png)

# How to use it

Make sure to import the header file
```objc
#import "HINSPDebug.h"
```


### Start
Just run the following to start HeapInspector in a separated debug window. The window can be moved on your screen in order to reach all your UI elements. The left circle button starts / stops the memory heap snapshot. See demo above.
```objc
[HINSPDebug startWithClassPrefix:@"RM"];
```
The prefix can be `nil`. We recommend to use a specific class prefix or even better a real class like `UIImageView`.
Or just run to record all NSObject subclasses
```objc
[HINSPDebug start];
```

### Stop
Stopping and removing the inspector's window goes with
```objc
[HINSPDebug stop];
```

Just call the start/stop methods at app launch or via your custom button.

### Backtrace record
HeapInspector can also record the backtrace for each object that received an alloc, retain, release or dealloc.
**Notice**: This has a large performance impact. Use this only with very specific recorded classes or small apps.
Start the backtrace with
```objc
[HINSPDebug recordBacktraces:YES]; 
```

# Example project
HeapInspector comes with an example project. There you will see a lot of mistakes made with the memory design.  
* `strong` delegate properties
* `NSTimer` that is not being invalidated properly
*  Holding objects longer than needed. `strong` property for the `UIViewController` that is pushed onto the `UINavigationController` stack

# Todo
- Test with Swift

# References, Inspirations & Thanks
* [FLEX](https://github.com/flipboard/flex) by Flipboard's iOS developers
* [Mike Ash](https://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html) Friday Q&A Automatic Reference Counting
* [Clang](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) Objective-C Automatic Reference Counting (ARC)

# Author
* [Christian Menschel](http://github.com/tapwork) ([@cmenschel](https://twitter.com/cmenschel))

# License
[MIT](LICENSE.md)
