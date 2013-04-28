Pod::Spec.new do |spec|
  spec.name         = 'SLRESTfulCoreData'
  spec.version      = '1.0.0'
  spec.platform     = :ios, '5.0'
  spec.license      = 'MIT'
  spec.source       = { :git => 'https://github.com/OliverLetterer/SLRESTfulCoreData.git', :tag => spec.version.to_s }
  spec.source_files = 'SLRESTfulCoreData/SLRESTfulCoreData/*.{h,m}', 'SLRESTfulCoreData/SLRESTfulCoreData/**/*.{h,m}', 'SLRESTfulCoreData/SLRESTfulCoreData/Framework Additions/**/**/*.{h,m}'
  spec.frameworks   = 'Foundation', 'UIKit', 'CoreData'
  spec.requires_arc = true
  spec.homepage     = 'https://github.com/OliverLetterer/SLRESTfulCoreData'
  spec.summary      = 'Map your REST API to your CoreData model in minutes.'
  spec.author       = { 'Oliver Letterer' => 'oliver.letterer@gmail.com' }
  spec.prefix_header_contents = <<-EOS
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
    #import <objc/runtime.h>
    #import <UIKit/UIKit.h>
#endif
EOS
end