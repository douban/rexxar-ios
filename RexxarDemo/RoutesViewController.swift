//
//  RoutesViewController.swift
//  Rexxar
//
//  Created by Tony Li on 11/25/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

import UIKit

class RoutesViewController: UITableViewController {

  fileprivate let URIs = [URL(string: "douban://douban.com/rexxar_demo")!,
                      URL(string: "douban://partial.douban.com/rexxar_demo/_.s")!]

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isTranslucent = false;

    title = "URIs"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return URIs.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = URIs[(indexPath as NSIndexPath).row].absoluteString
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let uri = URIs[(indexPath as NSIndexPath).row]
    if (indexPath as NSIndexPath).row == 0 {

      let controller = DemoRXRViewController(uri: uri)
      navigationController?.pushViewController(controller, animated: true)
      controller.view.backgroundColor = UIColor.white
    } else if (indexPath as NSIndexPath).row == 1 {
      navigationController?.pushViewController(PartialRexxarViewController(URI: uri), animated: true)
    }
  }

}
