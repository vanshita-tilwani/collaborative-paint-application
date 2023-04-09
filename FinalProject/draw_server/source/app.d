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
	char[80] data;
}

/// The purpose of the TCPServer is to accept
/// multiple client connections.
/// Every client that connects will have its own thread
/// for the server to broadcast information to each client.
class TCPServer{

	/// The listening socket is responsible for handling new client connections.
	Socket mListeningSocket;
	/// Stores the clients that are currently connected to the server.
	ClientProfile[] mClientsConnectedToServer;

	/// Stores all of the data on the server. Ideally, we'll
	/// use this to broadcast out to clients connected.
	ClientMessage[] mServerData;
	/// Keeps track of the last message that was broadcast out to each client.
	long[int] mCurrentMessageToSend;

	int clientIDCounter = 0;
	int[] removedClients;
	
	/// Constructor
	this(string host = "localhost", ushort port=50001, ushort maxConnectionsBacklog=4){
		writeln("Starting server...");
		writeln("Server must be started before clients may join");
		// Note: AddressFamily.INET tells us we are using IPv4 Internet protocol
		// Note: SOCK_STREAM (SocketType.STREAM) creates a TCP Socket
		//       If you want UDPClient and UDPServer use 'SOCK_DGRAM' (SocketType.DGRAM)
		mListeningSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		// Set the hostname and port for the socket
		// NOTE: It's possible the port number is in use if you are not able
		//  	 to connect. Try another one.
		// When we 'bind' we are assigning an address with a port to a socket.
		mListeningSocket.bind(new InternetAddress(host,port));
		// 'listen' means that a socket can 'accept' connections from another socket.
		// Allow 4 connections to be queued up in the 'backlog'
		mListeningSocket.listen(maxConnectionsBacklog);
	}

	/// Destructor
	~this(){
		// Close our server listening socket
		// TODO: If it was never opened, no need to call close
		mListeningSocket.close();
	}

	/// Call this after the server has been created
	/// to start running the server
	void run(){		  

		while(true){
			// The servers job now is to just accept connections
			writeln("Waiting to accept more connections");
			/// accept is a blocking call.
			auto newClientSocket = mListeningSocket.accept();
			// After a new connection is accepted, let's confirm.
			writeln("Hey, a new client joined!");
			writeln("(me)",newClientSocket.localAddress(),
			"<---->",newClientSocket.remoteAddress(),"(client)");
			// Now pragmatically what we'll do, is spawn a new
			// thread to handle the work we want to do.
			// Per one client connection, we will create a new thread
			// in which the server will relay messages to clients.
			ClientProfile newClient = ClientProfile(newClientSocket, clientIDCounter, true);
			
			mClientsConnectedToServer ~= newClient;
			// Set the current client to have '0' total messages received.
			// NOTE: You may not want to start from '0' here if you do not
			//       want to send a client the whole history.
			mCurrentMessageToSend[newClient.clientID] = mServerData.length;

			writeln("Friends on server = ", mClientsConnectedToServer.length);
			// Let's send our new client friend a welcome message
			newClient.socket.send("Hello friend\0");

			// Now we'll spawn a new thread for the client that
			// has recently joined.
			// The server will now be running multiple threads and
			// handling a chat here with clients.
			//
			// NOTE: The index sent indicates the connection in our data structures,
			//       this can be useful to identify different clients.
			new Thread({
					clientLoop(newClient);
				}).start();

			clientIDCounter++;
			// After our new thread has spawned, our server will now resume
			// listening for more client connections to accept.
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
			writeln("Received some data (bytes): ",got);
			if (got == 0) {
				// Then remove the socket
				runThreadLoop = false;
				client.alive = false;
				writeln("client ", client.clientID, " disconnected");
				break;
			}
			// TODO: Note, you might want to verify 'got'
			//       is infact 80 bytes

			// Store data that we receive in our server.
			// We append the buffer to the end of our server
			// data structure.
			// NOTE: Probably want to make this a ring buffer,
			//       so that it does not grow infinitely.
			mServerData ~= ClientMessage(client.clientID, to!int(got), buffer);

			/// After we receive a single message, we'll just
			/// immedietely broadcast out to all clients some data.
			broadcastToAllClients();
		}

	}

	/// The purpose of this function is to broadcast
	/// messages to all of the clients that are currently
	/// connected.
	void broadcastToAllClients(){
		writeln("Broadcasting to :", mClientsConnectedToServer.length);

		foreach(client; mClientsConnectedToServer){
			// Send whatever the latest data was to all the
			// clients.
			if (client.alive == false)
				continue;
			while(mCurrentMessageToSend[client.clientID] <= mServerData.length-1){
				ClientMessage msg = mServerData[mCurrentMessageToSend[client.clientID]];
				string prefix = "client " ~ to!string(msg.clientID) ~ ": ";
				char[] toSend = prefix.dup ~ msg.data[0 .. msg.length];
				string _data = toSend.idup(); // create immutable copy
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
