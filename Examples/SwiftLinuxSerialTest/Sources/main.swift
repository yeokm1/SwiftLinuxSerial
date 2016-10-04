import Glibc
import SwiftLinuxSerial

print("You should do a loopback i.e short the TX and RX pins of the target serial port before testing.")

let testString : String = "The big brown fox jumps over the lazy dog 01234567890."

let arguments = CommandLine.arguments

if(arguments.count < 2){
	print("Need Serial Port name example /dev/ttyUSB0 as first argument");
	exit(1)
}

let portName = arguments[1]

let serialHandler : SwiftLinuxSerial = SwiftLinuxSerial(serialPortName : portName)

let status = serialHandler.openPort(receive : true, transmit : true)

if(status.openSuccess){
	print("Serial port " + portName + " opened successfully")
} else {
	print("Serial port " + portName + " failed to open. You might need root permissions")
	exit(1)
}

serialHandler.setPortSettings(receiveBaud : SwiftLinuxSerialBaud.BAUD_B9600, 
	transmitBaud : SwiftLinuxSerialBaud.BAUD_B9600, 
	charsToReadBeforeReturn : 1)


let stringCharacterCount = testString.characters.count

print("Writing test string <"  + testString + "> of " + String(stringCharacterCount) + " characters to serial port")

var bytesWritten = serialHandler.writeStringToPortBlocking(stringToWrite : testString)

print("Sucessfully wrote " + String(bytesWritten) + " bytes")

print("Waiting to receive what was written...")

let stringReceived = serialHandler.readStringFromPortBlocking(bytesToReadFor : bytesWritten)

serialHandler.closePort()

if(testString == stringReceived){
	print("Received String is the same as transmitted string. Test successful!")
} else {
	print("Uh oh! Received String is not the same as what was transmitted. This was what we received")
	print("<" +  stringReceived + ">")
}









