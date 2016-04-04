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
#elseif os(watchOS)
	import WatchKit
#elseif os(OSX)
	import AppKit
#endif

public typealias MixpanelPeopleProfile = [String: AnyObject]

/// Supported Mixpanel People analytics update operations.
/// More: https://mixpanel.com/help/reference/http#people-analytics-updates
public enum MixpanelPeopleOperation {
    case Set(MixpanelPeopleProfile)
    case SetOnce(MixpanelPeopleProfile)
    case Add(MixpanelPeopleProfile)
    case Append(MixpanelPeopleProfile)
    case Union(MixpanelPeopleProfile)
    case Unset([String])
    case Delete
    
    var JSONName: String {
        switch self {
        case .Set(_): return "$set"
        case .SetOnce(_): return "$set_once"
        case .Add(_): return "$add"
        case .Append(_): return "$append"
        case .Union(_): return "$union"
        case .Unset(_): return "$unset"
        case .Delete: return "$delete"
        }
    }
    
    var JSONValue: AnyObject {
        switch self {
        case .Set(let profile): return profile
        case .SetOnce(let profile): return profile
        case .Add(let profile): return profile
        case .Append(let profile): return profile
        case .Union(let profile): return profile
        case .Unset(let profile): return profile
        case .Delete: return ""
        }
    }
}

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
    private let peopleEndpoint = "https://api.mixpanel.com/engage/"
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

		#elseif os(watchOS)
			properties["mp_lib"] = "applewatch"

			let device = WKInterfaceDevice.currentDevice()
			properties["$os"] = device.systemName
			properties["$os_version"] = device.systemVersion

			properties["$screen_width"] = UInt(device.screenBounds.size.width)
			properties["$screen_height"] = UInt(device.screenBounds.size.height)
		#elseif os(OSX)
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
		guard enabled else {
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

        let payload: [String: AnyObject] = [
			"event": event,
			"properties": properties
		]
        
        guard let encodedPayload = encodePayload(payload) else {
            completion?(success: false)
            return
        }
        
        guard let url = NSURL(string: "\(endpoint)?data=\(encodedPayload)&ip=1") else {
            completion?(success: false)
            return
        }
        
        URLSession.dataTaskWithRequest(NSURLRequest(URL: url)) { _, response, error in
            guard error == nil else {
                completion?(success: false)
                return
            }
            
            guard let HTTPResponse = response as? NSHTTPURLResponse else {
                completion?(success: false)
                return
            }
            
            completion?(success: HTTPResponse.statusCode == 200)
        }.resume()
	}
    
    public func people(operation: MixpanelPeopleOperation, completion: Completion? = nil) {
        guard enabled else {
            completion?(success: false)
            return
        }
        
        // Mixpanel People API requires a `distinctId`.
        guard let distinctId = distinctId else {
            completion?(success: false)
            return
        }
        
        var payload = [String: AnyObject]()
        payload["$token"] = token
        payload["$distinct_id"] = distinctId
        payload[operation.JSONName] = operation.JSONValue
        
        guard let encodedPayload = encodePayload(payload) else {
            completion?(success: false)
            return
        }
        
        guard let url = NSURL(string: "\(peopleEndpoint)?data=\(encodedPayload)") else {
            completion?(success: false)
            return
        }
        
        URLSession.dataTaskWithRequest(NSURLRequest(URL: url)) { _, response, error in
            guard error == nil else {
                completion?(success: false)
                return
            }
            
            guard let HTTPResponse = response as? NSHTTPURLResponse else {
                completion?(success: false)
                return
            }
            
            completion?(success: HTTPResponse.statusCode == 200)
        }.resume()
    }
}

private extension Mixpanel {
    private func encodePayload(payload: [String: AnyObject]) -> String? {
        do {
            let json = try NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return json.base64EncodedStringWithOptions([]).stringByReplacingOccurrencesOfString("\n", withString: "")
        } catch {
            return nil
        }
    }
}
