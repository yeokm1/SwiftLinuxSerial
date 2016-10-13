# SwiftLinuxSerial
A Swift 3 Linux-only library for reading and writing to serial ports. This library has been tested to work on Linux Mint 18 (based on Ubuntu 16.04) and on the [Raspberry Pi 3 on Ubuntu 16.04](https://wiki.ubuntu.com/ARM/RaspberryPi). Other platforms using Ubuntu like the Beaglebone might work as well.

<p>
<img src="https://img.shields.io/badge/OS-Ubuntu-blue.svg?style=flat" alt="Swift 3.0">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift3-compatible-orange.svg?style=flat" alt="Swift 3 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>

## System Preparation

Before using this library, I assume you already have Ubuntu installed and fully updated on your system or single-board computer. To get Ubuntu installed on the Raspberry Pi, use this [link](https://wiki.ubuntu.com/ARM/RaspberryPi). 

### Install Swift 3 on Ubuntu on x86-based machines

Reference instructions obtained from [here](http://dev.iachieved.it/iachievedit/swift-3-0-for-ubuntu-16-04-xenial-xerus/). We will use a Swift binary produced by iachievedit.
```bash
#Add the repository key for iachievedit
wget -qO- http://dev.iachieved.it/iachievedit.gpg.key | sudo apt-key add -

#Add the Xenial repository to sources.list
echo "deb http://iachievedit-repos.s3.amazonaws.com/ xenial main" | sudo tee --append /etc/apt/sources.list

sudo apt-get update
sudo apt-get install swift-3.0

#This command can be added to your bash profile so Swift will be in your PATH after a reboot
nano ~/.profile
export PATH=/opt/swift/swift-3.0/usr/bin:$PATH
```

### Install Swift 3 on Ubuntu on Raspberry Pi 3
Instructions from this section is referenced from this [link](http://dev.iachieved.it/iachievedit/swift-3-0-on-raspberry-pi-2-and-3/).

Since Swift 3 is still rapidly evolving, we should not use the Swift packages provided via the apt package manager if they exist and instead use prebuilt binaries instead. We will also not install Swift 3 to the system-level directories to avoid problems in case we have to update the version.

Go to this [page](http://swift-arm.ddns.net/job/Swift-3.0-Pi3-ARM-Incremental/lastSuccessfulBuild/artifact/) and find what it is the link to the latest Swift compiled `tar.gz` package.

```bash
#Install dependencies
sudo apt-get install libcurl4-openssl-dev libicu-dev clang-3.6
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.6 100
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.6 100

cd ~
#Replace the link below with the latest version
wget http://swift-arm.ddns.net/job/Swift-3.0-Pi3-ARM-Incremental/lastSuccessfulBuild/artifact/swift-3.0-2016-09-27-RPi23-ubuntu16.04.tar.gz
mkdir swift-3.0
cd swift-3.0 && tar -xzf ../swift-3.0-2016-09-27-RPi23-ubuntu16.04.tar.gz

#This command can be added to your bash profile so Swift will be in your PATH after a reboot
nano ~/.profile
export PATH=$HOME/swift-3.0/usr/bin:$PATH
```
## Jumping straight into sample code

To get started quickly, you can take a look at my example project [here](Examples/SwiftLinuxSerialTest). In order to run the example properly, you need to connect one of your (USB/UART) serial ports in a loopback manner. Basically, you short the TX and RX pins of the serial port.

```bash
git clone https://github.com/yeokm1/SwiftLinuxSerial.git
cd SwiftLinuxSerial/Examples/SwiftLinuxSerialTest/
swift build
#You need root to access the serial port. Replace /dev/ttyUSB0 with the name of your serial port under test
sudo ./.build/debug/SwiftLinuxSerialTest /dev/ttyUSB0

#If all goes well you should see a series of messages informing you that data transmitted has been received properly.
```

## Integrating with your project

Add SwiftLinuxSerial as a dependency to your project by editing the `Package.swift` file.

```swift
let package = Package(
    name: "NameOfMyProject",
    dependencies: [
        .Package(url: "https://github.com/yeokm1/SwiftLinuxSerial.git", majorVersion: 0),
        ...
    ]
    ...
)
```

Make sure to `import SwiftLinuxSerial` in the source files that use my API.

Then run `swift build` to download the dependencies and compile your project. Your executable will be found in the `./.build/debug/` directory.

## API usage

### Initialise the class

```swift
let serialHandler : SwiftLinuxSerial = SwiftLinuxSerial(serialPortName : portName)
```
Supply the portname that you wish to open like `/dev/ttyUSB0`.

### Opening the Serial Port

```swift
let status = serialHandler.openPort(receive : true, transmit : true)
```
Open the port and supply whether you want receive/transmit only or both. Obviously you should not put `false` for both. Will return a tuple containing `openSuccess` and the file descriptor. You don't have to store the file descriptor as that value is kept within the object.

### Set port settings

```swift
serialHandler.setPortSettings(receiveBaud : SwiftLinuxSerialBaud.BAUD_B9600, 
	transmitBaud : SwiftLinuxSerialBaud.BAUD_B9600, 
	charsToReadBeforeReturn : 1)
```

The port settings call can be as simple as the above. For the baud rate, just supply both transmit and receive even if you are only intend to use one function. For example, transmitBaud will be ignored if you specified `transmit : false` when opening the port. 

`charsToReadBeforeReturn` determines how many characters Linux must wait to receive before it will return from a [read()](https://linux.die.net/man/2/read) function. If in doubt, just put 1.

This function has been defined with default settings as shown in the function definition.

```swift
public func setPortSettings(receiveBaud : SwiftLinuxSerialBaud, 
	transmitBaud : SwiftLinuxSerialBaud, 
	charsToReadBeforeReturn : UInt8,
	parity : Bool = false,
	dataBits : SwiftLinuxSerialDataBit = SwiftLinuxSerialDataBit.DATA_BIT_8,
	stopBit : SwiftLinuxSerialStopBit = SwiftLinuxSerialStopBit.STOP_BIT_1,
	hardwareFlowControl : Bool = false,
	softwareFlowControl : Bool = false,
	outputProcessing : Bool = false,
	minimumTimeToWaitBeforeReturn : UInt8 = 0){ //0 means wait indefinitely
```
If the default settings do not suit you, just pass in extra parameters to override them.

### Reading data from port

There are several functions you can use to read data. All functions here are blocking till the expected number of bytes has been received or a condition has been met.

```swift
func readStringFromPortBlocking(bytesToReadFor : Int) -> String
```
This is the easiest to use if you are sending text data. Just provide how many bytes you expect to read. The result will then be returned as a typical Swift String. This function internally calls `readDataFromPortBlocking()`.

```swift
func readDataFromPortBlocking(bytesToReadFor : Int) -> (dataRead : Data, bytesRead : Int)
```
This function is if you intend to receive binary data. Will return both data and the number of bytes read. This function internally calls `readBytesFromPortBlocking()`

```swift
func readBytesFromPortBlocking(buf : UnsafeMutablePointer<UInt8>, size : Int) -> Int
```
If you intend to play with unsafe pointers directly, this is the function for you! Will return the number of bytes read. Note that you are responsible for allocating the pointer before passing into this function then deallocate the pointer once you are done.

```swift
func readLineFromPortBlocking() -> String
```
Read byte by byte till the newline character `\n` is encountered. A String containing the result so far will be returned without the newline character. This function internally calls `readTillCharacterBlocking()`.

```swift
func readTillCharacterBlocking(characterRep : UnicodeScalar) -> String
```
Keep reading until the specified ASCII or Unicode value has been encountered. Return the string read so far without that value.

### Writing data to the port

There are several functions you can use to write data. All functions here are blocking till all the data has been written.

```swift
func writeStringToPortBlocking(stringToWrite : String) -> Int
```
Most straightforward function, String in then transmit! Will return how many bytes actually written. Internally calls `writeDataToPortBlocking()`

```swift
func writeDataToPortBlocking(dataToWrite : Data) -> Int
```
Binary data in, then transmit! ill return how many bytes actually written. Internally calls `writeBytesToPortBlocking`.

```swift
func writeBytesToPortBlocking(buf : UnsafeMutablePointer<UInt8>, size : Int) -> Int
```
Function for those that want to mess with unsafe pointers. You have to specify how many bytes have to be written. Will return how many bytes actually written.

### Closing the port

Just do `serialHandler.closePort()` to close the port once you are done using it.

## C example code

I did my initial prototype of this library in the C language. For reference purposes, you can take a look at it [Examples/original-serial-example.c](Examples/original-serial-example.c) .

## External References

This library cannot be written without the amazing reference code I depended on.

1. [Xanthium's Serial Port Programming on Linux](http://xanthium.in/Serial-Port-Programming-on-Linux)
2. [Chrishey Drick's Reading data from Serial Port](https://chrisheydrick.com/2012/06/17/how-to-read-serial-data-from-an-arduino-in-linux-with-c-part-3/)

