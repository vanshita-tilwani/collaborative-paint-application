module drawinstruction;

/**
Struct responsible for keeping track of draw information such as x,y
coordinates along with r,g,b,a component of the color.
*/
struct drawInstruction {
	double x;
	double y;
	double r;
	double g;
	double b;
	double a;
	int brush_size;
}