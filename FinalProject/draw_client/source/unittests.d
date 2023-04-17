module unittests;

import std.stdio;
import std.socket;
import utility;
import std.conv;
import drawinstruction : drawInstruction;
import core.exception : AssertError;
import std.exception;
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

@("unit test for utility method for undo command")
unittest {
    string message = "undo";
    char[80] data = Utility.padMessage(message);
    string result = to!string(data);
    assert(result == "undo............................................................................");
}

@("unit test for utility method for redo command")
unittest {
    string message = "redo";
    char[80] data = Utility.padMessage(message);
    string result = to!string(data);
    assert(result == "redo............................................................................");
}

@("unit test for strings > 80 length")
unittest {
    string message = "Hi, how are you doing. I hope it is going well for you. I hope to see you very soon.";
    char[80] data = Utility.padMessage(message);
    string result = to!string(data);
    assert(result == "Hi, how are you doing. I hope it is going well for you. I hope to see you very s");
}

@("unit test for strings = 80 length")
unittest {
    string message = "Hi, how are you doing. I hope it is going well for you. I hope to see you sooonn";
    char[80] data = Utility.padMessage(message);
    string result = to!string(data);
    assert(result == "Hi, how are you doing. I hope it is going well for you. I hope to see you sooonn");
}

@("utility method for draw instructions")
unittest {
    assertThrown!Exception(Utility.parseDrawInstruction("undo"));
}

@("utility method for draw instructions for brush size = 2")
unittest {
    auto instructions = Utility.parseDrawInstruction("drw 296,98 153, 193, 241, 255, 2 ...............................................");
    assert(instructions.x == 296.0);
    assert(instructions.y == 98.0);
    assert(instructions.r == 153.0);
    assert(instructions.g == 193.0);
    assert(instructions.b == 241.0);
    assert(instructions.a == 255.0);
    assert(instructions.brush_size == 2);
}


@("utility method for draw instructions for brush size = 3")
unittest {
    auto instructions = Utility.parseDrawInstruction("drw 198,98 153, 193, 241, 255, 3 ...............................................");
    assert(instructions.x == 198.0);
    assert(instructions.y == 98.0);
    assert(instructions.r == 153.0);
    assert(instructions.g == 193.0);
    assert(instructions.b == 241.0);
    assert(instructions.a == 255.0);
    assert(instructions.brush_size == 3);
}

@("utility method for draw instructions for brush size = 4")
unittest {
    auto instructions = Utility.parseDrawInstruction("drw 198,98 153, 193, 241, 255, 4 ...............................................");
    assert(instructions.x == 198.0);
    assert(instructions.y == 98.0);
    assert(instructions.r == 153.0);
    assert(instructions.g == 193.0);
    assert(instructions.b == 241.0);
    assert(instructions.a == 255.0);
    assert(instructions.brush_size == 4);
}

