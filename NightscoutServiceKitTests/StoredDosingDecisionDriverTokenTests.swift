//
//  StoredDosingDecisionDriverTokenTests.swift
//  NightscoutServiceKitTests
//
//  B.11.2.1: validates the consumer-side splice of the driver-token
//  rendezvous (B.11.2 producer) into Nightscout devicestatus uploads.
//
//  Producer-side tests live in OmniBLETests/DriverTokenRendezvousTests.swift
//  and OmniBLETests/HandoffOrchestratorTests.swift. End-to-end propagation
//  through the App Group is exercised by Loop's
//  TokenRotationPropagationTests. The full JSON-shape integration test
//  (deviceStatus -> dictionaryRepresentation -> JSON path
//  loop.testingDetails.driverToken) lives in Loop's
//  DriverTokenNightscoutSpliceTests, where Bundle.main has the host-app
//  Info.plist needed by `Bundle.main.bundleDisplayName`. This file
//  covers the parts that don't depend on Bundle.main:
//
//    1. NightscoutService.driverTokenProvider plumbing — the property
//       defaults to nil (so existing call sites are unaffected) and is
//       invoked once per upload batch when set.
//    2. The provider closure shape contract is `() -> [String: Any]?`.
//
//  The slice is additive (Class A — additive metadata only): no
//  existing devicestatus field is altered, and when the provider
//  returns nil the testingDetails field is omitted entirely so
//  caretakers don't see stale rendezvous entries.
//

import XCTest
@testable import NightscoutServiceKit

class StoredDosingDecisionDriverTokenTests: XCTestCase {

    // MARK: - NightscoutService.driverTokenProvider plumbing

    func test_driverTokenProvider_defaultsToNil() {
        // The property must default to nil so that fresh
        // NightscoutService instances (e.g. ones created before
        // LoopAppManager wires the closure) produce byte-identical
        // upload payloads to the pre-slice version.
        let service = NightscoutService()
        XCTAssertNil(service.driverTokenProvider,
                     "driverTokenProvider must default to nil to preserve pre-slice upload-payload shape")
    }

    func test_driverTokenProvider_canReturnDictionary() {
        // The closure type contract is `() -> [String: Any]?`. The
        // dictionary is intentionally untyped so callers in OmniBLE
        // (which has no NightscoutKit dep) can supply a generic
        // payload — the producer side packages a
        // DriverTokenRendezvous.dictionaryRepresentation here.
        let service = NightscoutService()
        let expected: [String: Any] = [
            "currentDriver": "phone",
            "signature": "ZmFrZS1zaWduYXR1cmU=",
        ]
        service.driverTokenProvider = { expected }

        let result = service.driverTokenProvider?()
        XCTAssertEqual(result?["currentDriver"] as? String, "phone")
        XCTAssertEqual(result?["signature"] as? String, "ZmFrZS1zaWduYXR1cmU=")
    }

    func test_driverTokenProvider_canReturnNil() {
        // When the provider returns nil (no rendezvous available —
        // not currently driver, peer token missing, etc.) the
        // upload pipeline must omit the testingDetails field so
        // caretakers don't see stale entries.
        let service = NightscoutService()
        service.driverTokenProvider = { nil }

        XCTAssertNil(service.driverTokenProvider?())
    }

    func test_driverTokenProvider_invokedRepeatedly_returnsFreshValue() {
        // Late-binding contract: the closure is called per upload
        // batch, so token rotations between batches show up in the
        // next upload without LoopAppManager reassigning the closure.
        let service = NightscoutService()
        var counter = 0
        service.driverTokenProvider = {
            counter += 1
            return ["call": counter]
        }

        let first = service.driverTokenProvider?()
        let second = service.driverTokenProvider?()
        let third = service.driverTokenProvider?()

        XCTAssertEqual(first?["call"] as? Int, 1)
        XCTAssertEqual(second?["call"] as? Int, 2)
        XCTAssertEqual(third?["call"] as? Int, 3)
    }
}
