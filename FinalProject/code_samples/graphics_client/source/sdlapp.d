import std.stdio;
import std.string;
import std.socket;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
import surface;

SDL_Window* window;
Surface imgSurface;
const SDLSupport ret;

shared static this() {

    version(Windows){
        writeln("Searching for SDL on Windows");
        ret = loadSDL("SDL2.dll");
    }
    version(OSX){
        writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){
        writeln("Searching for SDL on Linux");
        ret = loadSDL();
    }

    if (ret != sdlSupport) {
        writeln("error loading SDL library");

        foreach (info; loader.errors) {
            writeln(info.error,':', info.message);
        }
    }

    if (ret == SDLSupport.noLibrary) {
        writeln("error no library found");
    }

    if (ret == SDLSupport.badLibrary) {
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }

    // Initialize SDL
    if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }

    window = SDL_CreateWindow("D SDL Painting", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_SHOWN);
    imgSurface = Surface(640, 480);

}

shared static ~this() {
    SDL_DestroyWindow(window);
    SDL_Quit();
    writeln("Ending application--good bye!");
}

class SDLApp {

    bool runApplication = true;
    bool drawing = false;

    public:

    void MainApplicationLoop(Socket socket) {
        while (runApplication) {
            SDL_Event e;

            while (SDL_PollEvent(&e) != 0) {
                if (e.type == SDL_QUIT) {
                    runApplication = false;
                }
                else if (e.type == SDL_MOUSEBUTTONDOWN) {
                    drawing = true;
                }
                else if (e.type == SDL_MOUSEBUTTONUP) {
                        drawing = false;
                    }
                    else if (e.type == SDL_MOUSEMOTION && drawing) {
                            int xPos = e.button.x;
                            int yPos = e.button.y;

                            if (xPos > 0 && yPos > 0) {
                                socket.send(format("%s,%s",xPos, yPos));
                            }



                            int brushSize = 4;
                            for (int w = -brushSize; w < brushSize; w++) {
                                for (int h = -brushSize; h < brushSize; h++) {
                                    imgSurface.updatePixel(xPos + w, yPos + h);
                                }
                            }
                        }
            }

            SDL_BlitSurface(imgSurface.surface, null, SDL_GetWindowSurface(window), null);
            SDL_UpdateWindowSurface(window);
            SDL_Delay(16);
        }
    }
}


