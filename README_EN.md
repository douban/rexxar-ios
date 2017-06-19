# Rexxar iOS

[![Test Status](https://travis-ci.org/douban/rexxar-ios.svg?branch=master)](https://travis-ci.org/douban/rexxar-ios)
[![IDE](https://img.shields.io/badge/XCode-8-blue.svg)]()
[![iOS](https://img.shields.io/badge/iOS-7.0-green.svg)]()
[![Language](https://img.shields.io/badge/language-ObjC-blue.svg)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)

**Rexxar** is a cross-platform library for hybrid mobile application. It supports both iOS and Android. `Rexxar iOS` is Rexxar's Container in iOS.

Rexxar brings the ease of web technologies, including HTML, JavaScript and CSS, into mobile application development. We have used [React](https://facebook.github.io/react/) for the web front demo, but a Rexxar Container does not confine your choice of web front end framework. You can use your own web front side framework to develop the application in Rexxar Container.

Rexxar iOS supports iOS 7.0 and above.


## Rexxar

About Rexxar's integral introduction, please check this article: [豆瓣的混合开发框架 -- Rexxar](http://lincode.github.io/Rexxar-OpenSource). In order to bring its full power, Rexxar iOS or Android need a Web implementation to offer the routes map api and the Web resources including HTML, JavaScript, CSS.

Rexxar includes threes libraries:

- Rexxar Web：[https://github.com/douban/rexxar-web](https://github.com/douban/rexxar-web)。
- Rexxar Android：[https://github.com/douban/rexxar-android](https://github.com/douban/rexxar-android)。
- Rexxar iOS：[https://github.com/douban/rexxar-ios](https://github.com/douban/rexxar-ios)。


## Installation

### Install Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C and Swift. You can install it with the following command:

```bash
$ gem install cocoapods
```

### Podfile

```ruby
target 'TargetName' do
  pod 'Rexxar', :git => 'https://github.com/douban/rexxar-ios.git', :commit => '0.2.1'
end
```

Then, run the following command:

```bash
$ pod install
```


## Usage

Please check out RexxarDemo for demo usage. We have used Github raw file as the routes map api. You would want to dynamically generate the routes map via an api endpoint, and need a real server to serve HTML, Javascript, and CSS in production. 

It's possible to change this endpoint with RXRConfig, see below for details.

### Configure routes map api address

```Swift
  RXRConfig.setRoutesMapURL(NSURL(string:"https://raw.githubusercontent.com/douban/rexxar-web/master/example/dist/routes.json)!)
```

Rexxar use url to identify the page in mobile application. With a valid url, we can create a RXRViewController. There is the map from url to HTML resources in the routes map api file. In the Demo, you can see a routes map api file like this:

```json
{
    "items": [{
        "remote_file": "https://raw.githubusercontent.com/douban/rexxar-web/master/example/dist/rexxar/demo-252452ae58.html",
        "deploy_time": "Sun, 09 Oct 2016 07:43:47 GMT",
        "uri": "douban://douban.com/rexxar_demo[/]?.*"
    }],
    "partial_items": [{
        "remote_file": "https://raw.githubusercontent.com/douban/rexxar-web/master/example/dist/rexxar/demo-252452ae58.html",
        "deploy_time": "Sun, 09 Oct 2016 07:43:47 GMT",
        "uri": "douban://partial.douban.com/rexxar_demo/_.*"
    }],
    "deploy_time": "Sun, 09 Oct 2016 07:43:47 GMT",
}
```

### Configure the resource path

```Swift
  RXRConfig.setRoutesResourcePath("rexxar")
```

We usually ship a copy of HTML resource files with the application's release package, in order to boost the initial load of the hybrid page. You can set the local path to the folder that contains the resource files with this API. Please be reminded that the folder type in Xcode must be set as `folder reference`, with a blue folder icon; instead of the `group` type with a yellow icon.

### Configure the cache path

```Swift
  RXRConfig.setRoutesCachePath("com.douban.RexxarDemo.rexxar")
```

Cache is also used to improve performance over routing. Rexxar can be set to check the routes map periodically and save the latest version in the cache. By deploying different path with the routes, it's possible to do a `hot deployment`, with which you can update the page just by replacing the resource file, and no need to go through the tedious process of asking a new release via App Store.

This is the way to call to update routes map file:

```Swift
  RXRViewController.updateRouteFiles(completion: nil)
```

### Use `RXRViewController`

You can use `RXRViewController` directly as your hybrid container. Or you can inherit `RXRViewController` to implement your own Rexxar Container. In RexxarDemo, we implement `FullRXRViewController` inheriting from `RXRViewController`.

To initialize a RXRViewController, you just need a valid url. This url should exist in the routes map file. Every url represents a page in app. Rexxar Container search the page's resource files via the url in the routes map file.

```Swift
     let controller = RXRViewController(URI: uri)
     let titleWidget = RXRNavTitleWidget()
     let alertDialogWidget = RXRAlertDialogWidget()
     controller.activities = [titleWidget, alertDialogWidget]
     navigationController?.pushViewController(controller, animated: true)
```


## Customize Rexxar Container

First, you inherit `RXRViewController` to implement your own Rexxar Container.

Then, you use the three interfaces provided by Rexxar to make your customization easier.

### Create your own RXRWidget

The `RXRWidget` protocol provides threes three methods: `canPerformWithURL:`, `prepareWithURL:`, `performWithContoller:`. Override these three methods to conform the `RXRWidget` protocol to implement a native UI, for example displaying a toast or adding pull to refresh UI widget etc.

You can find an example `RXRNavTitleWidget` in Rexxar.

```Objective-C
@interface RXRNavTitleWidget ()

@property (nonatomic, copy) NSString *title;

@end


@implementation RXRNavTitleWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/nav_title"]) {
    return true;
  }
  return false;
}

- (void)prepareWithURL:(NSURL *)URL
{
  self.title = [[URL rxr_queryDictionary] rxr_itemForKey:@"title"];
}

- (void)performWithController:(RXRViewController *)controller
{
  if (controller) {
    controller.title = self.title;
  }
}

@end
```

### Create your own RXRContainerAPI

In order to offer information computed by native but consumed by web, for example, getting the device's GPS location information, you can create a class conforming to `RXRContainerAPI` protocol and implement the three methods: `shouldInterceptRequest:`, `responseWithRequest:`, `responseData`.

You can find an example `RXRLocContainerAPI` in RexxarDemo. In this example, `RXRLocContainerAPI` returns the city information. To reduce Demo's complexity, we create it as a mock with false and always the same city information. You can implement your own loc information service on the base of this example.

### Create your own RXRDecorator

If the modification of request from Rexxar Container is needed, for example, adding the authentication information in http header, you can inherit `RXRDecorator` and implementing two methods `shouldInterceptRequest:`, `prepareWithRequest:`.

In RexxarDemo, you will find an example of usage of `RXRRequestDecorator` in `FullRXRViewController` to add the authentication information in http request.


## Partial RXRViewcontroller

If a page cannot be fully implemented in HTML, you still have a choice to render the page partially with Rexxar. A partial RXRViewController allows you to write part of a page in HTML, and the reset of it in native code.

Check out class `PartialRexxarViewController` in RexxarDemo for example.


## Rexxar's public interfaces

* Rexxar Container
  - `RXRConfig`
  - `RXRViewController`

* Widget
  - `RXRWidget`
  - `RXRNavTitleWidget`
  - `RXRAlertDialogWidget`
  - `RXRPullRefreshWidget`

* ContainerAPI
  - `RXRNSURLProtocol`
  - `RXRContainerInterceptor`
  - `RXRContainerAPI`

* Decorator
  - `RXRRequestInterceptor`
  - `RXRDecorator`
  - `RXRRequestDecorator`

* Util
  - `NSURL+Rexxar`
  - `NSDictionary+RXRMultipleItem`


## Changelog

- 0.3.0   Replace UIWebView with WKWebView. NSURLProtocol is not supported in WKWebView. The body of the POST request will be clean when intercepted by NSURLProtocol. So you need to take care of that.

## Unit Test

Rexxar iOS includes a suite of unit tests within the RexxarTests subdirectory.


## License

The MIT License.
