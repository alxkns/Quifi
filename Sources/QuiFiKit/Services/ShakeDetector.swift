import Foundation
import CoreGraphics

public final class ShakeDetector {
    private struct Sample {
        let x: Double
        let timestamp: Date
    }

    private var samples: [Sample] = []
    private var lastDirection: Int = 0 // -1 = left, 1 = right, 0 = unset
    private var directionChanges: Int = 0
    private var lastShakeTime: Date = .distantPast

    public var sensitivity: Double = 25.0 // Minimum px per reversal
    public var windowDuration: TimeInterval = 0.6 // 600 ms window
    public var requiredReversals: Int = 2
    public var cooldown: TimeInterval = 0.8

    public var onShakeDetected: (() -> Void)?

    public init(sensitivity: Double = 30.0) {
        self.sensitivity = sensitivity
    }

    public func reset() {
        samples.removeAll()
        lastDirection = 0
        directionChanges = 0
    }

    public func addPoint(x: Double, timestamp: Date = Date()) {
        guard timestamp.timeIntervalSince(lastShakeTime) > cooldown else { return }

        // Clean out samples older than the sliding window
        samples.removeAll { timestamp.timeIntervalSince($0.timestamp) > windowDuration }
        samples.append(Sample(x: x, timestamp: timestamp))

        guard samples.count >= 3 else { return }

        // Count direction reversals with sufficient amplitude
        var reversals = 0
        var currentDirection = 0
        var lastExtremeX = samples[0].x

        for sample in samples.dropFirst() {
            let delta = sample.x - lastExtremeX
            if abs(delta) >= sensitivity {
                let dir = delta > 0 ? 1 : -1
                if currentDirection != 0 && dir != currentDirection {
                    reversals += 1
                }
                currentDirection = dir
                lastExtremeX = sample.x
            }
        }

        if reversals >= requiredReversals {
            lastShakeTime = timestamp
            reset()
            onShakeDetected?()
        }
    }
}
