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

/**********
    This class represents the color picker and is used
    to choose color from the color chooser dialog.
*/
class MyColorChooserDialog : ColorChooserDialog
{
	private:
	string title = "Select Color";
	DialogFlags flags = GtkDialogFlags.MODAL;
	RGBA selectedColor;
	DrawingCanvas canvas;

	/***
	Public Constructor which is setting the drawing canvas and
	the parent window of the color picker dialog.
	*/
	public:
	this(Window _parentWindow, DrawingCanvas drawingCanvas)
	{
		super(title, _parentWindow);
		addOnResponse(&doSomething);
		run(); // no response ID because this dialog ignores it
		destroy();
		canvas = drawingCanvas;
	}

	/***
	Sets the color of the canvas as selected by the user. Specifically, sets
	R,G,B values for the canvas.
	*/
	protected:
	void doSomething(int response, Dialog d)
	{
		getRgba(selectedColor);
		canvas.r = cast(double) (selectedColor.red * 255.0);
		canvas.g = cast(double) (selectedColor.green * 255.0);
		canvas.b = cast(double) (selectedColor.blue * 255.0);
		canvas.a = cast(double) (selectedColor.alpha * 255.0);
	}

}