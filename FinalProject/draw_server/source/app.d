// @file multithreaded_chat/server.d
//
// Start server first: rdmd server.d
import std.conv;
import std.socket;
import std.stdio;
import std.string;
import core.thread.osthread;

import clientprofile : ClientProfile;
// struct ClientProfile { 
// 	Socket socket;
// 	int clientID;
// 	bool alive;
// }
import clientmessage : ClientMessage;
// struct ClientMessage {
// 	int clientID;
// 	int length;
// 	char[80] data;
// }
import tcpserver;

// Entry point to Server
void main(){
	 write("Please input an ip address for the server to run on: ");
	 string host = readln().chomp;
	 write("Please input a port number for the server to run on: ");
	 ushort port = to!ushort(readln().chomp);

	TCPServer server = new TCPServer(host, port);
	server.run();
}
