# Mixpanel

[![Version](https://img.shields.io/github/release/soffes/Mixpanel.svg)](https://github.com/soffes/Mixpanel/releases)
![Swift Version](https://img.shields.io/badge/swift-4.2-orange.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Unofficial [Mixpanel](https://mixpanel.com) client written in Swift 4.2 for iOS and Mac.

This is a very simple client that just implements tracking events and identifying the current user. A network request is initiated whenver you call `track`. If it fails, nothing happens. Eventually, it would be cool if it stored these and retried at some point.


## Installation

[Carthage](https://github.com/carthage/carthage) is the recommended way to install Mixpanel. Add the following to your Cartfile:

``` ruby
github "soffes/Mixpanel"
```


## Usage

``` swift
import Mixpanel

// Setup a client
let mixpanel = Mixpanel(token: "your app token")

// Identify the current user. This doesn't make a network request. It simply
// will add their identifer to the next event tracked.
mixpanel.identify("7")

// Track an event
mixpanel.track("Launch")

// Track an event with parameters
mixpanel.track("Share", parameters: [
  "service": "Twitter",
])

// You can also customize the time the event happened and add a completion
// handler if you want.
mixpanel.track("Import photo", parameters: [
  "source": "Photo library"
], time: someTime, completion: (success) in {
  println("Tracked event successfully: \(success)")
})
```

Enjoy.
