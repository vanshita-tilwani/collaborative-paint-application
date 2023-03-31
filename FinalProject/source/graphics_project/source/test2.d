import surface;
import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

@("Testing correct pixels are updated on update pixel")
unittest {
    loadSDL();
    Surface imgSurface;
    imgSurface = Surface(640, 480);
    imgSurface.updatePixel(7, 7);
    ubyte* pixelBoard = imgSurface.getPixelBoard();
    assert(pixelBoard[7 * imgSurface.getSurface().pitch + 7 * imgSurface.getSurface().format.BytesPerPixel + 0] == 255);
    assert(pixelBoard[7 * imgSurface.getSurface().pitch + 7 * imgSurface.getSurface().format.BytesPerPixel + 1] == 128);
    assert(pixelBoard[7 * imgSurface.getSurface().pitch + 7 * imgSurface.getSurface().format.BytesPerPixel + 2] == 32);

    // Also check that the other pixels are not set
    assert(pixelBoard[4 * imgSurface.getSurface().pitch + 4 * imgSurface.getSurface().format.BytesPerPixel + 0] != 255);
    assert(pixelBoard[4 * imgSurface.getSurface().pitch + 4 * imgSurface.getSurface().format.BytesPerPixel + 1] != 128);
    assert(pixelBoard[4 * imgSurface.getSurface().pitch + 4 * imgSurface.getSurface().format.BytesPerPixel + 2] != 32);
}