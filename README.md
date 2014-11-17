# HeapInspector

HeapInspector runs in your iOS app as a debug tool that **monitors the memory heap**, watch and inspect living objects.<br>

This helps you to identify memory issues directly in your app on your device without ever starting Instruments.

#### Memory heap snapshots
Basically you can inspect the entire heap and see all living objects of your iOS app. <br>
To be more precise you can record the heap for a specific part of the app. Like in Apple's Instruments the snapshot compares the heap before you started recording.
This helps you to find:
* Find retain cycles
* Find objects that are alive in memory but should be released
* Identify misused `static` objects like singletons or cached `UIImage`

For instance you can start the snapshot before you push a new `UIViewController` onto your `UINavigationController` stack and stop after popping the `UIViewController`.
<br><br>
Also you can inspect the recorded object and get detailed information like:

* Reference history (retain, strong, release) for NSObject subclasses
* Responder chain for recorded objects
* Screenshots the inspected UIView, UIViewController, UIImage
* Detailed information about the object (Description, frame, properties, iVars, methods)


# Why
Since ARC has been introduced we don't need to manage the `retai`n & `release` anymore. ARC is very powerful and made Objective C more stable. ARC decreased the number of crashes and improves the memory footprint.<br> ARC is technically doing a powerful job. It knows when to `retain`, `autorelease` and `release`.
<br>But ARC doesn't think about the overall architecture in order to design for a low memory footprint. You should be aware that you can still do a lot of things wrong. You can still get a memory pressure with ARC (even you don't need to release anymore).
* You can still create Retain Cycles => Link
* The `strong` property lifetime qualifier can be misused
* ...


# Installation
### Cocoapods

Just add the HeapInspector to your `Podfile`.
```objc
pod 'HeapInspector'
```
and run `pod install` afterwards.

### Without CocoaPods
Download the repository into your project via git or just as zip.
Drag it the `HeapInspector` folder into your Xcode project. See following image.

Disable ARC for `NSObject+HeapInspector.m` by adding `-fno-objc-arc` to XCode's Build Phases -> Compile Source. See following image.

# How to use it

Make sure to import the heder file
```objc
#import "HINSPDebug.h"
```


### Start
This starts HeapInspector in a separated debug window. The tool can be moved on our screen in order to reach your elements.  
```objc
[HINSPDebug startWithClassPrefix:@"RM"];
```
The prefix can be `nil`. In that case HeapInspector will record all `NSObject` subclasses. We recommend to use a specfic class prefix or even better real class like `UIImageView`.

### Stop
Stopping and removing the inspector's view goes with
```objc
[HINSPDebug stop];
```

Just call the start/stop methods at app launch or via your custom button .

### Backtrace record
HeapInspector can also record the backtrace for each object that received an alloc, retain, release or dealloc.
**Notice**: This has a large performance impact. Use this only with very specific recorded classes or small apps.

# Example project
HeapInspector comes with an example project. There you will see a lot of mistakes with the memory design.  
* `strong` delegate properties
* `NSTimer` that is not being invalivated properly
* `strong` property lifetime qualifier for `UIViewController` that is pushed onto the `UINavigationController` stack

This helps to demonstrate the use of the memory heap snapshots.

# Todo
- Test with Swift

# Thanks
