# Rexxar iOS

[![Language](https://img.shields.io/badge/language-ObjC-blue.svg)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)
[![iOS](https://img.shields.io/badge/iOS-7.0-green.svg)]()

**Rexxar** 是一个针对移动端的混合开发框架。现在支持 Android 和 iOS 平台。`Rexxar-iOS` 是 Rexxar 在 iOS 系统上的客户端实现。

通过 Rexxar，你可以使用包括 javascript，css，html 在内的传统前端技术开发移动应用。Rexxar 的客户端实现 Rexxar Container 对于 Web 端使用何种技术并无要求。我们现在的 Rexxar 的前端实现 Rexxar Web，以及 Rexxar Container 在两个平台的实现 Rexxar-iOS 和 Rexxar-Android 项目中所带的 Demo 都使用了 [React](https://facebook.github.io/react/)。但你完全可以选择自己的前端框架在 Rexxar Container 中进行开发。

Rexxar-iOS 现在支持 iOS 7 及以上版本。


## Rexxar 简介

关于 Rexxar 的整体介绍，可以查看文档：[Rexxar 简介](/docs/INTRODUTION.md)。

关于 Rexxar Android，可以访问：[https://www.github.com/douban/rexxar-android](https://www.github.com/douban/rexxar-android)。

关于 Rexxar Web，可以访问：[https://www.github.com/douban/rexxar-web](https://www.github.com/douban/rexxar-web)。


## 安装

### 安装 Cocoapods

[CocoaPods](http://cocoapods.org) 是一个 Objective-c 和 Swift 的依赖管理工具。你可以通过以下命令安装 CocoaPods：

```bash
$ gem install cocoapods
```

### Podfile

```ruby
target 'TargetName' do
  pod 'Rexxar', :git => 'https://github.com/douban/rexxar-ios.git', :commit => '0.1.0'
end
```

然后，运行以下命令：

```bash
$ pod install
```


## 使用

你可以查看 Demo 中的例子。了解如何使用 Rexxar。Demo 给出了完善的示例。

Demo 中使用 github 的 raw 文件服务提供一个简单的路由表文件 routes.json，demo.html 以及相关 javascript 资源的访问服务。在你的线上服务中，当然会需要一个真正的生产环境，以应付更大规模的路由表文件，以及 javascript，css，html 资源文件的访问。你可以使用任何服务端框架。Rexxar 对服务端框架并无要求。`RXRConfig` 提供了对路由表文件地址的配置接口。下一节描述了配置方法。

### 配置 RXRConfig

#### 设置路由表文件 api：

```Swift
  RXRConfig.setRoutesMapURL(NSURL(string:"https://raw.githubusercontent.com/lincode/rexxar-ios/master/Web/routes.json)!)
```

Rexxar 使用 url 来标识页面。提供一个正确的 url 就可以创建对应的 RXRViewController。路由表提供了每个 url 对应的 html 资源的下载地址。Demo 中的路由表如下：

```json
{
    "items": [{
        "remote_file": "https://raw.githubusercontent.com/lincode/rexxar-ios/master/Web/rexxar/demo-dd19d987ef.html",
        "deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
        "uri": "douban://douban.com/rexxar_demo[/]?.*"
    }],
    "partial_items": [{
        "remote_file": "https://raw.githubusercontent.com/lincode/rexxar-ios/master/Web/rexxar/demo-dd19d987ef.html",
        "deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
        "uri": "douban://partial.douban.com/rexxar_demo/_.*"
    }],
    "deploy_time": "Thu, 04 Aug 2016 07:43:47 GMT",
}
```

#### 设置预置资源文件路径

```Swift
  RXRConfig.setRoutesResourcePath("rexxar")
```

使用 Rexxar 一般会预置一份路由表，以及资源文件在应用包中。这样就可以减少用户的下载，加快第一次打开页面的速度。在没有网络的情况下，如果没有数据请求的话，页面也可访问。这都有利于用户体验。

注意，如果设置了预置资源文件路径，即意味着在应用包内预置一份资源文件。这个文件夹需要是 folder references 类型，即在 Xcode 中呈现为蓝色文件夹图标。创建方法是将文件夹拖入 Xcode 项目，选择 Create folder references 选项。

#### 设置缓存路径

```Swift
  RXRConfig.setRoutesCachePath("com.douban.RexxarDemo.rexxar")
```

以上配置设置了缓存路径。缓存文件夹存在的目的也是减少资源文件的下载次数，加快打开页面的速度。使得用户可以得到近似原生页面的页面加载体验。

缓存资源文件一般会出现在 Rexxar 部署了一次路由表的更新之后。这也是 Rexxar 支持`热部署`的方法：由路由表控制资源文件的更新。一般可以让应用定期访问路由表。比如，在开启应用时，或者关闭应用时更新路由表。更新路由表的方法如下：

```Swift
  RXRViewController.updateRouteFiles(completion: nil)
```

如果，新的路由表中出现了 html 文件的更新，或者出现了新的 url。也就是说这些文件并不存在于预置资源文件夹中，Rexxar Container 就会在下载完路由表之后，主动下载新资源，并将新资源储存在缓存文件夹中。

#### 预置资源文件和缓存文件关系

正常程序逻辑下，预置资源文件夹存在的资源，就不会再去服务器下载，也就不会有缓存的资源文件。

在进入一个 RXRViewController 时，会读取资源文件。在读取时，Rexxar Container 先读取缓存文件，如果存在就使用缓存文件。如果缓存文件不存在，就读取预置资源文件。如果，预置资源文件也不存在。RXRViewController 会尝试更新一次路由表，下载路由表中新出现的资源，并再次尝试读取缓存资源文件。如果仍然不存在，就会出现页面错误。

读取顺序如下：

1. 缓存文件夹中读取 html 文件；
2. 预置资源文件夹中读取 html 文件；
3. 重新下载路由表 Routes.json，遍历路由表将新的 html 文件下载到缓存文件夹。再次尝试从缓存文件夹读取 html 文件；

以上三步中，任何一步读取成功就停止，并返回读取的结果。如果，三步都完成了仍没有找到文件，就会出现页面错误。

有了预置资源文件和缓存文件的双重保证，一般用户打开 Rexxar 页面时都不会临时向服务器请求资源文件。这大大提升了用户打开页面的体验。

### 使用 RXRViewController

你可以直接使用 `RXRViewController` 作为你的混合开发客户端容器。或者你也可以继承 `RXRViewController`，在 `RXRViewController` 基础上实现你自己的客户端容器。在 Demo 中，创建了 `DemoRXRViewController`，它继承于 `RXRViewController`。

为了初始化 RXRViewController，你需要只一个 url。在路由表文件 api 提供的路由表中可以找到这个 url。这个 url 标识了该页面所需使用的资源文件的位置。Rexxar Container 会通过 url 在路由表中寻找对应的 javascript，css，html 资源文件。

```Swift
  let controller = RXRViewController(URI: uri)
  let titleWidget = RXRNavTitleWidget()
  let alertDialogWidget = RXRAlertDialogWidget()
  controller.activities = [titleWidget, alertDialogWidget]
  navigationController?.pushViewController(controller, animated: true)
```


## 定制你自己的 Rexxar Container

首先，可以继承 `RXRViewController`，在 `RXRViewController` 基础上以实现你自己客户端容器。

我们暴露了三类接口。供开发者更方便地扩展属于自己的特定功能实现。

### 定制 RXRWidget

Rexxar Container 提供了一些原生 UI 组件，供 Rexxar Web 使用。RXRWidget 是一个 Objective-C 协议（Protocol）。该协议是对这类原生 UI 组件的抽象。如果，你需要实现某些原生 UI 组件，例如，弹出一个 Toast，或者添加原生效果的下拉刷新，你就可以实现一个符合 RXRWidget 协议的类，并实现以下三个方法：`canPerformWithURL:`，`prepareWithURL:`，`performWithController:`。

在 Demo 中可以找到一个例子：`RXRNavTitleWidget` ，通过它可以设置导航栏的标题文字。

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

我们常常需要在 Rexxar Container 和 Rexxar Web 之间做数据交互。比如 Rexxar Container 可以为 Rexxar Web 提供一些计算结果。如果你需要提供一些由原生代码计算的数据给 Rexxar Web 使用，你就可以选择实现 RXRContainerAPI 协议（Protocol），并实现以下三个方法：`shouldInterceptRequest:`, `responseWithRequest:`, `responseData`。

在 Demo 中可以找到一个例子：`RXRLocContainerAPI`。这个例子中，`RXRLocContainerAPI` 返回了设备所在城市信息。当然，这个 ContainerAPI 仅仅是一个示例，它提供的是一个假数据，数据永远不会变化。你当然可以遵守 `RXRContainerAPI` 协议，实现一个类似的但是数据是真实的功能。

### 定制 RXRDecorator

如果你需要修改运行在 Rexxar Container 中的 Rexxar Web 所发出的请求。例如，在 http 头中添加登录信息，你可以实现 `RXRDecorator` 协议（Protocol），并实现这两个方法：`shouldInterceptRequest:`, `prepareWithRequest:`。

在 Demo 中可以找到一个例子：`RXRAuthDecorator`。这个例子为 Rexxar Web 发出的请求添加了登录信息。


## Rexxar 的公开接口

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
  - `RXRContainerIntercepter`
  - `RXRContainerAPI`

* Decorator
  - `RXRRequestIntercepter`
  - `RXRDecorator`
  - `RXRRequestDecorator`

* Util
  - `NSURL+Rexxar`
  - `NSDictionary+RXRMultipleItem`


## Partial RXRViewController

如果，你发现一个页面无法全部使用 Rexxar 实现。你可以在一个原生页面内内嵌一个 RXRViewController，部分功能使用原生实现，另一部分功能使用 Rexxar 实现。

Demo 中的 PartialRexxarViewController 给出了一个示例。


## 未来可能的改进

使用 WKWebView 替代 UIWebView 是一个长远的目标。WKWebView 在速度和内存消耗上都优于 UIWebView。但是，WKWebView 并不完善。对于 Rexxar iOS Container 而言，最重要的缺陷是不支持使用 NSURLProtocol 截获 WKWebView 中发出的网络请求。所以在现有的 Rexxar 的实现中，并没有使用 WKWebView。但是，我们会持续努力，以寻找切换至 WKWebView 的可能性。


## Unit Test

在项目的 RexxarTests 文件夹下可以找到一系列单元测试。这些单元测试可以通过命令 `cmd+u` 在 Xcode 中运行。单元测试除了可以验证代码的正确性之外，还提供了如何使用这些代码的示例。可以查看这些单元测试，以了解如何使用 Rexxar。


## License

Rexxar is released under the MIT license. See LICENSE for details.
