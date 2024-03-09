# InputMonitor - Easy macOS global input monitoring! 
<a href="https://www.swift.org/"><img alt="Swift 5.10" src="https://img.shields.io/badge/Swift-5.10-%23F05237?style=for-the-badge&logo=swift&logoColor=%23F05237"/></a>
<a href="https://developer.apple.com/documentation/macos-release-notes/macos-catalina-10_15-release-notes"><img alt="Mac OS 10.15" src="https://img.shields.io/badge/macOS-10.15-white?style=for-the-badge&logo=Apple&logoColor=white"/></a>

This is a simple Swift Package developed to monitor global keyboard events in macOS, based on the [IOKit](https://developer.apple.com/documentation/iokit) and [Quartz Event Services](https://developer.apple.com/documentation/coregraphics/cgevent/).

InputMonitor gives you ability to request an **Input Monitoring** system permission and allows you to subscribe to input events with [Combine](https://developer.apple.com/documentation/combine).

## Usage

`InputMonitor` is a singleton that you can use to observe global keyboard events.

You can check Input Monitor access by calling `checkAccess` method and request access by calling `requestAccess` method.

```swift
if InputMonitor.shared.checkAccess() != .granted {
    InputMonitor.shared.requestAccess()
}
```

Start and stop monitoring by calling `start` and `stop` methods.

```swift
InputMonitor.shared.start()

print("Input Monitor status: \(InputMonitor.shared.isMonitoring)")

InputMonitor.shared.stop()
```

Start method accepts optional array of `CGEventFlags` to filter possible events by type.

```swift
InputMonitor.shared.start(events: [.keyDown, .flagsChanged])
```

You can subscribe to input events using Combine's `sink` method.
```swift
InputMonitor.shared.publisher.sink { event in
    if (event.flags.contains(.maskShift) && event.keyCode == kVK_Space) {
        print("Shift + Space keystroke detected!")
    }
}
```
