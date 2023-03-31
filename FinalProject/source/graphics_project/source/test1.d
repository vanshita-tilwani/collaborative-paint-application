import surface;
import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

@("Testing the set value for height of the surface")
unittest {
    loadSDL();
    Surface imgSurface;
    imgSurface = Surface(640, 480);
    assert(imgSurface.height == 480);
}

@("Testing the set value for width of the surface")
unittest {
    loadSDL();
    Surface imgSurface;
    imgSurface = Surface(640, 480);
    assert(imgSurface.width == 640);
}