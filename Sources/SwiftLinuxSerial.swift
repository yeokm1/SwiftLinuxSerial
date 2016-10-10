import Glibc
import Foundation

public let SERIAL_OPEN_FAIL : Int32 = -1

public enum SwiftLinuxSerialBaud : Int{
    case BAUD_0
    case BAUD_50
    case BAUD_B75
    case BAUD_B110
    case BAUD_B134
    case BAUD_B150
    case BAUD_B200
    case BAUD_B300
    case BAUD_B600
    case BAUD_B1200
    case BAUD_B1800
    case BAUD_B2400
    case BAUD_B4800
    case BAUD_B9600
    case BAUD_B19200
    case BAUD_B38400
    case BAUD_B57600
    case BAUD_B115200
    case BAUD_B230400
    case BAUD_B460800
    case BAUD_B500000
    case BAUD_B576000
    case BAUD_B921600
    case BAUD_B1000000
    case BAUD_B1152000
    case BAUD_B1500000
    case BAUD_B2000000
    case BAUD_B2500000
    case BAUD_B3500000
    case BAUD_B4000000
}

public enum SwiftLinuxSerialDataBit : Int{
	case DATA_BIT_5
	case DATA_BIT_6
	case DATA_BIT_7
	case DATA_BIT_8
}

public enum SwiftLinuxSerialStopBit : Int{
    case STOP_BIT_1
    case STOP_BIT_2
}

public class SwiftLinuxSerial {

	var fileDescriptor : Int32 = SERIAL_OPEN_FAIL
	var portName : String

	public init(serialPortName : String){
		portName = serialPortName
	}

	public func openPort(receive : Bool = true, transmit : Bool = true) -> (openSuccess : Bool, descriptor : Int32){

		if(portName.isEmpty || (receive == false && transmit == false)){
			return (false, SERIAL_OPEN_FAIL)
		}

		//O_NOCTTY means that no terminal will control the process opening the serial port.
		if(receive && transmit){

			//C: open(portName, O_RDONLY | O_NOCTTY);
			fileDescriptor = open(portName, O_RDWR | O_NOCTTY)
		} else if(receive){
			fileDescriptor = open(portName, O_RDONLY | O_NOCTTY)
		} else {
			fileDescriptor = open(portName, O_WRONLY | O_NOCTTY)
		}

		if(fileDescriptor == SERIAL_OPEN_FAIL){
			return (false, SERIAL_OPEN_FAIL)
		} else {
			return (true, fileDescriptor)
		}
	}

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

		if(fileDescriptor == SERIAL_OPEN_FAIL){
			return
		}

		//Set up the control structure
		//C: struct termios srSettings;
		var srSettings : termios = termios()

		//Get options structure for the port
		tcgetattr(fileDescriptor, &srSettings)

		let receiveBaudActual = convertSwiftLinuxSerialBaudRatesEnumToRequired(param : receiveBaud)
		let transmitBaudActual = convertSwiftLinuxSerialBaudRatesEnumToRequired(param : transmitBaud)

		//C: cfsetispeed(&srSettings, B9600);
		cfsetispeed(&srSettings, UInt32(receiveBaudActual))
		cfsetospeed(&srSettings, UInt32(transmitBaudActual))

		if(parity){
			//C: srSettings.c_cflag |= PARENB;
			srSettings.c_cflag |= ~UInt32(PARENB)
		} else {
			//C: srSettings.c_cflag &= ~PARENB;
			srSettings.c_cflag &= ~UInt32(PARENB)
		}

		if(stopBit == SwiftLinuxSerialStopBit.STOP_BIT_2){
			srSettings.c_cflag |= UInt32(CSTOPB)
		} else {
			srSettings.c_cflag &= ~UInt32(CSTOPB)
		}

		//Disable mask
		srSettings.c_cflag &= ~UInt32(CSIZE)

		switch(dataBits){
			case SwiftLinuxSerialDataBit.DATA_BIT_5 : srSettings.c_cflag |= UInt32(CS5)
			case SwiftLinuxSerialDataBit.DATA_BIT_6 : srSettings.c_cflag |= UInt32(CS6)
			case SwiftLinuxSerialDataBit.DATA_BIT_7 : srSettings.c_cflag |= UInt32(CS7)
			case SwiftLinuxSerialDataBit.DATA_BIT_8 : srSettings.c_cflag |= UInt32(CS8)
		}

