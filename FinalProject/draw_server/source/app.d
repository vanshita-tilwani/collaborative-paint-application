// @file multithreaded_chat/server.d
//
// Start server first: rdmd server.d
import std.conv;
import std.socket;
import std.stdio;
import core.thread.osthread;

struct ClientProfile { 
	Socket socket;
	int clientID;
	bool alive;
}

struct ClientMessage {
	int clientID;
	int length;
	char[256] data;
}

class TCPServer{
	/// The listening socket is responsible for handling new client connections.
	Socket serverSocket;
	/// Stores the clients that are currently connected to the server.
	ClientProfile[] clientProfiles;
	/// Stores all of the data on the server. Ideally, we'll
	/// use this to broadcast out to clients connected.
	ClientMessage[] messageHistory;
	/// Keeps track of the last message that was broadcast out to each client.
	long[int] mCurrentMessageToSend;
	// Unique ID dispenser variable
	int clientIDCounter = 0;	

	this(string host = "localhost", ushort port=50001, ushort maxConnectionsBacklog=4){
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

			mCurrentMessageToSend[newClient.clientID] = messageHistory.length;

			writeln("Active clients = ", clientProfiles.length);

			newClient.socket.send("Hello\0");

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
			char[256] buffer;
			// Server is now waiting to handle data from specific client
			// We'll block the server awaiting to receive a message.
			auto got = client.socket.receive(buffer);
			writeln("receiving from client ", client.clientID, ", msg: ", buffer[0 .. got]);
			if (got == 0) {
				// Then remove the socket
				runThreadLoop = false;
				client.alive = false;
				writeln("client ", client.clientID, " disconnected");
				break;
			}

			messageHistory ~= ClientMessage(client.clientID, to!int(got), buffer);

			broadcastToAllClients();
		}

	}


	void broadcastToAllClients(){
		foreach(client; clientProfiles){
			// Send whatever the latest data was to all the
			// clients.
			if (client.alive == false)
				continue;
			while(mCurrentMessageToSend[client.clientID] <= messageHistory.length-1){
				ClientMessage msg = messageHistory[mCurrentMessageToSend[client.clientID]];
				if (msg.clientID == client.clientID){
					mCurrentMessageToSend[client.clientID]++;
					continue;
				}
				string prefix = "client " ~ to!string(msg.clientID) ~ ": ";
				char[] toSend = prefix.dup ~ msg.data[0 .. msg.length];
				string _data = toSend.idup(); 
				writeln("sending message from client ", msg.clientID, " to client ", client.clientID, " / msg: ", _data);
				client.socket.send(_data.dup);
				// Important to increment the message only after sending
				// the previous message to as many clients as exist.
				mCurrentMessageToSend[client.clientID]++;
			}
		}
	}


}

// Entry point to Server
void main(){
	// Note: I'm just using the defaults here.
	TCPServer server = new TCPServer;
	server.run();
}
