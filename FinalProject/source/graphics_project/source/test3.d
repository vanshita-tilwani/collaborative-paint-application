import surface;
import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

@("Testing updating pixels out of bounds keeps the board blank.")
unittest {
    loadSDL();
    Surface imgSurface;
    int width = 320;
    int height = 320;
    imgSurface = Surface(width, height);

    // Updating pixel out of the board (right bottom)
    imgSurface.updatePixel(width + 1, height + 1);

    // Updating pixel out of the board (left top)
    imgSurface.updatePixel(-1, -1);

    // Updating pixel out of the board (left bottom)
    imgSurface.updatePixel(-1, height + 1);

    // Updating pixel out of the board (right center)
    imgSurface.updatePixel(width + 1, height / 2);

    // Updating pixel out of the board (center bottom)
    imgSurface.updatePixel(width / 2, height + 1);

    // Iterating through the whole board to see if there are any set pixels, all should be 0
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            assert(imgSurface.getPixelBoard()[i * imgSurface.getSurface().pitch + j * imgSurface.getSurface().format.BytesPerPixel + 0] == 0);
        }
    }

}