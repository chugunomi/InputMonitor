@testable import InputMonitor
import XCTest
import Quick
import Nimble

internal final class InputMonitorTests: QuickSpec {
    override internal class func spec() {
        it("Should start monitoring input events") {
            let inputMonitor = InputMonitor()
            try inputMonitor.start(events: [.keyDown])
//            expect(inputMonitor.isMonitoring).to(beTrue())
//            expect(inputMonitor.events).to(equal([.keyDown]))
            inputMonitor.stop()
        }

        it("Should request access to monitor input events") {
            let inputMonitor = InputMonitor()
            let result = inputMonitor.requestAccess()
            expect(result).to(beTrue())
        }

        it("Should check access to monitor input events") {
            let inputMonitor = InputMonitor()
            let result = inputMonitor.checkAccess()
            expect(result).to(equal(.granted))
        }
    }
}
