#!/bin/sh

git clone https://github.com/OliverLetterer/xctool.git /tmp/xctool

me=$(whoami)
cp -r SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/oliver.xcuserdatad/* SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/$me.xcuserdatad
cp -r SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/project.xcworkspace/xcuserdata/oliver.xcuserdatad/* SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/project.xcworkspace/xcuserdata/$me.xcuserdatad

ls -la SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/*.xcuserdatad/xcschemes
ls -la SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/project.xcworkspace/xcuserdata/*.xcuserdatad/xcschemes

runTest() {
	/tmp/xctool/xctool.sh -project "SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj" -scheme "SLRESTfulCoreData" -configuration "$1" test -test-sdk "$2"
	if [ $? != 0 ]; then 
		exit 1
	fi
}

runTest "Debug" "iphonesimulator5.1"
runTest "Release" "iphonesimulator5.1"
runTest "Debug" "iphonesimulator6.1"
runTest "Release" "iphonesimulator6.1"

