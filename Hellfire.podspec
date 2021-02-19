#
# Be sure to run `pod lib lint Hellfire.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'Hellfire'
    s.version          = '0.2.1'
    s.summary          = 'Hellfire Network Lib'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'Hellfire is a lightweight and easy to use network lib that supports JSON serialization on complex custom types, optional/configurable response caching and reachability.'
    
    s.homepage         = 'https://github.com/ehellyer/Hellfire'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Ed Hellyer' => 'ejhellyer@gmail.com' }
    s.source           = { :git => 'https://github.com/ehellyer/Hellfire.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '10.0'
    s.tvos.deployment_target = '10.0'
    s.swift_version = '5.0'
    
    s.source_files = 'Hellfire/Classes/**/*'

end
