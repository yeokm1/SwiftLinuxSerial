# SwiftLinuxSerial
(Readme is still work in progress)

A Swift 3 Linux-only library for reading and writing to serial ports. This library has been tested to work on Linux Mint 18 (based on Ubuntu 16.04) and on the [Raspberry Pi 3 on Ubuntu 16.04](https://wiki.ubuntu.com/ARM/RaspberryPi). Other platforms using Ubuntu like the Beaglebone might work as well.

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
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
export PATH=/opt/swift/swift-3.0/usr/bin:$PATH
```

### Install Swift 3 on Ubuntu on Raspberry Pi 3
Instructions from thes section is referenced from this [link](http://dev.iachieved.it/iachievedit/swift-3-0-on-raspberry-pi-2-and-3/)

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
export PATH=$HOME/swift-3.0/usr/bin:$PATH
```







