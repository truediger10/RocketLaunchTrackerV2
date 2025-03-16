import Foundation
import SwiftUI
import Combine
import os

/// A utility for monitoring and optimizing app performance
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var frameTimeSubscription: AnyCancellable?
    private var frameTimeHistory: [Double] = []
    private let maxHistorySize = 120
    
    private(set) var currentFPS: Double = 60
    private(set) var hasPerformanceIssues = false
    
    private(set) var availableRAM: UInt64 = 0
    private(set) var usedRAM: UInt64 = 0
    
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "PerformanceMonitor")

    private init() {
        updateRAMUsage()
    }
    
    func startMonitoring() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        
        frameTimeSubscription = Timer.publish(every: 1.0/60.0, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recordFrameTime()
            }
        #endif
    }
    
    func stopMonitoring() {
        frameTimeSubscription?.cancel()
        frameTimeSubscription = nil
    }
    
    private func recordFrameTime() {
        let frameTime = CACurrentMediaTime()
        frameTimeHistory.append(frameTime)
        
        if frameTimeHistory.count > maxHistorySize {
            frameTimeHistory.removeFirst()
        }
        
        if frameTimeHistory.count >= 2 {
            let timeElapsed = frameTimeHistory.last! - frameTimeHistory.first!
            let measuredFPS = Double(frameTimeHistory.count - 1) / timeElapsed
            currentFPS = measuredFPS
            hasPerformanceIssues = measuredFPS < 45
            if hasPerformanceIssues {
                Self.logger.warning("Performance drop detected. Current FPS: \(measuredFPS)")            }
        }
    }
    
    private func updateRAMUsage() {
        let processInfo = ProcessInfo.processInfo
        #if DEBUG
        availableRAM = UInt64(processInfo.physicalMemory)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: 1) { reboundPointer in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), reboundPointer, &count)
            }
        }
        if result == KERN_SUCCESS {
            usedRAM = info.resident_size
        }
        #endif
    }
    
    var shouldEnableHeavyEffects: Bool {
        #if DEBUG
        return !hasPerformanceIssues && currentFPS > 55
        #else
        return isHighPerformanceDevice
        #endif
    }
    
    var isHighPerformanceDevice: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(validatingUTF8: ptr)
            }
        }
        if let model = modelCode {
            if model.contains("iPhone") {
                let version = model.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                if let versionNumber = Int(version), versionNumber >= 13 {
                    return true
                }
            }
            if model.contains("iPad") {
                if model.contains("iPad8") || model.contains("iPad9") || model.contains("iPad13") {
                    return true
                }
            }
        }
        return false
    }
    
    var recommendedParallaxMagnitude: CGFloat {
        if isHighPerformanceDevice {
            return 8.0
        } else if currentFPS > 45 {
            return 4.0
        } else {
            return 0.0
        }
    }
}
