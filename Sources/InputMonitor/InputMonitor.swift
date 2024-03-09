import Combine
import IOKit
import Quartz

/// A class for monitoring input events.
open class InputMonitor {
    public static let shared: InputMonitor = InputMonitor()

    /// A boolean indicating if the monitor is currently monitoring input events.
    public private(set) var isMonitoring: Bool = false

    /// The types of events to monitor.
    public private(set) var events: [CGEventType] = [.keyDown, .flagsChanged]

    /// A publisher for input events.
    /// Use this publisher to receive `InputMonitorEvent` from the monitor.
    public var publisher: AnyPublisher<InputMonitorEvent, Never> { subject.eraseToAnyPublisher() }

    private var subject: PassthroughSubject<InputMonitorEvent, Never> = PassthroughSubject()
    private var runLoopSource: CFRunLoopSource?

    /// Start monitoring input events.
    /// - Parameter events: The type of events to monitor. Defaults to keyDown and flagsChanged.
    /// - Throws: An error of type InputMonitorError if the app does not have access to monitor input events.
    /// - Returns: A boolean indicating if the monitor was started successfully.
    public func start(events: [CGEventType] = [.keyDown, .flagsChanged]) throws {
        if isMonitoring { throw InputMonitorError.alreadyMonitoring("InputMonitor is already monitoring input events.") }
        if self.checkAccess() != .granted { throw InputMonitorError.insufficientPrivileges("InputMonitor was unable to start because it does not have the required permissions. Make sure to request access before calling start.") }

        self.events = events

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            let monitor = Unmanaged<InputMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            monitor.onEvent(type, keyCode, flags)
            return Unmanaged.passRetained(event)
        }

        let mask = events.reduce(0) { $0 | (1 << $1.rawValue) }
        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        tap.map {
            self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, $0, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: $0, enable: true)
            // CFRunLoopRun() will cause hang in test environment
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                CFRunLoopRun()
            } else {
                print("InputMonitor is running in test environment. It will not start monitoring input events.")
            }
            self.isMonitoring = true
        }
    }

    /// Stop monitoring input events.
    public func stop() {
        if let runLoopSource = self.runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CFRunLoopStop(CFRunLoopGetCurrent())
            self.runLoopSource = nil
            self.isMonitoring = false
        }
    }

    /// Request access to monitor input events. This must be called before calling start.
    /// This method will prompt the user to allow the app to monitor input events. Based on IOHIDRequestAccess.
    /// - Returns: A boolean indicating if the request was successful.
    public func requestAccess() -> Bool { IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) }

    /// Check if the app has access to monitor input events.
    /// This method will return the access level for the app and not giving prompt to the user. Backed by IOHIDCheckAccess.
    /// - Returns: An InputMonitorAccess value indicating the access level.
    public func checkAccess() -> InputMonitorAccess { InputMonitorAccess(rawValue: IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)) }

    private func onEvent(_ type: CGEventType, _ keyCode: Int64, _ flags: CGEventFlags) {
        if self.events.contains(type) {
            self.subject.send(InputMonitorEvent(type: type, keyCode: keyCode, flags: flags))
        }
    }
}

/// A struct representing an input event.
/// - type: A CGEventType of event.
/// - keyCode: The key code of the event.
/// - flags: The flags of the event.
public struct InputMonitorEvent {
    public let type: CGEventType
    public let keyCode: Int64
    public let flags: CGEventFlags
}

/// An enum representing the access level for monitoring input events.
/// Mapped from IOHIDAccessType.
/// - granted: The app has access to monitor input events.
/// - denied: The app does not have access to monitor input events.
/// - unknown: The access level is unknown.
public enum InputMonitorAccess {
    case granted
    case denied
    case unknown

    fileprivate init(rawValue: IOHIDAccessType) {
        switch rawValue {
            case kIOHIDAccessTypeGranted: self = .granted
            case kIOHIDAccessTypeDenied: self = .denied
            default: self = .unknown
        }
    }
}

/// An error type for InputMonitor.
/// - insufficientPrivileges: The app does not have access to monitor input events.
/// - unknown: An unknown error occurred.
public enum InputMonitorError: Error {
    case insufficientPrivileges(String)
    case alreadyMonitoring(String)
    case unknown
}
