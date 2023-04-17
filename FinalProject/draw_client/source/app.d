module dlangmafiacollabpaint;

import gio.Application : GioApplication = Application;
import gtk.Application;
import gtk.ApplicationWindow;
import drawingcanvas;

int main(string[] args){
	Application application;

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
