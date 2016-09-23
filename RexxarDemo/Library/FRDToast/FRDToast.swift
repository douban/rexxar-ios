//
//  FRDToast.swift
//  FRDToast
//
//  Created by 李俊 on 15/11/11.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

import UIKit

private let toastStartY: CGFloat = 50
private let toastFinalY: CGFloat = 80
private let miniToastShowTime: TimeInterval = 1.5
private let horizonalMargin: CGFloat = 25


@objc public enum FRDToastMaskType: Int {
  case `default`    // allow user interactions while Toast is displayed
  case clear      // don't allow user interactions
}


open class FRDToast: NSObject {

  /**
    设置文本字体，如果不设置该属性，缺省为 HelveticaNeue-Medium 字体。
   */
  open static var titleFont = UIFont(name:"HelveticaNeue-Medium", size:15) {
    didSet {
      sharedToast.toastView.titleFont = titleFont
    }
  }

  fileprivate static let sharedToast = FRDToast()

  fileprivate lazy var toastView: ToastView = {
    let view = ToastView()
    view.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
    return view
  }()

  fileprivate lazy var overlayView: UIControl = {

    let application = UIApplication.shared
    let window = application.delegate?.window ?? nil

    var windowBounds = CGRect.zero
    if let bounds = window?.bounds {
      windowBounds = bounds
    }

    let view = UIControl(frame: windowBounds)
    view.backgroundColor = UIColor.clear
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.isUserInteractionEnabled = false
    return view
  }()

  fileprivate var fadeOutTimer: Timer?
  fileprivate var toastShowTime = miniToastShowTime
  fileprivate var isFadeIn = false
  fileprivate var isFadeOut = false

  fileprivate func showToast(_ title: String, color: UIColor, maskType: FRDToastMaskType, image: UIImage?, loadingAnimateOrNot: Bool) {

    let application = UIApplication.shared
    let window = application.delegate?.window ?? nil

    var windowBounds = CGRect.zero
    if let bounds = window?.bounds {
      windowBounds = bounds
    }

    overlayView.frame = windowBounds
    if overlayView.superview == nil {
      for window in UIApplication.shared.windows {
        let windowOnMainScreen = window.screen == UIScreen.main
        let windowIsVisible = !window.isHidden && window.alpha > 0
        let windowLevelNormal = window.windowLevel == UIWindowLevelNormal

        if windowOnMainScreen && windowIsVisible && windowLevelNormal {
          window.addSubview(overlayView)
          break
        }
      }
    } else {
      overlayView.superview?.bringSubview(toFront: overlayView)
    }

    switch maskType {
    case .default:
      overlayView.isUserInteractionEnabled = false
    case .clear:
      overlayView.isUserInteractionEnabled = true
    }

    toastShowTime = displayDurationForTitle(title)
    if fadeOutTimer != nil {
      fadeOutTimer?.invalidate()
    }

    if toastView.superview != nil && !isFadeIn {
      let newToastView = ToastView()
      newToastView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
      newToastView.updateContent(title, color: color, image: image, loadingAnimateOrNot: loadingAnimateOrNot)
      switchToastViewWithAnimation(newToastView)
    } else {
      toastView.updateContent(title, color: color, image: image, loadingAnimateOrNot: loadingAnimateOrNot)
      addToastViewToOverLayView(toastView, center: nil)
      showToastWithAnimation()
    }
  }

  fileprivate func addToastViewToOverLayView(_ toastView: ToastView, center: CGPoint?) {
    let toastViewSize = toastView.sizeThatFits(CGSize(width: (overlayView.bounds.width - 2 * horizonalMargin), height: 0))
    toastView.bounds = CGRect(x: 0, y: 0, width: toastViewSize.width, height: toastViewSize.height)

    if toastView.superview == nil {
      overlayView.addSubview(toastView)
      toastView.alpha = 0
      let centerX = overlayView.bounds.width / 2
      toastView.center = (center != nil ? center! : CGPoint(x: centerX, y: toastStartY + toastView.bounds.height/2))
    }
  }

  fileprivate func showToastWithAnimation() {
    if isFadeIn {
      return
    }
    isFadeIn = true
    isFadeOut = false
    UIView.animate(withDuration: TimeInterval(0.5 * (1 - toastView.alpha)), delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
      self.toastView.center.y = toastFinalY + self.toastView.bounds.height/2
      self.toastView.alpha = 1
      }, completion: { (_) -> Void in
        if self.toastView.alpha == 1 {
          self.isFadeIn = false
          if self.toastView.loadingAnimateOrNot {
            self.toastView.startLoadingAnimation()
            return
          }

          self.fadeOutTimer = Timer(timeInterval: self.toastShowTime, target: self, selector: #selector(self.dismiss), userInfo: nil, repeats: false)
          RunLoop.main.add(self.fadeOutTimer!, forMode: RunLoopMode.commonModes)
        }
    })
  }

