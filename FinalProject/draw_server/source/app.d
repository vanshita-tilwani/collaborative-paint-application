// @file multithreaded_chat/server.d
//
// Start server first: rdmd server.d
import std.conv;
import std.socket;
import std.stdio;
import std.string;
import core.thread.osthread;

import clientprofile : ClientProfile;
import clientmessage : ClientMessage;
import tcpserver;

// Entry point to Server
/**
Entry point to the server side of the application.
*/
void main(){

	TCPServer server = new TCPServer();
	server.run();
}
