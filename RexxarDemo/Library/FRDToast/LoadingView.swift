//
//  LoadingView.swift
//  Frodo
//
//  Created by 李俊 on 15/12/7.
//  Copyright © 2015年 Douban Inc. All rights reserved.
//

import UIKit

private let animationDuration: TimeInterval = 2.4

@objc class LoadingView: UIView {

  var lineWidth: CGFloat = 5 {
    didSet {
      setNeedsLayout()
    }
  }

  var strokeColor = UIColor(hex: 0x42BD56) {
    didSet {
      ringLayer.strokeColor = strokeColor.cgColor
      rightPointLayer.strokeColor = strokeColor.cgColor
      leftPointLayer.strokeColor = strokeColor.cgColor
    }
  }

  fileprivate let ringLayer = CAShapeLayer()
  fileprivate let pointSuperLayer = CALayer()
  fileprivate let rightPointLayer = CAShapeLayer()
  fileprivate let leftPointLayer = CAShapeLayer()
  fileprivate var isAnimating = false

  init(frame: CGRect, color: UIColor?) {
    super.init(frame: frame)
    strokeColor = color ?? strokeColor

    ringLayer.contentsScale = UIScreen.main.scale
    ringLayer.strokeColor = strokeColor.cgColor
    ringLayer.fillColor = UIColor.clear.cgColor
    ringLayer.lineCap = kCALineCapRound
    ringLayer.lineJoin = kCALineJoinBevel

    layer.addSublayer(ringLayer)
    layer.addSublayer(pointSuperLayer)

    rightPointLayer.strokeColor = strokeColor.cgColor
    rightPointLayer.lineCap = kCALineCapRound
    pointSuperLayer.addSublayer(rightPointLayer)

    leftPointLayer.strokeColor = strokeColor.cgColor
    leftPointLayer.lineCap = kCALineCapRound
    pointSuperLayer.addSublayer(leftPointLayer)

    NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let centerPoint = CGPoint(x: bounds.width/2, y: bounds.height/2)
    let radius = bounds.width/2 - lineWidth
    let path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle:CGFloat(-M_PI), endAngle: CGFloat(M_PI * 0.6), clockwise: true)

    ringLayer.lineWidth = lineWidth
    ringLayer.path = path.cgPath
    ringLayer.frame = bounds

    let x = bounds.width/2 - CGFloat(sin(M_PI * 50.0/180.0)) * radius
    let y = bounds.height/2 - CGFloat(sin(M_PI * 40.0/180.0)) * radius
    let rightPoint = CGPoint(x: bounds.width - x, y: y)
    let leftPoint = CGPoint(x: x, y: y)

    let rightPointPath = UIBezierPath()
    rightPointPath.move(to: rightPoint)
    rightPointPath.addLine(to: rightPoint)
    rightPointLayer.path = rightPointPath.cgPath
    rightPointLayer.lineWidth = lineWidth

    let leftPointPath = UIBezierPath()
    leftPointPath.move(to: leftPoint)
    leftPointPath.addLine(to: leftPoint)
    leftPointLayer.path = leftPointPath.cgPath
    leftPointLayer.lineWidth = lineWidth

    pointSuperLayer.frame = bounds
  }

  func startAnimation() {

    if isAnimating { return }
    pointSuperLayer.isHidden = false

    let keyTimes = [NSNumber(value: 0 as Double), NSNumber(value: 0.216 as Double), NSNumber(value: 0.396 as Double), NSNumber(value: 0.8 as Double), NSNumber(value: 1 as Int32)]

    // pointSuperLayer animation

    let pointKeyAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
    pointKeyAnimation.duration = animationDuration
    pointKeyAnimation.repeatCount = Float.infinity
    pointKeyAnimation.values = [0, (2 * M_PI * 0.375 + 2 * M_PI), (4 * M_PI), (4 * M_PI), (4 * M_PI + 0.3 * M_PI)]
    pointKeyAnimation.keyTimes = keyTimes
    pointSuperLayer.add(pointKeyAnimation, forKey: nil)

    // ringLayer animation

    let ringAnimationGroup = CAAnimationGroup()

    let ringKeyRotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
    ringKeyRotationAnimation.values = [0, (2 * M_PI), (M_PI/2 + 2 * M_PI), (M_PI/2 + 2 * M_PI), (4 * M_PI)]
    ringKeyRotationAnimation.keyTimes = keyTimes
    ringAnimationGroup.animations = [ringKeyRotationAnimation]

    let ringKeyStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
    ringKeyStartAnimation.values = [0, 0.25, 0.35, 0.35, 0]
    ringKeyStartAnimation.keyTimes = keyTimes
    ringAnimationGroup.animations?.append(ringKeyStartAnimation)

    let ringKeyEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
    ringKeyEndAnimation.values = [1, 1, 0.9, 0.9, 1]
    ringKeyEndAnimation.keyTimes = keyTimes
    ringAnimationGroup.animations?.append(ringKeyEndAnimation)

    ringAnimationGroup.duration = animationDuration
    ringAnimationGroup.repeatCount = Float.infinity
    ringLayer.add(ringAnimationGroup, forKey: nil)

    // pointAnimation

    let rightPointKeyAnimation = CAKeyframeAnimation(keyPath: "lineWidth")
    rightPointKeyAnimation.values = [lineWidth, lineWidth, lineWidth * 1.4, lineWidth * 1.4, lineWidth]
    rightPointKeyAnimation.keyTimes = [NSNumber(value: 0 as Double), NSNumber(value: 0.21 as Double), NSNumber(value: 0.29 as Double), NSNumber(value: 0.88 as Double), NSNumber(value: 0.96 as Double)]
    rightPointKeyAnimation.duration = animationDuration
    rightPointKeyAnimation.repeatCount = Float.infinity
    rightPointLayer.add(rightPointKeyAnimation, forKey: nil)

    let leftPointKeyAnimation = CAKeyframeAnimation(keyPath: "lineWidth")
    leftPointKeyAnimation.values = [lineWidth, lineWidth, lineWidth * 1.4, lineWidth * 1.4, lineWidth]
    leftPointKeyAnimation.keyTimes = [NSNumber(value: 0 as Double), NSNumber(value: 0.31 as Double), NSNumber(value: 0.39 as Double), NSNumber(value: 0.8 as Double), NSNumber(value: 0.88 as Double)]
    leftPointKeyAnimation.duration = animationDuration
    leftPointKeyAnimation.repeatCount = Float.infinity
    leftPointLayer.add(leftPointKeyAnimation, forKey: nil)

    isAnimating = true
  }

  func stopAnimation() {
    pointSuperLayer.removeAllAnimations()
    ringLayer.removeAllAnimations()
    rightPointLayer.removeAllAnimations()
    leftPointLayer.removeAllAnimations()

    isAnimating = false
  }

  func setPercentage(_ percent: CGFloat) {
    pointSuperLayer.isHidden = true
    ringLayer.strokeEnd = percent
  }

  @objc fileprivate func appWillEnterForeground() {
    if isAnimating {
      isAnimating = false
      startAnimation()
    }
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    if newWindow != nil && isAnimating {
      isAnimating = false
      startAnimation()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
