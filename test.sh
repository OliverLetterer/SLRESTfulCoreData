#!/bin/sh

printf "\e[32m Installing xctool...\n"
git clone https://github.com/facebook/xctool.git /tmp/xctool >/dev/null

if [ $? != 0 ]; then 
	printf "\e[31m Cloning xctool failed"
	exit 1
fi

me=$(whoami)

mkdir -p ~/Library/Logs/DiagnosticReports
mkdir -p SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/$me.xcuserdatad/xcschemes

cp -r SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/oliver.xcuserdatad/xcschemes/* SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj/xcuserdata/$me.xcuserdatad/xcschemes

runTest() {
	/tmp/xctool/xctool.sh -project "SLRESTfulCoreData/SLRESTfulCoreData.xcodeproj" -scheme "SLRESTfulCoreData" -configuration "$1" test -test-sdk "$2"
	if [ $? != 0 ]; then 
		printf "\e[31m Test with SDK $2 failed"
		exit 1
	fi
}

runTest "Release" "iphonesimulator5.1"
runTest "Release" "iphonesimulator6.1"

