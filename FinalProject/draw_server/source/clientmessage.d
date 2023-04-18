module clientmessage;

/**
Struct for passing client message to the server in packets of length 80
*/
struct ClientMessage {
	int clientID;
	int length;
	char[80] data;
}