//
//  DemoRXRViewController.swift
//  Rexxar
//
//  Created by GUO Lin on 8/19/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

import UIKit

class DemoRXRViewController: RXRViewController {


  override func viewDidLoad() {
    super.viewDidLoad()

    let pullRefreshWidget = RXRPullRefreshWidget()
    let titleWidget = RXRNavTitleWidget()
    let alertDialogWidget = RXRAlertDialogWidget()
    let toastWidget = RXRToastWidget()
    let navMenuWidget = RXRNavMenuWidget()

    widgets = [titleWidget, alertDialogWidget, pullRefreshWidget, toastWidget, navMenuWidget]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let locContainerAPI = RXRLocContainerAPI()

    RXRContainerIntercepter.setContainerAPIs([locContainerAPI])
    URLProtocol.registerClass(RXRContainerIntercepter.self)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    URLProtocol.unregisterClass(RXRContainerIntercepter.self)
  }

}
