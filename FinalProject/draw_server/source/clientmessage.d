module clientmessage;

struct ClientMessage {
	int clientID;
	int length;
	char[80] data;
}