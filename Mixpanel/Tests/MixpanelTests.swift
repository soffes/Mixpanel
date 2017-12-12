//
//  MixpanelTests.swift
//  MixpanelTests
//
//  Created by Sam Soffes on 6/21/15.
//  Copyright © 2015–2017 Sam Soffes. All rights reserved.
//

import XCTest
import Mixpanel
import DVR

class DisabledSession: URLSession {
	override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		XCTFail("Networking disabled")
		return URLSessionDataTask()
	}
}


class MixpanelTests: XCTestCase {
	func testDisabling() {
		let expectation = self.expectation(description: "Completion")

		var client = Mixpanel(token: "asdf1234", session: DisabledSession())
		client.enabled = false
		client.track(event: "foo") { success in
			XCTAssertFalse(success)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 1)
	}

	func testTracking() {
		let expectation = self.expectation(description: "Completion")

		let client = Mixpanel(token: "07e60c15c2630d9047d62ac779203cae", session: Session(cassetteName: "tracking"))
		client.track(event: "test1", time: Date(timeIntervalSince1970: 1434954974)) { success in
			XCTAssertTrue(success)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 1)
	}

	func testTrackingWithParameters() {
		let expectation = self.expectation(description: "Completion")

		let client = Mixpanel(token: "07e60c15c2630d9047d62ac779203cae", session: Session(cassetteName: "tracking-parameters"))
		client.track(event: "test2", parameters: ["foo": "bar"], time: Date(timeIntervalSince1970: 1434954974)) { success in
			XCTAssertTrue(success)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 2)
	}
}
