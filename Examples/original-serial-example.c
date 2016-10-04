/* Referenced from
http://xanthium.in/Serial-Port-Programming-on-Linux
https://chrisheydrick.com/2012/06/17/how-to-read-serial-data-from-an-arduino-in-linux-with-c-part-3/
*/

#include <stdio.h>
#include <fcntl.h>  /* File Control Definitions          */
#include <termios.h>/* POSIX Terminal Control Definitions*/
#include <unistd.h> /* UNIX Standard Definitions         */
#include <errno.h>  /* ERROR Number Definitions          */

#define SIZE_BYTES_READ_BLOCKING 1
#define SIZE_READ_BUFFER 32

int openSerialPort(char portName[]){
	//O_RDONLY opens the serial port as read-only
	//O_NOCTTY means that no terminal will control the process opening the serial port.
	int fd = open(portName, O_RDONLY | O_NOCTTY);
	return fd;
}

void setSerialPortSettings(int fd, int charsToReadBeforeReturn){

	//Set up the control structure
	struct termios srSettings;

 	//Get options structure for the port
	tcgetattr(fd, &srSettings);

	// Set 9600 baud for input
	cfsetispeed(&srSettings, B9600);
	//We do not set baud rate for output as this is readonly
	//cfsetospeed(srSettings, B9600);
 
	//No Parity
	srSettings.c_cflag &= ~PARENB;
	//1 Stop bit
	srSettings.c_cflag &= ~CSTOPB;
	//No mask
	srSettings.c_cflag &= ~CSIZE;
	//8 Data bits
	srSettings.c_cflag |= CS8;
 
	//Turn off hardware flow control
	srSettings.c_cflag &= ~CRTSCTS;
	//Turn on the receiver of the serial port (CREAD)
	srSettings.c_cflag |= CREAD | CLOCAL;
	//Turn off software based flow control (XON/XOFF)
	srSettings.c_iflag &= ~(IXON | IXOFF | IXANY);
 
	//Turn off canonical mode
 	srSettings.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);

 	//Disable output processing. Not needed now
 	//srSettings.c_oflag &= ~OPOST;
 
	//Wait for certain number of characters to come in before returning
 	srSettings.c_cc[VMIN] = charsToReadBeforeReturn;
 	
 	//No minimum time to wait before read returns
 	srSettings.c_cc[VTIME] = 0;
 
	//Commit settings
 	tcsetattr(fd, TCSANOW, &srSettings);
}

int readBytesFromPort(int fd, char buf[], int size){
	int bytesRead = read(fd, buf, size);
	return bytesRead;
}

void closeSerialPort(int fd){
	close(fd);
}

int main(int argc, char * argv[]){

	if(argc < 2){
		printf("Insufficent arguments, need Serial Port name\n");
		return 1;
	}

	char * serialPortName = argv[1];

	printf("Opening port %s\n", serialPortName);

	int fd = openSerialPort(serialPortName);

	if(fd == -1){
		printf("Error in opening %s\n", serialPortName);
	} else{
		printf("%s opened Successfully\n", serialPortName);
	}

	setSerialPortSettings(fd, SIZE_BYTES_READ_BLOCKING);

	char lineBuffer[SIZE_READ_BUFFER];

	int currentPosition = 0;
	char tempBuffer[1];

	while(1){
		int bytesRead = readBytesFromPort(fd, tempBuffer, 1);

		if(bytesRead > 0){
			
			if(tempBuffer[0] == '\n' || currentPosition >= (SIZE_READ_BUFFER - 2)){ 
				/* We print when we:
					1. receive a newline character. 
					2. reach buffer capacity of one less to reserve the last character for '\0'
				*/

				//If we are at the end, we write the last character to the buffer
				if(currentPosition >= (SIZE_READ_BUFFER - 2)){
					lineBuffer[currentPosition] = tempBuffer[0];
					currentPosition++;
				}

				lineBuffer[currentPosition] = '\0';
				puts(lineBuffer);
				currentPosition = 0;

			} else {
				lineBuffer[currentPosition] = tempBuffer[0];
				currentPosition++;
			}
		}

	}

	closeSerialPort(fd);

	return 0;
}



