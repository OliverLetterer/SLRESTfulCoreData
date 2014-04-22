desc "Runs tests."
task :test do
  exit system("xcodebuild -workspace SLRESTfulCoreData.xcworkspace -scheme 'iOS Tests' test -sdk iphonesimulator7.1 -configuration Release | xcpretty -c; exit ${PIPESTATUS[0]}")
end

task :default => 'test'
