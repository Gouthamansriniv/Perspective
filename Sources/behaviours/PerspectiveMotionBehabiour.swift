/*
 * PerspectiveView
 *
 * Copyright 2018-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import CoreMotion
import Foundation
import UIKit

public final class PerspectiveMotionBehabior: PerspectiveBehaviour {
  private var delegate: PerspectiveBehaviourDelegate?

  public let identifier = "MotionBehavior"
  public private(set) var offset: CGPoint = .zero

  private let lowPassRatio: CGFloat = 0.25
  private let motionManager = CMMotionManager()
  private lazy var backgroundQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.qualityOfService = .userInteractive

    return queue
  }()

  deinit {
    if motionManager.isAccelerometerActive {
      motionManager.stopAccelerometerUpdates()
    }
  }

  public func link(to view: UIView, delegate: PerspectiveBehaviourDelegate) {
    guard motionManager.isAccelerometerAvailable else { return }

    self.delegate = delegate
    self.motionManager.accelerometerUpdateInterval = 1 / 60

    self.motionManager.startAccelerometerUpdates(to: backgroundQueue) { [weak self] data, error in
      guard let weakSelf = self, let data = data else { return }

      // Low-pass filter to smooth the measurements
      let tiltX = Int(weakSelf.offset.x * (1 - weakSelf.lowPassRatio) + CGFloat(data.acceleration.x) * weakSelf.lowPassRatio * 100)
      let tiltY = Int(weakSelf.offset.y * (1 - weakSelf.lowPassRatio) + CGFloat(data.acceleration.y) * weakSelf.lowPassRatio * 100)

      if Int(weakSelf.offset.x) != tiltX || Int(weakSelf.offset.y) != tiltY {
        let tilt = CGPoint(x: tiltX, y: tiltY)

        DispatchQueue.main.async {
          weakSelf.offset = tilt

          weakSelf.delegate?.behaviour(weakSelf, didUpdate: tilt)
        }
      }
    }
  }

  public func unlink() {
    delegate = nil
    motionManager.stopAccelerometerUpdates()
  }

  public func dimensionsDidUpdate(bounds: CGRect, contentSize: CGSize) {}
}