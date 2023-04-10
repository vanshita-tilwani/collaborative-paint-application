module clientprofile;

import std.socket;
struct ClientProfile { 
	Socket socket;
	int clientID;
	bool alive;
}