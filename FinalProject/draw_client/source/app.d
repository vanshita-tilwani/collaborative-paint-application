module dlangmafiacollabpaint;

import std.socket : Socket, AddressFamily, InternetAddress, SocketType;
import std.stdio;
import std.conv;
import std.regex;
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
}

class DrawingCanvas : DrawingArea
{
	Socket clientSocket;

	coords[] draw_coords;	
	bool drawing = false;

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
		
		write(">");
		while(clientRunning){
			foreach(line; stdin.byLine){
				write(">");
				// Send the packet of information
				clientSocket.send(line);
			}
				// Now we'll immedietely block and await data from the server
		}
	}

	coords parseCoords(string str_coords){
		auto r = regex(r"(\d+),(\d+)");
		int x = -1;
		int y = -1;
		auto exp = matchFirst(str_coords, r);
		if (exp.empty()) {
			return coords(0,0);
		}
		else {
			return coords(to!double(exp[1]),to!double(exp[2]));
		}
	}

	void receiveDataFromServer(){
		while(true){	
			// Note: It's important to recreate or 'zero out' the buffer so that you do not
			// 			 get previous data leftover in the buffer.
			char[80] buffer;
			
			auto got = clientSocket.receive(buffer);

			auto fromServer = buffer[0 .. got];

			if (fromServer.length > 0) {
				if (fromServer[10 .. 13] == "drw") {
					draw_coords ~= [parseCoords(fromServer[10 .. fromServer.length].dup)];
					queueDraw();
				}
				else
					writeln("(from server)>",fromServer);
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
			draw_coords ~= [coords(mouseEvent.x, mouseEvent.y)];
			widget.queueDraw();
			clientSocket.send("drw " ~ to!string(mouseEvent.x) ~ "," ~ to!string(mouseEvent.y));
			value = true;
		}

		return(value);
	}

	public bool onMousePress(Event event, Widget widget) {
		bool value = false;
		
		if(event.type == EventType.BUTTON_PRESS)
		{
			GdkEventButton* mouseEvent = event.button;
			draw_coords ~= [coords(mouseEvent.x, mouseEvent.y)];
			widget.queueDraw();
			clientSocket.send("drw " ~ to!string(mouseEvent.x) ~ "," ~ to!string(mouseEvent.y));
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
		foreach (coords coordinates ; draw_coords) {
			cr.setLineWidth(5);
			cr.setSourceRgba(0.1, 0.2, 0.3, 0.8);
			cr.rectangle(coordinates.x, coordinates.y, 1, 1);
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
