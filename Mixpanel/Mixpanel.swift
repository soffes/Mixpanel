//
//  Mixpanel.swift
//  Mixpanel
//
//  Created by Sam Soffes on 4/21/15.
//  Copyright (c) 2015 Sam Soffes. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

/// Simple wrapper for Mixpanel. All requests are sent to the network in the background. If there is no Internet
/// connection, it will silently fail.
public struct Mixpanel {

	// MARK: - Types

	public typealias Completion = (success: Bool) -> ()


	// MARK: - Properties

	/// Easily disable tracking when desired.
	public var enabled: Bool = true

	private var token: String
	private var URLSession: NSURLSession
	private let endpoint = "https://api.mixpanel.com/track/"
	private var distinctId: String?

	private var deviceModel: String? {
		var size : Int = 0
		sysctlbyname("hw.machine", nil, &size, nil, 0)
		var machine = [CChar](count: Int(size), repeatedValue: 0)
		sysctlbyname("hw.machine", &machine, &size, nil, 0)
		return String.fromCString(machine)
	}

	private var defaultProperties: [String: AnyObject] {
		var properties: [String: AnyObject] = [
			"$manufacturer": "Apple"
		]

		if let info = NSBundle.mainBundle().infoDictionary {
			if let version = info["CFBundleVersion"] as? String {
				properties["$app_version"] = version
			}

			if let shortVersion = info["CFBundleShortVersionString"] as? String {
				properties["$app_release"] = shortVersion
			}
		}

		if let deviceModel = deviceModel {
			properties["$model"] = deviceModel
		}

		#if os(iOS)
			properties["mp_lib"] = "iphone"

			let device = UIDevice.currentDevice()
			properties["$os"] = device.systemName
			properties["$os_version"] = device.systemVersion

			let size = UIScreen.mainScreen().bounds.size
			properties["$screen_width"] = UInt(size.width)
			properties["$screen_height"] = UInt(size.height)
		#else
			properties["mp_lib"] = "mac"

			let processInfo = NSProcessInfo()
			properties["$os"] = "Mac OS X"
			properties["$os_version"] = processInfo.operatingSystemVersionString

			if let size = NSScreen.mainScreen()?.frame.size {
				properties["$screen_width"] = UInt(size.width)
				properties["$screen_height"] = UInt(size.height)
			}
		#endif

		return properties
	}


	// MARK: - Initializers

	public init(token: String, identifier: String? = nil, URLSession: NSURLSession = NSURLSession.sharedSession()) {
		self.token = token
		self.distinctId = identifier
		self.URLSession = URLSession
	}


	// MARK: - Tracking

	public mutating func identify(identifier: String?) {
		distinctId = identifier
	}


	public func track(event: String, parameters: [String: AnyObject]? = nil, time: NSDate = NSDate(), completion: Completion? = nil) {
		if !enabled {
			completion?(success: false)
			return
		}

		var properties = defaultProperties

		if let parameters = parameters {
			for (key, value) in parameters {
				properties[key] = value
			}
		}

		properties["token"] = token
		properties["time"] = time.timeIntervalSince1970

		if let distinctId = distinctId {
			properties["distinct_id"] = distinctId
		}

		let payload = [
			"event": event,
			"properties": properties
		]

		do {
			let json = try NSJSONSerialization.dataWithJSONObject(payload, options: [])
			let base64 = json.base64EncodedStringWithOptions([]).stringByReplacingOccurrencesOfString("\n", withString: "")
			if let url = NSURL(string: "\(endpoint)?data=\(base64)") {
				URLSession.dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: { data, _, error in
					if error != nil {
						completion?(success: false)
						return
					}

					guard let data = data, string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
						completion?(success: false)
						return
					}

					completion?(success: string == "1")
				}).resume()
			}
		} catch {
			// Do nothing
		}

		completion?(success: false)
	}
}