		if(hardwareFlowControl){
			srSettings.c_cflag |= UInt32(CRTSCTS)
		} else {
			srSettings.c_cflag &= ~UInt32(CRTSCTS)
		}

		if(softwareFlowControl){
			srSettings.c_iflag |= UInt32(IXON) | UInt32(IXOFF) | UInt32(IXANY)
		} else {
			srSettings.c_iflag &= ~(UInt32(IXON) | UInt32(IXOFF) | UInt32(IXANY))
		}

		//Turn on the receiver of the serial port (CREAD)
		srSettings.c_cflag |= UInt32(CREAD) | UInt32(CLOCAL)

		//Turn off canonical mode
		srSettings.c_lflag &= ~(UInt32(ICANON) | UInt32(ECHO) | UInt32(ECHOE) | UInt32(ISIG))

		if(outputProcessing){
			srSettings.c_oflag |= UInt32(OPOST)
		} else {
			srSettings.c_oflag &= ~(UInt32(OPOST))
		}


		//Wait for certain number of characters to come in before returning
		//VMIN should be position 6 in the tuple. C fixed arrays are imported as tuples in Swift
		//Use print(VMIN) to confirm the value for your platform
		//C: srSettings.c_cc[VMIN] = charsToReadBeforeReturn;
		srSettings.c_cc.6 = charsToReadBeforeReturn

		//VTIME is position 5 in the tuple. C fixed arrays are imported as tuples in Swift
		//Use print(VTIME) to check the value for your platform
		//C: srSettings.c_cc[VTIME] = minimumTimeToWaitBeforeReturn;
		srSettings.c_cc.5 = minimumTimeToWaitBeforeReturn

