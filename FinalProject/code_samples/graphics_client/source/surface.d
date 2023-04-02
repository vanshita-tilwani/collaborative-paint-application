import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

struct Surface {
    SDL_Surface* surface;

    int width;
    int height;

    this(int width, int height) {
        this.width = width;
        this.height = height;
        surface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
    }

    ~this() {
        SDL_FreeSurface(surface);
    }

    void updatePixel(int xPos, int yPos) {
        SDL_LockSurface(surface);

        scope(exit) SDL_UnlockSurface(surface);

        ubyte* pixelArray = cast(ubyte*)surface.pixels;

        if (xPos > 0 && xPos <= width && yPos <= height && yPos > 0) {
            pixelArray[yPos * surface.pitch + xPos * surface.format.BytesPerPixel + 0] = 255;
            pixelArray[yPos * surface.pitch + xPos * surface.format.BytesPerPixel + 1] = 128;
            pixelArray[yPos * surface.pitch + xPos * surface.format.BytesPerPixel + 2] = 32;
        }
    }

    ubyte* getPixelBoard() {
        return cast(ubyte*)surface.pixels;
    }

    SDL_Surface* getSurface() {
        return surface;
    }

}