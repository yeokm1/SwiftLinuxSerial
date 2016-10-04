import PackageDescription

let package = Package(
    name: "SwiftLinuxSerialTest",
    dependencies: [
    	.Package(url: "https://github.com/yeokm1/SwiftLinuxSerial.git", majorVersion: 0)
	]
)