		//Commit settings
		tcsetattr(fileDescriptor, TCSANOW, &srSettings)
	}

	public func convertSwiftLinuxSerialBaudRatesEnumToRequired(param : SwiftLinuxSerialBaud) -> Int32{
	 	switch(param){
	 		case SwiftLinuxSerialBaud.BAUD_0 : return B0
			case SwiftLinuxSerialBaud.BAUD_50 : return B50
			case SwiftLinuxSerialBaud.BAUD_B75 : return B75
			case SwiftLinuxSerialBaud.BAUD_B110 : return B110
			case SwiftLinuxSerialBaud.BAUD_B134 : return B134
			case SwiftLinuxSerialBaud.BAUD_B150 : return B150
			case SwiftLinuxSerialBaud.BAUD_B200 : return B200
			case SwiftLinuxSerialBaud.BAUD_B300 : return B300
			case SwiftLinuxSerialBaud.BAUD_B600 : return B600
			case SwiftLinuxSerialBaud.BAUD_B1200 : return B1200
			case SwiftLinuxSerialBaud.BAUD_B1800 : return B1800
			case SwiftLinuxSerialBaud.BAUD_B2400 : return B2400
			case SwiftLinuxSerialBaud.BAUD_B4800 : return B4800
			case SwiftLinuxSerialBaud.BAUD_B9600 : return B9600
			case SwiftLinuxSerialBaud.BAUD_B19200 : return B19200
			case SwiftLinuxSerialBaud.BAUD_B38400 : return B38400
			case SwiftLinuxSerialBaud.BAUD_B57600 : return B57600
			case SwiftLinuxSerialBaud.BAUD_B115200 : return B115200
			case SwiftLinuxSerialBaud.BAUD_B230400 : return B230400
			case SwiftLinuxSerialBaud.BAUD_B460800 : return B460800
			case SwiftLinuxSerialBaud.BAUD_B500000 : return B500000
			case SwiftLinuxSerialBaud.BAUD_B576000 : return B576000
			case SwiftLinuxSerialBaud.BAUD_B921600 : return B921600
			case SwiftLinuxSerialBaud.BAUD_B1000000 : return B1000000
			case SwiftLinuxSerialBaud.BAUD_B1152000 : return B1152000
			case SwiftLinuxSerialBaud.BAUD_B1500000 : return B1500000
			case SwiftLinuxSerialBaud.BAUD_B2000000 : return B2000000
			case SwiftLinuxSerialBaud.BAUD_B2500000 : return B2500000
			case SwiftLinuxSerialBaud.BAUD_B3500000 : return B3500000
			case SwiftLinuxSerialBaud.BAUD_B4000000 : return B4000000
	 	}
	}

	//C: readBytesFromPortBlocking(char * buf, int size)
	public func readBytesFromPortBlocking(buf : UnsafeMutablePointer<UInt8>, size : Int) -> Int {
		if(fileDescriptor == SERIAL_OPEN_FAIL){
			return 0
		}

		let bytesRead : Int = read(fileDescriptor, buf, size)
		return bytesRead
	}

	public func writeBytesToPortBlocking(buf : UnsafeMutablePointer<UInt8>, size : Int) -> Int {
		if(fileDescriptor == SERIAL_OPEN_FAIL){
			return 0
		}

		let bytesWritten : Int = write(fileDescriptor, buf, size)
		return bytesWritten
	}

	public func readDataFromPortBlocking(bytesToReadFor : Int) -> (dataRead : Data, bytesRead : Int) {
		
		//C: char * tempBuffer = (char*) malloc(sizeof(char) * bytesToReadFor); 
		let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity : bytesToReadFor)

		//C: free(tempBuffer)
		defer { tempBuffer.deallocate(capacity : bytesToReadFor) }

		let bytesRead : Int = readBytesFromPortBlocking(buf : tempBuffer, size : bytesToReadFor)
		let data = Data(bytes: tempBuffer, count: bytesRead)

		return (dataRead : data, bytesRead : bytesRead)
	}

	public func writeDataToPortBlocking(dataToWrite : Data) -> Int {

		let sizeToWrite = dataToWrite.count

		let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity : sizeToWrite)
		defer { tempBuffer.deallocate(capacity : sizeToWrite) }

		dataToWrite.copyBytes(to : tempBuffer, count : sizeToWrite)

		let bytesWritten : Int = writeBytesToPortBlocking(buf : tempBuffer, size : sizeToWrite)
		return bytesWritten
	}


	public func writeStringToPortBlocking(stringToWrite : String) -> Int {
		let data : Data? = stringToWrite.data(using : String.Encoding.utf8)

		if(data == nil){
			return 0
		}

		return writeDataToPortBlocking(dataToWrite : data!)
	}


	public func readStringFromPortBlocking(bytesToReadFor : Int) -> String {

		var bytesToReadRemaining : Int = bytesToReadFor
		var bytesReadSoFar : Int = 0
		var stringReadSoFar : String = ""

		while(bytesReadSoFar < bytesToReadFor){


			let result = readDataFromPortBlocking(bytesToReadFor : bytesToReadRemaining)

			let dataRead = result.dataRead
			let bytesRead = result.bytesRead

			let stringRead : String? = String(data: dataRead, encoding: String.Encoding.utf8)

			if(stringRead == nil){
				return stringReadSoFar
			} else {
				stringReadSoFar = stringReadSoFar + stringRead!

				bytesReadSoFar += bytesRead
				bytesToReadRemaining -= bytesRead
			}


		}


		return stringReadSoFar

	}

	public func closePort(){
		if(fileDescriptor != SERIAL_OPEN_FAIL){
			close(fileDescriptor)
			fileDescriptor = SERIAL_OPEN_FAIL
		}
	}

	public func readTillCharacterBlocking(characterRep : UnicodeScalar) -> String{
		var lineBuffer : String = ""
		let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity : 1)
		defer { tempBuffer.deallocate(capacity : 1) }

		while(true){
			//Read byte by byte so we pass 1
			let bytesRead : Int = readBytesFromPortBlocking(buf : tempBuffer, size : 1)

			if(bytesRead > 0){
				let newestCharacter : UnicodeScalar = UnicodeScalar(tempBuffer[0])

				if(newestCharacter == characterRep){
					return lineBuffer
				} else {
					lineBuffer = lineBuffer + String(newestCharacter)
				}
			}
		}
	}

	public func readLineFromPortBlocking() -> String{
		//UnicodeScalar(10) is the newline \n character
		return readTillCharacterBlocking(characterRep : UnicodeScalar(10))
	}

}


