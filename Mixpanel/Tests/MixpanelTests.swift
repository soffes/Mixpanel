//
//  MixpanelTests.swift
//  MixpanelTests
//
//  Created by Sam Soffes on 6/21/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import XCTest
import Mixpanel
import DVR

class DisabledSession: NSURLSession {
	override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
		XCTFail("Networking disabled")
		return NSURLSessionDataTask()
	}
}


class MixpanelTests: XCTestCase {
	func testDisabling() {
		let expectation = expectationWithDescription("Completion")

		var client = Mixpanel(token: "asdf1234", URLSession: DisabledSession())
		client.enabled = false
		client.track("foo") { success in
			XCTAssertFalse(success)
			expectation.fulfill()
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testTracking() {
		let expectation = expectationWithDescription("Completion")

		let client = Mixpanel(token: "07e60c15c2630d9047d62ac779203cae", URLSession: Session(cassetteName: "tracking"))
		client.track("test1", time: NSDate(timeIntervalSince1970: 1434954974)) { success in
			XCTAssertTrue(success)
			expectation.fulfill()
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testTrackingWithParameters() {
		let expectation = expectationWithDescription("Completion")

		let client = Mixpanel(token: "07e60c15c2630d9047d62ac779203cae", URLSession: Session(cassetteName: "tracking-parameters"))
		client.track("test2", parameters: ["foo": "bar"], time: NSDate(timeIntervalSince1970: 1434954974)) { success in
			XCTAssertTrue(success)
			expectation.fulfill()
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
