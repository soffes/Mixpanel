//
//  Mixpanel.swift
//  Mixpanel
//
//  Created by Sam Soffes on 4/21/15.
//  Copyright (c) 2015 Sam Soffes. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
	import UIKit
#elseif os(watchOS)
	import WatchKit
#elseif os(OSX)
	import AppKit
#endif

/// Simple wrapper for Mixpanel. All requests are sent to the network in the background. If there is no Internet
/// connection, it will silently fail.
public struct Mixpanel {

	// MARK: - Types

	public typealias Completion = (Bool) -> ()


	// MARK: - Properties

	/// Easily disable tracking when desired.
	public var enabled: Bool = true

	private var token: String
	private var session: URLSession
	private let endpoint = "https://api.mixpanel.com/track/"
	private var distinctId: String?

	private var deviceModel: String? {
		var size: Int = 0
		sysctlbyname("hw.machine", nil, &size, nil, 0)
		var machine = [CChar](repeating: 0, count: Int(size))
		sysctlbyname("hw.machine", &machine, &size, nil, 0)
		return String(validatingUTF8: machine)
	}

	private var defaultProperties: [String: Any] {
		var properties: [String: Any] = [
			"$manufacturer": "Apple"
		]

		if let info = Bundle.main.infoDictionary {
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
        #elseif os(tvOS)
            properties["mp_lib"] = "tvOS"
        #endif
        
		#if os(iOS) || os(tvOS)
			let device = UIDevice.current
			properties["$os"] = device.systemName
			properties["$os_version"] = device.systemVersion

			let size = UIScreen.main.bounds.size
			properties["$screen_width"] = UInt(size.width)
			properties["$screen_height"] = UInt(size.height)

		#elseif os(watchOS)
			properties["mp_lib"] = "applewatch"

			let device = WKInterfaceDevice.current()
			properties["$os"] = device.systemName
			properties["$os_version"] = device.systemVersion

			properties["$screen_width"] = UInt(device.screenBounds.size.width)
			properties["$screen_height"] = UInt(device.screenBounds.size.height)
		#elseif os(OSX)
			properties["mp_lib"] = "mac"

			let processInfo = ProcessInfo()
			properties["$os"] = "macOS"
			properties["$os_version"] = processInfo.operatingSystemVersionString

			if let size = NSScreen.main?.frame.size {
				properties["$screen_width"] = UInt(size.width)
				properties["$screen_height"] = UInt(size.height)
			}
		#endif

		return properties
	}


	// MARK: - Initializers

	public init(token: String, identifier: String? = nil, session: URLSession = URLSession.shared) {
		self.token = token
		self.distinctId = identifier
		self.session = session
	}


	// MARK: - Tracking

	public mutating func identify(identifier: String?) {
		distinctId = identifier
	}


	public func track(event: String, parameters: [String: Any]? = nil, time: Date = Date(), completion: Completion? = nil) {
		if !enabled {
			completion?(false)
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

		let payload: [String: Any] = [
			"event": event,
			"properties": properties
		]

		guard let json = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
			completion?(false)
			return
		}

		let base64 = json.base64EncodedString().replacingOccurrences(of: "\n", with: "")
		if let url = URL(string: "\(endpoint)?data=\(base64)&ip=1") {
			session.dataTask(with: URLRequest(url: url)) { _, res, error in
				if error != nil {
					completion?(false)
					return
				}

				guard let response = res as? HTTPURLResponse else {
					completion?(false)
					return
				}

				completion?(response.statusCode == 200)
			}.resume()
			return
		}

		completion?(false)
	}
}
