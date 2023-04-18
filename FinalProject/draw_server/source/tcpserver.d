module tcpserver;

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

class TCPServer{
	Socket serverSocket;

	ClientProfile[] clientProfiles;

	ClientMessage[] messageHistory;
	ClientMessage[] drawHistory;

	long draw_head;

	long[int] mCurrentMessageToSend;
	long[int] mCurrentDrawToSend;

	// Unique ID dispenser variable
	int clientIDCounter = 0;	

	this(string host = "localhost", ushort port=50002, ushort maxConnectionsBacklog=4){
		writeln("Starting server...");
		writeln("Server must be started before clients may join");

		serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		serverSocket.bind(new InternetAddress(host,port));
		serverSocket.listen(maxConnectionsBacklog);
	}

	~this(){
		serverSocket.close();
	}

	/// Call this after the server has been created
	/// to start running the server
	void run(){		  

		while(true){
			writeln("Waiting to accept more connections");
			
			auto newClientSocket = serverSocket.accept();

			writeln("(me)",newClientSocket.localAddress(),
			"<---->",newClientSocket.remoteAddress(),"(client)");

			ClientProfile newClient = ClientProfile(newClientSocket, clientIDCounter, true);
			
			clientProfiles ~= newClient;

			mCurrentMessageToSend[newClient.clientID] = 0;
			mCurrentDrawToSend[newClient.clientID] = 0;

			writeln("Active clients = ", clientProfiles.length);

			broadcastToAllClients();

			// Sending the draw head to the new client to synchronize them
			auto helloMessage = "client -1: hello " ~ to!string(draw_head) ~ " ";
			char[90] toSend;
			char[] temp = helloMessage.dup;
			for (int i = 0; i < 90; i++) {
				if (i < helloMessage.length)
					toSend[i] = temp[i];
				else
					toSend[i] = '.';
			}
			newClient.socket.send(toSend);

			new Thread({
					clientLoop(newClient);
				}).start();

			clientIDCounter++;
		}
	}

	// Function to spawn from a new thread for the client.
	// The purpose is to listen for data sent from the client
	// and then rebroadcast that information to all other clients.
	// NOTE: passing 'clientSocket' by value so it should be a copy of
	//       the connection.
	void clientLoop(ClientProfile client){
		writeln("\t Starting clientLoop:(me)",client.socket.localAddress(),
		"<---->",client.socket.remoteAddress(),"(client)");

		bool runThreadLoop = true;

		while(runThreadLoop){
			// Message buffer will be 80 bytes
			char[80] buffer;
			// Server is now waiting to handle data from specific client
			// We'll block the server awaiting to receive a message.
			auto got = client.socket.receive(buffer);
			debug {
				writeln("receiving from client ", client.clientID, ", msg: ", buffer[0 .. got]);
			}
			if (got == 0) {
				// Then remove the socket
				runThreadLoop = false;
				client.alive = false;
				writeln("client ", client.clientID, " disconnected");
				break;
			}

			if (buffer[0 .. 3] == "drw"){
				debug {
					writeln("Server recieves draw command");
				}
				draw_head++;
				drawHistory = drawHistory[0 .. draw_head - 1];
				drawHistory ~= ClientMessage(client.clientID, to!int(got), buffer); 	
				foreach(tmpp_client; clientProfiles) {
					if (mCurrentDrawToSend[tmpp_client.clientID] >= drawHistory.length)
						mCurrentDrawToSend[tmpp_client.clientID] = draw_head - 1;
				}
			}
			else if (buffer[0 .. 4] == "undo"){
				debug {
					writeln("Server recieves undo command");
				}
				draw_head--;
				foreach(temp_client;clientProfiles) {
					if (temp_client == client) 
						continue;
					temp_client.socket.send(
						formatMessage(ClientMessage(client.clientID, to!int(got), buffer)));
				}
			}
			else if (buffer[0 .. 4] == "redo") {
				debug {
					writeln("Server recieves redo command");
				}
				draw_head++;
				foreach(temp_client;clientProfiles) {
					if (temp_client == client) 
						continue;
					temp_client.socket.send(
						formatMessage(ClientMessage(client.clientID, to!int(got), buffer)));
				}
			}
			else 
				messageHistory ~= ClientMessage(client.clientID, to!int(got), buffer);

			debug {
				writeln("Draw head at ", draw_head, "/", drawHistory.length);
			}
			broadcastToAllClients();
		}

	}

	string formatMessage(ClientMessage msg) {
		string prefix = "client " ~ to!string(msg.clientID) ~ ": ";
		char[] toSend = prefix.dup ~ msg.data[0 .. msg.length];
		return toSend.idup();
	}

	void broadcastToAllClients(){
		foreach(client; clientProfiles){
			if (client.alive == false)
				continue;
			
			while(messageHistory.length > 0 && mCurrentMessageToSend[client.clientID] <= messageHistory.length-1){
				ClientMessage msg = messageHistory[mCurrentMessageToSend[client.clientID]];
				
				writeln("sending message from client ", msg.clientID, " to client ", client.clientID, " / msg: ", formatMessage(msg));
				client.socket.send(formatMessage(msg).dup);
				mCurrentMessageToSend[client.clientID]++;
			}

			while(drawHistory.length > 0 && mCurrentDrawToSend[client.clientID] <= drawHistory.length-1){
				ClientMessage draw_msg = drawHistory[mCurrentDrawToSend[client.clientID]];

				if (draw_msg.clientID == client.clientID){
					mCurrentDrawToSend[client.clientID]++;
					continue;
				}

				writeln("sending draw from client ", draw_msg.clientID, " to client ", client.clientID, " / msg: ", formatMessage(draw_msg));
				client.socket.send(formatMessage(draw_msg).dup);
				mCurrentDrawToSend[client.clientID]++;
			}
		}
	}


}