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
	override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
		XCTFail("Networking disabled")
		return nil
	}
}


class MixpanelTests: XCTestCase {
	func testDisabling() {
		var client = Mixpanel(token: "asdf1234", URLSession: DisabledSession())
		client.enabled = false

		let expectation = expectationWithDescription("Completion")

		client.track("foo") { success in
			expectation.fulfill()
			XCTAssertFalse(success)
		}
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
