module unittests;

import std.stdio;
import std.socket;

/**
unit test for checking socket creation
*/
@("unit test for checking socket creation")
unittest{
    Socket serverSocket;
    string host = "localhost";
    ushort port = 50002;
    serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
	serverSocket.bind(new InternetAddress(host,port));
    bool isAlive = serverSocket.isAlive();
    assert(isAlive == true);
    serverSocket.close();
}

/**
unit test for checking socket closure
*/
@("unit test for checking socket closure")
unittest{
    Socket serverSocket;
    string host = "localhost";
    ushort port = 50002;
    serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
	serverSocket.bind(new InternetAddress(host,port));
    serverSocket.close();
    bool isAlive = serverSocket.isAlive();
    assert(isAlive == false);
}