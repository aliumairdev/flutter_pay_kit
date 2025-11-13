#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_universal_payments.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_universal_payments'
  s.version          = '0.1.0'
  s.summary          = 'A unified API for integrating multiple payment processors in Flutter apps'
  s.description      = <<-DESC
A unified API for integrating multiple payment processors (Stripe, Paddle, Braintree, Lemon Squeezy, Totalpay Global) in Flutter apps with native Apple Pay support.
                       DESC
  s.homepage         = 'https://github.com/aliumairdev/flutter_pay_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Universal Payments' => 'support@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Add PassKit framework for Apple Pay
  s.frameworks = 'PassKit'
end
