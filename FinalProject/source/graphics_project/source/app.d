/// Run with: 'dub'

// Import D standard libraries
import sdlapp;
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

// Entry point to program
void main() {
	SDLApp myApp = new SDLApp();
	myApp.MainApplicationLoop();
}
