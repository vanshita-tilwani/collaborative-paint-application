import std.stdio;

import gtk.Main;
import gtk.MainWindow;
import gtk.Box;
import gtk.Window;
import gtk.Button;
import gtk.Dialog;
import gtk.ColorChooserDialog;
import gdk.RGBA;

import drawingcanvas;

class MyColorChooserDialog : ColorChooserDialog
{
	private:
	string title = "Select Color";
	DialogFlags flags = GtkDialogFlags.MODAL;
	RGBA selectedColor;
	DrawingCanvas canvas;

	public:
	this(Window _parentWindow, DrawingCanvas drawingCanvas)
	{
		super(title, _parentWindow);
		addOnResponse(&doSomething);
		run(); // no response ID because this dialog ignores it
		destroy();
		canvas = drawingCanvas;
	} // this()

	protected:
	void doSomething(int response, Dialog d)
	{
		getRgba(selectedColor);
		writeln("New color selection: ", selectedColor.red);
		writeln("Canvas red: ", canvas.r);
		writeln("Canvas green: ", canvas.g);
		writeln("Canvas blue: ", canvas.b);
		canvas.r = cast(double) (selectedColor.red * 255.0);
		canvas.g = cast(double) (selectedColor.green * 255.0);
		canvas.b = cast(double) (selectedColor.blue * 255.0);
		canvas.a = cast(double) (selectedColor.alpha * 255.0);
		writeln("Now reassigned to");
		writeln("Canvas red: ", canvas.r);
		writeln("Canvas green: ", canvas.g);
		writeln("Canvas blue: ", canvas.b);
	} // doSomething()

} // class MyColorChooserDialog