module dlangmafiacollabpaint;

import gio.Application : GioApplication = Application;
import gtk.Application;
import gtk.ApplicationWindow;
import drawingcanvas;
import std;

int main(string[] args){
	Application application;

	 write("Please input a server ip address for the client to connect to: ");
	 string host = readln().chomp;
	 write("Please input a port number for the client to connect to: ");
	 ushort port = to!ushort(readln().chomp);

	void activateCanvas(GioApplication app)
	{
		auto window = new ApplicationWindow(application);
		window.setTitle("Collaborative paint");
		window.setDefaultSize(600, 600);
		auto pt = new DrawingCanvas(application, window, host, port);
	}

	application = new Application("org.dlangmafia.collabpaint", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(&activateCanvas);
	return application.run(args);
}
