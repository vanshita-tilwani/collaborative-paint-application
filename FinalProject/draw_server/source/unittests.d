module unittests;

import std.stdio;
import std.socket;
@("unit test for checking socket creation")
unittest{
    Socket serverSocket;
    string host = "localhost";
    ushort port = 50002;
    serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
	serverSocket.bind(new InternetAddress(host,port));
    bool isAlive = serverSocket.isAlive();
    assert(isAlive == true);

    // auto results = getAddressInfo("127.0.0.1",
    // AddressInfoFlags.NUMERICHOST);
    // // writeln(results.length);
    // assert(results.length && results[0].family ==
    // AddressFamily.INET);

    serverSocket.close();
}

@("unit test for checking socket closure")
unittest{
    Socket serverSocket;
    string host = "localhost";
    ushort port = 50002;
    serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
	serverSocket.bind(new InternetAddress(host,port));

    // auto results = getAddressInfo("127.0.0.1",
    // AddressInfoFlags.NUMERICHOST);
    // // writeln(results.length);
    // assert(results.length && results[0].family ==
    // AddressFamily.INET);

    serverSocket.close();
    bool isAlive = serverSocket.isAlive();
    assert(isAlive == false);
}