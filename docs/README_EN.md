# Rexxar iOS

[![Build status](http://shields.dapps.douban.com/badge/qa-ci/peteris-rexxar-ios-inHouse)](http://qa-ci.intra.douban.com/job/peteris-rexxar-ios-inHouse)
[![Language](https://img.shields.io/badge/language-ObjC-blue.svg)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)
[![iOS](https://img.shields.io/badge/iOS-7.0-green.svg)]()

**Rexxar** is a Hybrid library for mobile application development. Now it supports iOS and Android platform. `Rexxar iOS` is Rexxar's Container in iOS.

With Rexxar, you can develop mobile application by traditional web techniques including javascript, html and css. Rexxar Container has not any requirements of web front side. Our demo in the web front side is implemented by [React](https://facebook.github.io/react/). You can use your own front side framework to develop the application in Rexxar Container.

Rexxar iOS Container supports iOS 7.0 and above systems.

## Installation

### Install Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C and Swift. You can install it with the following command:

```bash
$ gem install cocoapods
```

### Podfile

```ruby
target 'TargetName' do
  pod 'Rexxar', '~> 1.2.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

You can take a look at the example in RexxarDemo folder.

### Launch local server

Launch the local server for serving the routes map api.

```bash
$ python routes.py
``` 

Test by entering the url [http:\\localhost:5000](http:\\localhost:5000) in your browser. You will see the output as json format:

```json
{
	"items": [{
		"remote_file": "https://img1.doubanio.com/dae/rexxar/files/rexxar/demo-ffb8a4a9fa.html",
		"deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
		"uri": "douban://douban.com/rexxar_demo[/]?.*"
	}],
	"partial_items": [{
		"remote_file": "https://img1.doubanio.com/dae/rexxar/files/rexxar/demo-ffb8a4a9fa.html",
		"deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
		"uri": "douban://partial.douban.com/rexxar_demo/_.*"
	}],
	"deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
}
``` 

We use the python web framework [Flask](http://flask.pocoo.org/) to serve a local server for this demo. You need implement a real server in your real product serving the routes map api and html, css, javascript resources. You can use any server framework. Rexxar has not any requirement about the server framework. Rexxar offers the configuration interface of the routes map api address in `RXRConfig`. You can find the way to configure the address in next section.

### Configure with `RXRConfig`

Configure the routes map url and routes cache path.

```Swift
    RXRConfig.setRoutesMapURL(NSURL(string:"http://rexxar.douban.com/api/routes?edition=pre")!)
    RXRConfig.setRoutesCachePath("com.douban.RexxarDemo.rexxar")
```

### Use `RXRViewController`

You can use `RXRViewController` directly as your Hybrid container. Or you can inherit `RXRViewController` to implement your own Rexxar Container. In the RexxarDemo, We use `RXRViewController` directly.

To Initialize a RXRViewController, you just need a route uri. Your should find this uri in the routes map api served by the local server. Every uri represents a page. Rexxar Container search the page resources (html, css, javascript files) via the route uri.

```Swift
     let controller = RXRViewController(URI: uri)
     let titleWidget = RXRNavTitleWidget()
     let alertDialogWidget = RXRAlertDialogWidget()
     controller.activities = [titleWidget, alertDialogWidget]
     navigationController?.pushViewController(controller, animated: true)
```

## Customize your own Rexxar Container

### Create your own RXRWidget

If you want to implement a native UI feature which can be used by web, for example, displaying a toast and adding pull to refresh ui widget etc, you can inherit `RXRWidget` and implementing three methods: `canPerformWithURL:`, `prepareWithURL:`, `performWithContoller:`.

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

If you want to offer information computed by native but used by web, for example, getting the device's GPS location information, you can create an Object conforming to `RXRContainerAPI` protocol ant implementing three methods: `shouldInterceptRequest:`, `responseWithRequest:`, `responseData`.

You can find an example `RXRLocContainerAPI` in RexxarDemo. In this example `RXRLocContainerAPI` returns the city information. Of course, It's a container API offerring false and always the same city information. You can implement your own loc information service on the base of this example.

### Create your own RXRDecorator

If you want to modify the request sent by Rexxar Container, for example, adding the authentical information in http header, you can inherit `RXRDecorator` and implementing two methods `shouldInterceptRequest:`, `prepareWithRequest:`.

You can find an example `RXRAuthDecorator` in RexxarDemo.

## Architecture

* Rexxar Container
  - `RXRConfig`
  - `RXRViewController`

* Widget
  - `RXRWidget`
  - `RXRNavTitleWidget`
  - `RXRAlertDialogWidget`

* ContainerAPI
  - `RXRNSURLProtocol`
  - `RXRContainerIntercepter`
  - `RXRContainerAPI`

* Decorator
  - `RXRRequestIntercepter`
  - `RXRDecorator`
  - `RXRRequestDecorator`

* Util
  - `NSURL+Rexxar`
  - `NSDictionary+RXRMultipleItem`

## Unit Test

Rexxar iOS includes a suite of unit tests within the RexxarTests subdirectory. These tests can be run simply be executed the test action on the platform framework you would like to test.

## License

Rexxar is released under the MIT license. See LICENSE for details.
