module pangocairo;
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
	coords[] draw_coords;	
	bool drawing = false;

	public this()
	{
		addOnDraw(&drawPixel);
		addOnMotionNotify(&onMouseMotion);
		addOnButtonPress(&onMousePress);
		addOnButtonRelease(&onButtonRelease);
	}

	public bool onMouseMotion(Event event, Widget widget) {
		bool value = false;

		if(event.type == EventType.MOTION_NOTIFY && drawing == true)
		{
			GdkEventButton* mouseEvent = event.button;
			writeln("Mouse motion ", mouseEvent.x, " ", mouseEvent.y);
			draw_coords ~= [coords(mouseEvent.x, mouseEvent.y)];
			widget.queueDraw();
			value = true;
		}

		return(value);
	}

	public bool onMousePress(Event event, Widget widget) {
		bool value = false;
		
		if(event.type == EventType.BUTTON_PRESS)
		{
			GdkEventButton* mouseEvent = event.button;
			writeln("Mouse pressed ", mouseEvent.x, " ", mouseEvent.y);
			draw_coords ~= [coords(mouseEvent.x, mouseEvent.y)];
			widget.queueDraw();
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
			writeln("Mouse released ", mouseEvent.x, " ", mouseEvent.y);
			value = true;
			drawing = false;
		}

		return(value);
	}

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


int main(string[] args)
{
	Application application;

	void activateCanvas(GioApplication app)
	{
		auto window = new ApplicationWindow(application);
		window.setTitle("Collaborative paint");
		window.setDefaultSize(600, 600);
		auto pt = new DrawingCanvas();
		window.add(pt);
		pt.show();
		window.showAll();

	}

	application = new Application("org.dlangmafia.collabpaint", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(&activateCanvas);
	return application.run(args);
}
