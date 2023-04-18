module clientprofile;

import std.socket;

/**
Struct for keeping track of client information.
*/
struct ClientProfile { 
	Socket socket;
	int clientID;
	bool alive;
}