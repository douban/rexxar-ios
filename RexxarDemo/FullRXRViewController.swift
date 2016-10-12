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

    let pullRefreshWidget = RXRPullRefreshWidget()
    let titleWidget = RXRNavTitleWidget()
    let alertDialogWidget = RXRAlertDialogWidget()
    let toastWidget = RXRToastWidget()
    let navMenuWidget = RXRNavMenuWidget()

    widgets = [titleWidget, alertDialogWidget, pullRefreshWidget, toastWidget, navMenuWidget]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let geoContainerAPI = RXRGeoContainerAPI()
    let logContainerAPI = RXRLogContainerAPI()

    RXRContainerIntercepter.setContainerAPIs([geoContainerAPI, logContainerAPI])
    URLProtocol.registerClass(RXRContainerIntercepter.self)

    let headers = ["Customer-Authorization": "Bearer token"]
    let parameters = ["apikey": "apikey value"]
    let requestDecorator = RXRRequestDecorator(headers: headers, parameters: parameters)
    RXRRequestIntercepter.setDecorators([requestDecorator])

    URLProtocol.registerClass(RXRRequestIntercepter.self)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    URLProtocol.unregisterClass(RXRContainerIntercepter.self)

    URLProtocol.unregisterClass(RXRRequestIntercepter.self)
  }

}
