Pod::Spec.new do |s|

  s.name         = "SimpleMixpanel"
  s.version      = "0.2"
  s.summary      = "Unofficial Mixpanel client written in Swift 2 for iOS/tvOS/watchOS/OSX"

  s.description  = <<-DESC
  This is a very simple client that just implements tracking events and identifying the current user. A network request is initiated whenver you call track. If it fails, nothing happens.
                   DESC

  s.homepage     = "https://github.com/soffes/Mixpanel"

  s.license      = "MIT"
  s.authors      = { "Sam Soffes" => "sam@soff.es", "Roman Shevtsov" => "roman.shevtsov@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/soffes/Mixpanel.git", :tag => "v#{s.version}" }

  s.source_files  = "Mixpanel", "Mixpanel/**/*.{h,m,swift}"
  s.exclude_files = "Mixpanel/Tests"

end
