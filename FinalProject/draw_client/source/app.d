module dlangmafiacollabpaint;

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

import gdk.Event;
import gdk.Window;
import gdk.c.functions;

import cairo.c.types;
import cairo.c.functions;

import cairo.Context;
import cairo.Surface;
import cairo.ImageSurface;

struct coords {
	double x;
	double y;
	double r;
	double g;
	double b;
	double a;
	int brush_size;
}

class DrawingCanvas : DrawingArea
{
	Socket clientSocket;

	coords[] draw_coords;

	// Keeps track of what to draw
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
		
		char[80] buffer;
		auto received = clientSocket.receive(buffer);
		writeln("(incoming from server) ", buffer[0 .. received]);

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
		myBox.packStart(this,true,true,localPadding);

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

		Button undoButton = new Button("Undo");
		Button redoButton = new Button("Redo");

		myBox.packStart(undoButton,false,false,localPadding);
		myBox.packStart(redoButton,false,false,localPadding);
		
		undoButton.addOnPressed(delegate void(Button b){
			if (draw_head > 0){
				draw_head--;
				queueDraw();
				clientSocket.send(formatDrawMsg("undo"));
				printDrawHead();
			}
		});
		
		// undoButton.addOnReleased(delegate void(Button b){
		// 	writeln("undo release");
		// });

		redoButton.addOnPressed(delegate void(Button b){
			if (draw_head < draw_coords.length){
				draw_head++;
				queueDraw();
				clientSocket.send(formatDrawMsg("redo"));
				printDrawHead();
			}
		});

		// redoButton.addOnReleased(delegate void(Button b){
		// 	writeln("redo release");
		// });

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

	void chatMessaging(){
		bool clientRunning=true;
		
		while(clientRunning){
			foreach(line; stdin.byLine){
				clientSocket.send(line);
			}
		}
	}

	void printDrawHead(){
		writeln("Draw head at ", draw_head, "/", draw_coords.length);
	}

	coords parseCoords(string draw_details){
		int x = -1;
		int y = -1;
		auto match = matchFirst(draw_details, r"drw (\d+),(\d+) (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+.\d*), (\d+) ");

		if (match.empty()) {
			return coords(0,0);
		}
		else {
			return coords(to!double(match[1]),
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
			auto match = matchFirst(fromServer, r"client (\d+): ([\S+\s+]+)");
			string msg_content = match[2].dup;
			if (msg_content.length > 0) {
				if (startsWith(msg_content, "drw")) {
					draw_head++;
					draw_coords = draw_coords[0 .. draw_head - 1];
					draw_coords ~= [parseCoords(msg_content)];
					queueDraw();
					printDrawHead();
				}
				else if (startsWith(msg_content, "undo")){
					if (draw_head > 0){
						draw_head--;
						queueDraw();
						printDrawHead();
					}
				}
				else if (startsWith(msg_content, "redo")){
					if (draw_head < draw_coords.length){
						draw_head++;
						queueDraw();
						printDrawHead();
					}	
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

	// Formatting message to be exactly 80 characters
	// this is crucial for socket.receive to receive exactly one message 
	// at a time
	char[80] formatDrawMsg(string data){
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
			draw_coords = draw_coords[0 .. draw_head - 1];

			draw_coords ~= [coords(mouseEvent.x, 
								   mouseEvent.y,
								   r,g,b,a,
								   brush_size)];
			widget.queueDraw();
			string data = "drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a)
							  ~ ", " ~ to!string(brush_size) ~ " ";
			clientSocket.send(formatDrawMsg(data));
			printDrawHead();
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
			draw_coords = draw_coords[0 .. draw_head - 1];
			draw_coords ~= [coords(mouseEvent.x, 
								   mouseEvent.y,
								   r,g,b,a, 
								   brush_size)];
			widget.queueDraw();
			string data = "drw " 
			                  ~ to!string(mouseEvent.x) 
							  ~ "," ~ to!string(mouseEvent.y) 
							  ~ " " ~ to!string(r)
							  ~ ", " ~ to!string(g)
							  ~ ", " ~ to!string(b)
							  ~ ", " ~ to!string(a)
							  ~ ", " ~ to!string(brush_size) ~ " ";
			clientSocket.send(formatDrawMsg(data));
			printDrawHead();
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
		for (long i = 0; i < draw_head; i++) {
			coords cord = draw_coords[i];
			cr.setLineWidth(cord.brush_size);
			cr.setSourceRgba(cord.r, cord.g, cord.b, cord.a);
			cr.rectangle(cord.x, cord.y, 1, 1);
			cr.stroke();
		}
		return(true);	
	}
}

int main(string[] args){
	Application application;

	// write("Please input a server ip address for the client to connect to: ");
	// string host = readln().chomp;
	// write("Please input a port number for the client to connect to: ");
	// ushort port = to!ushort(readln().chomp);

	void activateCanvas(GioApplication app)
	{
		auto window = new ApplicationWindow(application);
		window.setTitle("Collaborative paint");
		window.setDefaultSize(600, 600);
		auto pt = new DrawingCanvas(application, window);
	}

	application = new Application("org.dlangmafia.collabpaint", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(&activateCanvas);
	return application.run(args);
}
