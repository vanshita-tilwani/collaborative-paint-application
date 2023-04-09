module dlangmafiacollabpaint;

import std.socket : Socket, AddressFamily, InternetAddress, SocketType;
import std.stdio;
import std.conv;
import std.regex;
import std.algorithm;
import core.stdc.stdlib : exit;
import core.thread.osthread;

import gio.Application : GioApplication = Application;

import gtk.Application;
import gtk.ApplicationWindow;
import gtk.DrawingArea;
import gtk.Widget;

import gdk.Event;
import gdk.Window;
import gdk.c.functions;

import cairo.c.types;
import cairo.c.functions;

import cairo.Context;
import cairo.Surface;
import cairo.ImageSurface;

import std.stdio;
import std.math;

struct coords {
	double x;
	double y;
	double r;
	double g;
	double b;
	double a;
}

class DrawingCanvas : DrawingArea
{
	Socket clientSocket;

	coords[] draw_coords;	
	bool drawing = false;
	
	// color
	double r = 30.0;
	double g = 0.4;
	double b = 200.3;
	double a = 0.8;

	public this(Application app, string host = "localhost", ushort port=50001)
	{
		// Socket setup
		writeln("Starting client...attempt to create socket");
		clientSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		clientSocket.connect(new InternetAddress(host, port));
		writeln("Client conncted to server");
		
		char[80] buffer;
		auto received = clientSocket.receive(buffer);
		writeln("(incoming from server) ", buffer[0 .. received]);

		new Thread({
			chatMessaging();
		}).start();

		new Thread({
			receiveDataFromServer();
		}).start();

		// Gio callback
		app.addOnShutdown(&onWindowClose);

		// GTK callbacks
		addOnDraw(&drawPixels);
		addOnMotionNotify(&onMouseMotion);
		addOnButtonPress(&onMousePress);
		addOnButtonRelease(&onButtonRelease);
	}

	~this(){
		clientSocket.close();
	}

	void chatMessaging(){
		bool clientRunning=true;
		
		while(clientRunning){
			foreach(line; stdin.byLine){
				clientSocket.send(line);
			}
		}
	}

	coords parseCoords(string draw_details){
		int x = -1;
		int y = -1;
		writeln(draw_details);
		writeln("4.1");
		auto match = matchFirst(draw_details, r"drw (\d+),(\d+) (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+.\d*) ");
		writeln("4.2");

		if (match.empty()) {
			writeln("4.2.1");
			return coords(0,0);
		}
		else {
			writeln("4.2.2");
			writeln(match);
			return coords(to!double(match[1]),
						  to!double(match[2]),
						  to!double(match[3]),
						  to!double(match[4]),
						  to!double(match[5]),
						  to!double(match[6]));
		}
	}

	void receiveDataFromServer(){
		while(true){	
			// Note: It's important to recreate or 'zero out' the buffer so that you do not
			// 			 get previous data leftover in the buffer.
			char[80] buffer;
			writeln("1");
			auto got = clientSocket.receive(buffer);
			writeln("2");
			auto fromServer = buffer[0 .. got];
			
			// extracting id and content
			auto match = matchFirst(fromServer, r"client (\d+): ([\S+\s+]+)");
			string msg_content = match[2].dup;
			writeln("3");
			if (msg_content.length > 0) {
				if (startsWith(msg_content, "drw")) {
					writeln("4");
					draw_coords ~= [parseCoords(msg_content)];
					writeln("5");
					queueDraw();
				}
				else
					writeln("(from server) ",fromServer);
			}
		}
	}

	// SHUTDOWN procedure
	public void onWindowClose(GioApplication app) {
		clientSocket.close();
		writeln("dlang mafia collaborative paint app shutting down");
		exit(0);
	}

	// GTK Event handling //
	public bool onMouseMotion(Event event, Widget widget) {
		bool value = false;

		if(event.type == EventType.MOTION_NOTIFY && drawing == true)
		{
			GdkEventButton* mouseEvent = event.button;
			draw_coords ~= [coords(mouseEvent.x, 
								   mouseEvent.y,
								   r,g,b,a)];
			widget.queueDraw();
			clientSocket.send("drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a) ~ " ");
			value = true;
		}

		return(value);
	}

	public bool onMousePress(Event event, Widget widget) {
		bool value = false;
		
		if(event.type == EventType.BUTTON_PRESS)
		{
			GdkEventButton* mouseEvent = event.button;
			draw_coords ~= [coords(mouseEvent.x, 
								   mouseEvent.y,
								   r,g,b,a)];
			widget.queueDraw();
			clientSocket.send("drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a) ~ " ");
			value = true;
			drawing = true;
		}

		return(value);
	}

	public bool onButtonRelease(Event event, Widget widget)
	{
		bool value = false;

		if(event.type == EventType.BUTTON_RELEASE)
		{
			GdkEventButton* mouseEvent = event.button;
			value = true;
			drawing = false;
		}

		return(value);
	}

	// GTK Drawing //
	public bool drawPixels(Scoped!Context cr, Widget widget) {
		foreach (coords cord ; draw_coords) {
			cr.setLineWidth(5);
			cr.setSourceRgba(cord.r, cord.g, cord.b, cord.a);
			cr.rectangle(cord.x, cord.y, 1, 1);
			cr.stroke();
		}

		return(true);	
	}
}

int main(string[] args){
	Application application;

	void activateCanvas(GioApplication app)
	{
		auto window = new ApplicationWindow(application);
		window.setTitle("Collaborative paint");
		window.setDefaultSize(600, 600);
		auto pt = new DrawingCanvas(application);
		window.add(pt);
		pt.show();
		window.showAll();
	}

	application = new Application("org.dlangmafia.collabpaint", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(&activateCanvas);
	return application.run(args);
}