  fileprivate func switchToastViewWithAnimation(_ newToastView: ToastView) {
    let oldToastView = toastView
    if oldToastView.loadingAnimateOrNot {
      oldToastView.stopLoadingAnimation()
    }

    toastView = newToastView
    newToastView.alpha = 0
    addToastViewToOverLayView(newToastView, center: oldToastView.center)

    if isFadeOut || isFadeIn {
      oldToastView.removeFromSuperview()
      newToastView.alpha = oldToastView.alpha
      showToastWithAnimation()
      return
    }

    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
      oldToastView.alpha = 0
      }, completion: { (_) -> Void in
        if self.toastView.alpha == 0 {
          oldToastView.removeFromSuperview()
        }
    })

    UIView.animate(withDuration: TimeInterval(0.5 * (1 - newToastView.alpha)), delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
      newToastView.alpha = 1
      }, completion: nil)

    showToastWithAnimation()
  }

  @objc fileprivate func dismiss() {
    if isFadeOut || toastView.alpha == 0 {
      return
    }
    isFadeIn = false
    isFadeOut = true
    if toastView.loadingAnimateOrNot {
      toastView.stopLoadingAnimation()
    }

    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
      self.toastView.center.y = toastStartY
      self.toastView.alpha = 0
      }, completion: { (_) -> Void in
        if self.toastView.alpha == 0 {
          self.isFadeOut = false
          self.toastView.removeFromSuperview()
          self.overlayView.removeFromSuperview()
          self.fadeOutTimer = nil
        }
    })
  }

  fileprivate func showStaticToast(_ status: String, color: UIColor, image: UIImage?) {
    showToast(status, color: color, maskType: .default, image: image, loadingAnimateOrNot: false)
  }

  fileprivate func displayDurationForTitle(_ title: String) -> TimeInterval {
    let nsTitle = title as NSString
    let time = max(TimeInterval(nsTitle.length)*0.06 + 0.5, miniToastShowTime)
    return min(time, 5.0)
  }
}

// MARK: public function for show

public extension FRDToast {

  /**
    灰色，用于展示信息的提示。
 
   - Parameter status: 文本信息
   */
  class func showInfo(_ status: String) {
    showInfo(status, image: nil)
  }

  /**
    灰色，用于展示带图片的信息提示。

    - Parameter status: 文本信息
    - Parameter image: 图片
   */
  class func showInfo(_ status: String, image: UIImage?) {
    let color = UIColor(hex: 0x494949, alpha: 0.96)
    FRDToast.sharedToast.showStaticToast(status, color: color, image: image)
  }

  /**
    绿色，用于成功的提示。
    
    - Parameter status: 文本信息
   */
  class func showSuccess(_ status: String) {
    showSuccess(status, image: nil)
  }

  /**
   绿色，用于带图片的成功的提示。

   - Parameter status: 文本信息
   - Parameter image: 图片
   */
  class func showSuccess(_ status: String, image: UIImage?) {
    let color = UIColor(hex: 0x42bd56, alpha: 0.96)
    FRDToast.sharedToast.showStaticToast(status, color: color, image: image)
  }

  /**
    红色，用于失败、警告信息，比如某项操作失败，密码错误等。

   - Parameter status: 展示的文本信息
  */
 class func showError(_ status: String) {
    showError(status, image: nil)
  }

  /**
   红色，用于带图片的失败、警告信息，比如某项操作失败，密码错误等。

   - Parameter status: 展示的文本信息
   - Parameter image: 图片

   */
  class func showError(_ status: String, image: UIImage?) {
    let color = UIColor(hex: 0xff4055, alpha: 0.96)
    FRDToast.sharedToast.showStaticToast(status, color: color, image: image)
  }

  /**
   显示一个自己定制的 Toast。

   - Parameter status: 展示的文本信息
   - Parameter image: 图片
   - Parameter backgroundColor: 背景色
   - Parameter maskType: 交互类型
   */
  class func show(_ status: String, backgroundColor: UIColor, image: UIImage?, maskType: FRDToastMaskType) {
    FRDToast.sharedToast.showStaticToast(status, color: backgroundColor, image: image)
  }

  /**
   使 Toast 消失。
   */
  class func dismiss() {
    FRDToast.sharedToast.dismiss()
  }

  /**
   检查 Toast 的可见性。
   */
  class func isVisible() -> Bool {
    let toastView = FRDToast.sharedToast.toastView
    return toastView.superview != nil && toastView.alpha == 1.0
  }
}
