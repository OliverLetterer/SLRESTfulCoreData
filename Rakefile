namespace :test do
  desc "Run the SLRESTfulCoreData Tests for iOS"
  task :ios do
    $ios_success = system("xctool -workspace SLRESTfulCoreData.xcworkspace -scheme 'iOS Tests' test -test-sdk iphonesimulator")
  end
  
  desc "Run the SLRESTfulCoreData Tests for Mac OS X"
  task :osx do
    $osx_success = system("xctool -workspace SLRESTfulCoreData.xcworkspace -scheme 'OS X Tests' test -test-sdk macosx -sdk macosx")
  end
end

desc "Run the SLRESTfulCoreData Tests for iOS"
task :test => [ 'test:ios' ] do
  puts "\033[0;31m!! iOS unit tests failed" unless $ios_success
  if $ios_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => 'test'
