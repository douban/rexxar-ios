//
//  ToastView.swift
//  FRDToast
//
//  Created by 李俊 on 15/11/11.
//  Copyright © 2015年 Douban Inc. All rights reserved.
//

import UIKit

private let horizonalMargin: CGFloat = 25
private let imageTitleMargin: CGFloat = 5
private let verticalMargin: CGFloat = 10

class ToastView: UIView {

  var titleFont = UIFont(name:"HelveticaNeue-Medium", size:15) {
    didSet {
      label.font = titleFont
    }
  }

  fileprivate var image: UIImage? {
    didSet {
      guard let image = image else {
        imageView?.removeFromSuperview()
        imageView = nil
        return
      }

      if imageView == nil {
        imageView = UIImageView()
        addSubview(imageView!)
      }
      imageView?.image = image
    }
  }

  fileprivate var loadingView: LoadingView?
  fileprivate var imageView: UIImageView?
  fileprivate let label: UILabel

  var loadingAnimateOrNot: Bool = false {
    didSet {
      if !loadingAnimateOrNot {
        loadingView?.removeFromSuperview()
        loadingView = nil
        return
      }

      if loadingView == nil {
        loadingView = LoadingView(frame: .zero, color: UIColor.white)
        loadingView?.lineWidth = 2
        addSubview(loadingView!)
      }
    }
  }

  override init(frame: CGRect) {
    label = UILabel(frame: frame)
    super.init(frame: frame)

    label.font = titleFont
    label.textColor = UIColor.white
    label.textAlignment = .center
    label.numberOfLines = 3
    addSubview(label)

    layer.shadowColor = UIColor(hex: 0x000000).cgColor
    layer.shadowOpacity = 0.3
    layer.shadowOffset = CGSize(width: 0, height: 0)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var labelMaxWidth = size.width - horizonalMargin * 2
    var width: CGFloat = horizonalMargin * 2
    if image != nil || loadingAnimateOrNot {
      let lineHeight = label.font.lineHeight
      var imageViewSize = CGSize.zero
      if let image = image {
        imageViewSize = computeLableSideViewSize(lineHeight, width:  size.width, imageContentSize: image.size)
      }

      if loadingAnimateOrNot {
        imageViewSize = computeLableSideViewSize(lineHeight, width:  size.width, imageContentSize: CGSize(width: lineHeight, height: lineHeight))
      }

      let imageViewWidth = imageViewSize.width
      width += (imageViewWidth + imageTitleMargin)
      labelMaxWidth -= (imageViewWidth + imageTitleMargin)
    }

    let maxSize = CGSize(width: labelMaxWidth, height: size.height)
    let labelSize = label.sizeThatFits(maxSize)
    width += labelSize.width
    return CGSize(width: width, height: labelSize.height + 2 * verticalMargin)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2

    var labelMaxWidth = bounds.width - horizonalMargin * 2
    var x = horizonalMargin
    if image != nil || loadingAnimateOrNot {
      let lineHeight = label.font.lineHeight
      var sideViewSize = CGSize.zero
      if let image = image {
        sideViewSize = computeLableSideViewSize(lineHeight, width:  bounds.width, imageContentSize: image.size)
        imageView?.frame = CGRect(x: x, y: (bounds.height - sideViewSize.height) / 2, width: sideViewSize.width, height: sideViewSize.height)
      }

      if loadingAnimateOrNot {
        sideViewSize = computeLableSideViewSize(lineHeight, width:  bounds.width, imageContentSize: CGSize(width: lineHeight, height: lineHeight))
        loadingView?.frame = CGRect(x: x, y: (bounds.height - sideViewSize.height) / 2, width: sideViewSize.width, height: sideViewSize.height)
      }

      x += (sideViewSize.width + imageTitleMargin)
      labelMaxWidth -= (sideViewSize.width + imageTitleMargin)
    }

    let maxSize = CGSize(width: labelMaxWidth, height: 0)
    let labelSize = label.sizeThatFits(maxSize)
    label.frame = CGRect(x: x, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
  }

  fileprivate func computeLableSideViewSize(_ height: CGFloat, width: CGFloat, imageContentSize: CGSize) -> CGSize {
    let width = imageContentSize.width / imageContentSize.height * height
    let labelSize = label.sizeThatFits(CGSize(width: width - horizonalMargin * 2 - width - imageTitleMargin, height: 0))
    if labelSize.height > height {
      return computeLableSideViewSize(labelSize.height, width: width, imageContentSize: imageContentSize)
    }

    return CGSize(width: width, height: height)
  }

}

// MARK: internal method

extension ToastView {

  func updateContent(_ title: String, color: UIColor, image toastImage: UIImage?, loadingAnimateOrNot bool: Bool) {
    label.text = title
    backgroundColor = color
    image = toastImage
    loadingAnimateOrNot = bool
    setNeedsLayout()
  }

  func startLoadingAnimation() {
    loadingView?.startAnimation()
  }

  func stopLoadingAnimation() {
    loadingView?.stopAnimation()
  }

}
