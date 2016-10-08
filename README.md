# SwiftLinuxSerial
(Readme is still work in progress)

A Swift 3 Linux-only library for reading and writing to serial ports. This library has been tested to work on Linux Mint 18 (based on Ubuntu 16.04) and on the [Raspberry Pi 3 on Ubuntu 16.04](https://wiki.ubuntu.com/ARM/RaspberryPi). Other platforms using Ubuntu like the Beaglebone might work as well.

<p>
<img src="https://img.shields.io/badge/OS-Ubuntu-blue.svg?style=flat" alt="Swift 3.0">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift3-compatible-orange.svg?style=flat" alt="Swift 3 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>

## System Preparation

Before using this library, I assume you already have Ubuntu installed and fully updated on your system or single-board computer. To get Ubuntu installed on the Raspberry Pi, use this [link](https://wiki.ubuntu.com/ARM/RaspberryPi). 

### Network bug on Raspberry Pi 3 Ubuntu after system update

Reference from a [comment of this page link](http://dev.iachieved.it/iachievedit/building-swift-3-0-on-a-raspberry-pi-3/#comment-2072). The `eth0` ethernet adapter has been changed to something like `enxp...`.

```bash
#Get new name of network adapter
ifconfig -a
#enxp....
sudo nano /etc/network/interfaces.d/50-cloud-init.cfg
#Replace eth 0 with the name of your new adapter enxp...
sudo reboot
```

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
## For those who want to jump straight in

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

There are several functions you can use to read data. All functions here are blocking till the expected number of bytes has been received.

```swift
func readStringFromPortBlocking(bytesToReadFor : Int) -> String
```
This is the easiest to use if you are sending text data. Just provide how many bytes you expect to read. The result will then be returned as a typical Swift String. This function internally calls `readDataFromPortBlocking()`.

```swift
func readDataFromPortBlocking(bytesToReadFor : Int) -> (dataRead : Data, bytesRead : Int)
```
This function is if you intend to receive binary data. This function internally calls `readBytesFromPortBlocking()`

```swift
func readBytesFromPortBlocking(buf : UnsafeMutablePointer<UInt8>, size : Int) -> Int
```
If you intend to play with unsafe pointers directly, this is the function for you! Note that you are responsible for allocating the pointer before passing into this function then deallocate the pointer once you are done.





