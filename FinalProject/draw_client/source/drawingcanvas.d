module drawingcanvas;

import std.socket : Socket, AddressFamily, InternetAddress, SocketType;
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.stdio;
import std.math;
import std.algorithm;

import core.stdc.stdlib : exit;
import core.thread.osthread;

import gio.Application : GioApplication = Application;

import gtk.Application;
import gtk.ApplicationWindow;
import gtk.DrawingArea;
import gtk.Widget;
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.Box;
import gtk.Button;

import glib.Timeout;

import gdk.Event;
import gdk.Window;
import gdk.c.functions;

import cairo.c.types;
import cairo.c.functions;

import cairo.Context;
import cairo.Surface;
import cairo.ImageSurface;

import drawinstruction : drawInstruction;
// struct drawInstruction {
// 	double x;
// 	double y;
// 	double r;
// 	double g;
// 	double b;
// 	double a;
// 	int brush_size;
// }

class DrawingCanvas : DrawingArea
{
	Socket clientSocket;

	drawInstruction[] drawHistory;

	// Index to which we draw to
	long draw_head;
	
	bool drawing = false;
	
	// color
	double r = 255.1;
	double g = 0.1;
	double b = 0.1;
	double a = 1.1;

	// brush size
	int brush_size = 2;

	public this(Application app, ApplicationWindow window, string host = "localhost", ushort port=50001)
	{
		// Socket setup
		writeln("Starting client...attempt to create socket");
		clientSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		clientSocket.connect(new InternetAddress(host, port));
		writeln("Client conncted to server");

		new Thread({
			chatMessaging();
		}).start();

		new Thread({
			receiveDataFromServer();
		}).start();

		// Box
		const int globalPadding=2;
        const int localPadding= 2;
        auto myBox = new Box(Orientation.VERTICAL,globalPadding);
		

		// Menubar
		auto menuBar = new MenuBar;
		auto menuColorItem = new MenuItem("Color");
		auto menuBrushSizeItem = new MenuItem("Brush size");

		menuBar.append(menuColorItem);
		menuBar.append(menuBrushSizeItem);
		
		// Color submenu
		auto menuColor = new Menu;
		auto menuRed = new MenuItem("Red"); 
		auto menuGreen = new MenuItem("Green"); 
		auto menuBlue = new MenuItem("Blue"); 
		auto menuBlack = new MenuItem("Black"); 

		menuRed.addOnActivate(delegate void (MenuItem m){
				r = 255.1;
				g = 0.1;
				b = 0.1;
				a = 1.1;
			});
		menuGreen.addOnActivate(delegate void (MenuItem m){
				r = 0.1;
				g = 255.1;
				b = 0.1;
				a = 1.1;
			});
		menuBlue.addOnActivate(delegate void (MenuItem m){
				r = 0.1;
				g = 0.1;
				b = 255.1;
				a = 1.1;
			});
		menuBlack.addOnActivate(delegate void (MenuItem m){
				r = 0.1;
				g = 0.1;
				b = 0.1;
				a = 1.1;
			});
		
		menuColor.append(menuRed);
		menuColor.append(menuGreen);
		menuColor.append(menuBlue);
		menuColor.append(menuBlack);
		menuColorItem.setSubmenu(menuColor);

		// Brush size submenu
		auto menuBrushSize = new Menu;
		auto menuBrush1 = new MenuItem("1"); 
		auto menuBrush2 = new MenuItem("2"); 
		auto menuBrush3 = new MenuItem("3"); 
		auto menuBrush4 = new MenuItem("4");

		menuBrush1.addOnActivate(delegate void (MenuItem m){brush_size = 2;});
		menuBrush2.addOnActivate(delegate void (MenuItem m){brush_size = 4;});
		menuBrush3.addOnActivate(delegate void (MenuItem m){brush_size = 6;});
		menuBrush4.addOnActivate(delegate void (MenuItem m){brush_size = 8;});

		menuBrushSize.append(menuBrush1);
		menuBrushSize.append(menuBrush2);
		menuBrushSize.append(menuBrush3);
		menuBrushSize.append(menuBrush4);
		menuBrushSizeItem.setSubmenu(menuBrushSize);

        
		myBox.packStart(menuBar,false,false,0);
        myBox.packStart(this,true,true,localPadding);

		Button undoButton = new Button("Undo");
		Button redoButton = new Button("Redo");

		myBox.packStart(undoButton,false,false,localPadding);
		myBox.packStart(redoButton,false,false,localPadding);
		
		// These timeouts are meant to execute a function in time intervals
		// We use these to execute the redo and undo functions quicker
		// currently set to 10 ms
		Timeout undoTimeout;

		undoButton.addOnPressed(delegate void(Button b){
			undoTimeout = new Timeout(10, &undoAndSend, true);
		});

		undoButton.addOnReleased(delegate void(Button b){
			undoTimeout.stop();
		});

		Timeout redoTimeout;

		redoButton.addOnPressed(delegate void(Button b){
			redoTimeout = new Timeout(10, &redoAndSend, true);
		});

		redoButton.addOnReleased(delegate void(Button b){
			redoTimeout.stop();
		});

		window.add(myBox);
		window.showAll();

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

	bool undo(){
		if (draw_head > 0){
			draw_head--;
			queueDraw();
			return true;
		}
		return false;
	}

	bool redo(){
		if (draw_head < drawHistory.length){
			draw_head++;
			queueDraw();
			return true;
		}
		return false;
	}

	bool undoAndSend(){
		if (undo()){
			clientSocket.send(padMessage("undo"));
			return true;
		}
		return false;
	}
	
	bool redoAndSend(){
		if (redo()){
			clientSocket.send(padMessage("redo"));
			return true;
		}
		return false;
	}

	void chatMessaging(){
		bool clientRunning=true;
		
		while(clientRunning){
			foreach(line; stdin.byLine){
				clientSocket.send(padMessage(line.dup).dup);
			}
		}
	}

	void printDrawHead(){
		writeln("(debug) Draw head at ", draw_head, "/", drawHistory.length);
	}

	// Message format: drw x,y r,g,b,a 
	drawInstruction parseDrawInstruction(string draw_args){
		auto match = matchFirst(draw_args, r"drw (\d+),(\d+) (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+) ");

		if (match.empty()) {
			return drawInstruction(0,0); // this should trigger an exception
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


	void receiveDataFromServer(){
		while(true){	
			char[90] buffer;
			auto got = clientSocket.receive(buffer);
			auto fromServer = buffer[0 .. got]; 
			
			// extracting id and content
			auto match = matchFirst(fromServer, r"client (-*\d+): ([\S+\s+]+)");
			string msg_content = match[2].dup;
			if (msg_content.length > 0) {
				if (startsWith(msg_content, "drw")) {
					draw_head++;
					drawHistory = drawHistory[0 .. draw_head - 1];
					drawHistory ~= [parseDrawInstruction(msg_content)];
					queueDraw();
				}
				else if (startsWith(msg_content, "hello") && to!int(match[1]) == -1) {
					writeln("(debug) syncing draw head with server, ");
					auto matchHelloMsg = matchFirst(msg_content, r"hello (\d+) ");
					draw_head = to!long(matchHelloMsg[1]);
					queueDraw();
				}
				else if (startsWith(msg_content, "undo"))
					undo();
				else if (startsWith(msg_content, "redo"))
					redo();
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

	// Padding message with dots to be exactly 80 characters
	// It is crucial for messages sent to the server to be exactly 80 character
	// so that socket.receive can receive one message at a time
	char[80] padMessage(string data){
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

	// GTK Input Event handling //
	public bool onMouseMotion(Event event, Widget widget) {
		bool value = false;

		if(event.type == EventType.MOTION_NOTIFY && drawing == true)
		{
			GdkEventButton* mouseEvent = event.button;
			
			draw_head++;
			drawHistory = drawHistory[0 .. draw_head - 1]; // Cut the history to draw head to dissallow redo if someone draws

			drawHistory ~= [drawInstruction(mouseEvent.x, 
											mouseEvent.y,
											r,g,b,a,
											brush_size)];
			widget.queueDraw();
			// This could be moved to a function
			string data = "drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a)
							  ~ ", " ~ to!string(brush_size) ~ " ";
			clientSocket.send(padMessage(data));
			value = true;
		}

		return(value);
	}

	public bool onMousePress(Event event, Widget widget) {
		bool value = false;
		
		if(event.type == EventType.BUTTON_PRESS)
		{
			GdkEventButton* mouseEvent = event.button;

			draw_head++;
			drawHistory = drawHistory[0 .. draw_head - 1]; // Cut the history to draw head to dissallow redo if someone draws
			drawHistory ~= [drawInstruction(mouseEvent.x, 
											mouseEvent.y,
											r,g,b,a, 
											brush_size)];
			widget.queueDraw();
			// This could be moved to a function
			string data = "drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a)
							  ~ ", " ~ to!string(brush_size) ~ " ";
			clientSocket.send(padMessage(data));
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
		printDrawHead();
		for (long i = 0; i < draw_head; i++) {
			drawInstruction drawInstruction = drawHistory[i];
			cr.setLineWidth(drawInstruction.brush_size);
			cr.setSourceRgba(drawInstruction.r, 
							 drawInstruction.g, 
							 drawInstruction.b, 
							 drawInstruction.a);
			cr.rectangle(drawInstruction.x, drawInstruction.y, 1, 1);
			cr.stroke();
		}
		return(true);	
	}
}