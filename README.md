# Rexxar iOS

[![Build status](http://shields.dapps.douban.com/badge/qa-ci/peteris-rexxar-ios-inHouse)](http://qa-ci.intra.douban.com/job/peteris-rexxar-ios-inHouse)
[![Language](https://img.shields.io/badge/language-ObjC-blue.svg)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)
[![iOS](https://img.shields.io/badge/iOS-7.0-green.svg)]()

**Rexxar** 是一个针对移动端的混合开发框架。现在支持 Android 和 iOS 平台。`Rexxar-iOS` 是 Rexxar 在 iOS 系统上的客户端实现。

通过 Rexxar，你可以使用包括 javascript，css，html 在内的传统前端技术开发移动应用。Rexxar 的客户端实现 Rexxar Container 对于 Web 端使用何种技术并无要求。我们现在的 Rexxar 的前端实现 Rexxar-Web，以及 Rexxar Container 在两个平台的实现 Rexxar-iOS 和 Rexxar-Android 项目中所带的 Demo 都使用了 [React](https://facebook.github.io/react/)。但你完全可以选择自己的前端框架在 Rexxar-Container 中进行开发。

Rexxar-iOS 现在支持 iOS 7.0 及以上版本。


## 安装

### 安装 Cocoapods

[CocoaPods](http://cocoapods.org) 是一个 Objective-c 和 Swift 的依赖管理工具。你可以通过以下命令安装 CocoaPods：

```bash
$ gem install cocoapods
```

### Podfile

```ruby
target 'TargetName' do
  pod 'Rexxar', '~> 1.2.0'
end
```

然后，运行以下命令：

```bash
$ pod install
```

## 使用

你可以查看 RexxarDemo 中的例子。了解如何使用 Rexxar。RexxarDemo 给出了完善的实例。

### 启动本地服务器

启动本地服务器，提供路由文件 api 和资源文件的访问服务。启动命令如下：

```bash
$ python routes.py
``` 

在浏览器中输入以下 url [http://localhost:5000](http://localhost:5000)。你应该能看到如下类似的 json 格式的输出：

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

这个 Demo 中，我们使用 [Flask](http://flask.pocoo.org/) 启动了一个简单的本地服务器。在你的线上服务中，当然需要一个真正的生产环境的服务器，以应付更大规模的对路由文件 api，以及 javascript，css，html 这些资源文件的访问。你可以使用任何服务端框架。Rexxar 对服务端框架并不要求。`RXRConfig` 提供了对路由文件 api 地址的配置接口。下一节描述了配置方法。

### 配置 RXRConfig

配置路由文件 api，缓存路径：

```Swift
    RXRConfig.setRoutesMapURL(NSURL(string:"http://rexxar.douban.com/api/routes?edition=pre")!)
    RXRConfig.setRoutesCachePath("com.douban.RexxarDemo.rexxar")
    RXRConfig.setRoutesResourcePath("rexxar")
```

注意，如果自己配置 RoutesResourcePath，即意味着在打包好的包内预置一份资源文件。这样所有页面，即使在没有网络的情况下，也都可以访问。这个文件夹需要是 folder references 类型，即在 Xcode 中呈现为蓝色文件夹图标。创建方法是将文件夹拖入 Xcode 项目，选择 Create folder references 选项。

### 使用 RXRViewController

你可以直接使用 `RXRViewController` 作为你的混合开发客户端容器。或者你也可以继承 `RXRViewController`，在 `RXRViewController` 基础上以实现你自己客户端容器。在 RexxarDemo 中，我们直接使用了 `RXRViewController`。

为了初始化 RXRViewController，你需要只一个 url。在路由文件 api 提供的路由表中可以找到这个 url。这个 url 标识了该页面所需使用的资源文件的位置。Rexxar Container 会通过 url 在路由表中寻找对应的 javascript，css，html 资源文件。

```Swift
	let controller = RXRViewController(URI: uri)
	let titleWidget = RXRNavTitleWidget()
    let alertDialogWidget = RXRAlertDialogWidget()
    controller.activities = [titleWidget, alertDialogWidget]
    navigationController?.pushViewController(controller, animated: true)
```


## 定制你自己的 Rexxar Container

首先，可以继承 `RXRViewController`，在 `RXRViewController` 基础上以实现你自己客户端容器。

另外，我们暴露了三类接口。供开发者更方便地扩展属于自己的特定功能实现。

### 定制 RXRWidget

Rexxar Container 提供了一些原生 UI 组件供 Rexxar-Web 使用。RXRWidget 协议是对这类原生 UI 组件的抽象。如果，你需要实现某些原生 UI 组件，例如，弹出一个 Toast，或者添加原生效果的下拉刷新，你就可以实现一个符合 RXRWidget 协议的对象，并实现以下三个方法：`canPerformWithURL:`，`prepareWithURL:`，`performWithController:`。

你可以在 RexxarDemo 中找到一个 RXRNavTitleWidget 的例子，通过它可以设置导航栏的标题文字。

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

### 定制 RXRContainerAPI

Rexxar Container 和 Rexxar-Web 做数据上的交互。比如 Rexxar Container 可以为 Rexxar-Web 提供一些计算结果。RXRContainerAPI 协议是对这类 Rexxar Container 和 Rexxar-Web 之间的数据交互的抽象。如果你需要提供一些由原生代码计算的数据给 Rexxar-Web 使用，你可以实现 RXRContainerAPI 协议，并实现以下三个方法：`shouldInterceptRequest:`, `responseWithRequest:`, `responseData`。

你可以在 RexxarDemo 中找到一个例子：`RXRLocContainerAPI`。这个例子中，`RXRLocContainerAPI` 返回了设备所在城市信息。当然，这个 Container API 仅仅是一个实例，它提供的是一个假数据，数据永远不会变化。你当然可以遵守 `RXRContainerAPI` 协议，实现一个类似的功能。

### 定制 RXRDecorator

如果你需要修改运行在 Rexxar-Container 中的 Rexxar-Web 所发出的请求。例如，在 http 头中添加登录信息，你可以实现 `RXRDecorator` 协议，并实现这两个方法：`shouldInterceptRequest:`, `prepareWithRequest:`。

你可以在 RexxarDemo 中找到一个例子 `RXRAuthDecorator`。这个例子，为 Rexxar-Web 发出的请求添加了登录信息。


## Rexxar 的公开接口

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

在项目的 RexxarTests 文件夹下可以找到一系列单元测试。这些单元测试可以很容易地在 Xcode 中运行：cmd+u。单元测试在验证代码的正确性之外，还提供了如何使用这些代码的实例。可以查看这些单元测试，以了解如何使用 Rexxar。


## License

Rexxar is released under the MIT license. See LICENSE for details.
