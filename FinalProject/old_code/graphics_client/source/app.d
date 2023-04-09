/// Run with: 'dub'

// Import D standard libraries
import sdlapp;
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
import std.stdio;
import std.string;
import std.socket;

// Entry point to program
void main() {

	writeln("Starting graphics client...attempt to create socket");
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM);

	socket.connect(new InternetAddress("localhost", 50002));
	scope(exit) socket.close();
	writeln("Connected");

	char[1024] buffer;
	auto received = socket.receive(buffer);

	writeln("(Client connecting) ", buffer[0 .. received]);
	write(">");

	SDLApp myApp = new SDLApp();
	myApp.MainApplicationLoop(socket);

	foreach(line; stdin.byLine) {
		// Send the packet of information
		socket.send(line);
		// Now we'll immedietely block and await data from the server
		auto fromServer = buffer[0 .. socket.receive(buffer)];
		writeln("Server echos back: ", fromServer);
		write(">");
	}

}
