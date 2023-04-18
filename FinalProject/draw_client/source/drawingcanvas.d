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
import gtk.ScrolledWindow;
import gtk.TextView;
import gtk.TextBuffer;
import gtk.ColorChooserDialog;
import gtk.Entry;

import glib.Timeout;

import gdk.Event;
import gdk.Window;
import gdk.c.functions;

import cairo.c.types;
import cairo.c.functions;

import cairo.Context;
import cairo.Surface;
import cairo.ImageSurface;
import colorchooser;
import gtk.Dialog;
import gdk.RGBA;
import utility;
import drawinstruction : drawInstruction;

class DrawingCanvas : DrawingArea
{
	Socket clientSocket;

	drawInstruction[] drawHistory;

    TextView chatHistoryText;
    

	// Index to which we draw to
	long draw_head;
	
	bool drawing = false;
	
	// color
	static double r = 153;
	static double g = 193;
	static double b = 241;
	static double a = 255;

	// brush size
	int brush_size = 2;
	DrawingCanvas canvas;

	public this(Application app, ApplicationWindow window, string host = "localhost", ushort port=50002)
	{
		canvas = this;
		// Socket setup
		writeln("Starting client...attempt to create socket");
		clientSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		clientSocket.connect(new InternetAddress(host, port));
		writeln("Client conncted to server");

		auto myChatWindow = new ScrolledWindow();
        chatHistoryText = new TextView();
        chatHistoryText.setEditable(false);
        myChatWindow.add(chatHistoryText);
        // auto mychatText = new TextView();
        // mychatText.getBuffer().setText("Hello");
        // mychatText.setEditable(true);
        auto mychatText = new Entry();
		mychatText.setPlaceholderText("Type here and press `Send Chat`");
        auto sendChatButton = new SendButton("Send Chat", mychatText, chatHistoryText, clientSocket);

		new Thread({
			chatMessaging();
		}).start();

		new Thread({
			receiveDataFromServer();
		}).start();

		// Box
		const int globalPadding=2;
        const int localPadding= 5;
        auto myBox = new Box(Orientation.VERTICAL, globalPadding);
		

		// Menubar
		auto menuBar = new MenuBar;
		auto menuColorItem = new MenuItem("Color");
		auto menuBrushSizeItem = new MenuItem("Brush size");

		menuBar.append(menuColorItem);
		menuBar.append(menuBrushSizeItem);
		
		// Color submenu
		auto menuColor = new Menu;
		auto menuColorPicker = new MenuItem("Pick Color");

		menuColorPicker.addOnActivate(delegate void (MenuItem m){
			auto colorPickerDialog = new MyColorChooserDialog(window, canvas);
		});
		
		menuColor.append(menuColorPicker);
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

        this.setSizeRequest(400, 400);
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


        
        // Chat Box
        // auto entry = new Entry();
        // entry.addOnKeyRelease(&onKeyRelease);
        // entry.activate();

		
        // Timeout sendChatTimeout;

		// redoButton.addOnPressed(delegate void(Button b){
		// 	sendChatTimeout = new Timeout(10, &sendChatData, true);
		// });

		// redoButton.addOnReleased(delegate void(Button b){
		// 	sendChatTimeout.stop();
		// });

        // sendChatButton.addOnButtonPress(&sendChatData);

        // Add chat window
        myBox.packStart(myChatWindow, true, true, localPadding);
        myBox.packStart(mychatText, true, true, localPadding);
        myBox.packStart(sendChatButton,false,false,localPadding);

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

	void changeColor() {

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
			clientSocket.send(Utility.padMessage("undo"));
			return true;
		}
		return false;
	}
	
	bool redoAndSend(){
		if (redo()){
			clientSocket.send(Utility.padMessage("redo"));
			return true;
		}
		return false;
	}

	void chatMessaging(){
		bool clientRunning=true;
		
		while(clientRunning){
			foreach(line; stdin.byLine){
				clientSocket.send(Utility.padMessage(line.dup).dup);
			}
		}
	}

	void printDrawHead(){
		writeln("(debug) Draw head at ", draw_head, "/", drawHistory.length);
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
					drawHistory ~= [Utility.parseDrawInstruction(msg_content)];
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
				else{
					writeln("(from server) ",fromServer);
					string toWrite = to!string(fromServer) ~ "\n";
					string chatMessage = "";

					foreach (ch; toWrite)
					{
						if (ch != '.') {
							chatMessage ~= ch;
						}
					}
					chatHistoryText.appendText(chatMessage);
                    // chatHistoryText.queueDraw();
				}
                    
			}
		}
	}

	// SHUTDOWN procedure
	public void onWindowClose(GioApplication app) {
		clientSocket.close();
		writeln("dlang mafia collaborative paint app shutting down");
		exit(0);
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
			clientSocket.send(Utility.padMessage(data));
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
			clientSocket.send(Utility.padMessage(data));
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
		foreach (i, drawInstruction; drawHistory) {
			if (i == draw_head)
				break;
			cr.setLineWidth(drawInstruction.brush_size);
			cr.setSourceRgba(drawInstruction.r/255.0,
							 drawInstruction.g/255.0,
							 drawInstruction.b/255.0,
							 drawInstruction.a/255.0);
			cr.rectangle(drawInstruction.x, drawInstruction.y, 1, 1);
			cr.stroke();
		}
		return(true);	
	}

    // public bool onKeyRelease(Event event, Widget widget){
    //     bool value = false;

	// 	if(event.type == EventType.KEY_RELEASE)
	// 	{
	// 		GdkEventKey* enterEvent = event.key;
	// 		messageHistory ~= "hello";
    //         queueDraw();
	// 	}
    //     return (true);
    // }

    // public bool sendChatData(Event event, Widget widget){
    //         bool value = false;

	// 	if(event.type == EventType.BUTTON_PRESS)
	// 	{
	// 		GdkEventKey* enterEvent = event.key;
	// 		messageHistory ~= mychatText.getBuffer().getText();
    //         writeln(messageHistory[0]);
    //         queueDraw();
	// 	}
    //     return (true);

    // }

    // bool sendChatData(){
        
    //             // messageHistory ~= mychatText.getBuffer().getText();
    //             messageHistory ~= "LOL";
    //         writeln(messageHistory[0]);
        
	// 	return false;
	// }

}

class SendButton : Button
{
    Entry entry = null;
    TextView textview = null;
    Socket clientSocket;

    this(in string text, Entry ent, TextView tv, Socket cSocket){
        super(text);
        this.entry = ent;
        this.textview = tv;
        this.clientSocket = cSocket;
        addOnButtonRelease(&read);
    } 

    private bool read(Event event, Widget widget){
		writeln("writing text right here");
        if(entry.getText){
            clientSocket.send(Utility.padMessage(entry.getText()).dup);
            entry.setText("");
        }
        return true;
    }
}
