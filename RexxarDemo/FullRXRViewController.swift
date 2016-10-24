//
//  FullRXRViewController.swift
//  RexxarDemo
//
//  Created by GUO Lin on 8/19/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

import UIKit

class FullRXRViewController: RXRViewController {


  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.white

    // Widgets
    let pullRefreshWidget = RXRPullRefreshWidget()
    let titleWidget = RXRNavTitleWidget()
    let alertDialogWidget = RXRAlertDialogWidget()
    let toastWidget = RXRToastWidget()
    let navMenuWidget = RXRNavMenuWidget()
    widgets = [titleWidget, alertDialogWidget, pullRefreshWidget, toastWidget, navMenuWidget]

    // ContainerAPIs
    let geoContainerAPI = RXRGeoContainerAPI()
    let logContainerAPI = RXRLogContainerAPI()
    RXRContainerInterceptor.setContainerAPIs([geoContainerAPI, logContainerAPI])
    let _  = RXRContainerInterceptor.register()

    // Decorators
    let headers = ["Customer-Authorization": "Bearer token"]
    let parameters = ["apikey": "apikey value"]
    let requestDecorator = RXRRequestDecorator(headers: headers, parameters: parameters)
    RXRRequestInterceptor.setDecorators([requestDecorator])
    URLProtocol.registerClass(RXRRequestInterceptor.self)
    let _ = RXRRequestInterceptor.register()
  }

  deinit {
    RXRContainerInterceptor.unregisterInterceptor()
    RXRRequestInterceptor.unregisterInterceptor()
  }
}
