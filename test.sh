#!/bin/sh

git clone https://github.com/facebook/xctool.git /tmp/xctool

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

rm -rf /tmp/xctool
