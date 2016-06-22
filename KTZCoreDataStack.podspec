#
# Be sure to run `pod lib lint KTZCoreDataStack.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KTZCoreDataStack'
  s.version          = '0.1.0'
  s.summary          = 'A starting point for a Core Data app w/ non-blocking disk saves and background context for performing work.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This is a template for a Core Data stack which can be used in apps needing basic support for background writes, main thread access, and background context for work.
                       DESC

  s.homepage         = 'https://github.com/popwarsweet/KTZCoreDataStack'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kyle Zaragoza' => 'popwarsweet@gmail.com' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/KTZCoreDataStack.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'KTZCoreDataStack/Classes/**/*'
  
  # s.resource_bundles = {
  #   'KTZCoreDataStack' => ['KTZCoreDataStack/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
