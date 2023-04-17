module utility;

import drawinstruction : drawInstruction;
import std.regex;
import std.conv;

class Utility
{
	// Padding message with dots to be exactly 80 characters
	// It is crucial for messages sent to the server to be exactly 80 character
	// so that socket.receive can receive one message at a time
	public static char[80] padMessage(string data){
		char[80] buffer;
		char[] temp = data.dup;
		for (int i = 0; i < 80; i++) {
			if (i < data.length)
				buffer[i] = temp[i];
			else
				buffer[i] = '.';
		}
		return buffer;
	}

	// Message format: drw x,y r,g,b,a
	public static drawInstruction parseDrawInstruction(string draw_args){
		auto match = matchFirst(draw_args, r"drw (\d+),(\d+) (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+) ");

		if (match.empty()) {
			// this should trigger an exception
			throw new Exception("Illegal Argument");

		}
		else {
			return drawInstruction(to!double(match[1]),
			to!double(match[2]),
			to!double(match[3]),
			to!double(match[4]),
			to!double(match[5]),
			to!double(match[6]),
			to!int(match[7]));
		}
	}

}
