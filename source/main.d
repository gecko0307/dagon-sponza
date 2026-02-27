module main;

import std.stdio;
import dagon;
import scene;

class DemoGame: Game
{
    this(uint windowWidth, uint windowHeight, bool fullscreen, string title, string[] args)
    {
        super(windowWidth, windowHeight, fullscreen, title, args);
        currentScene = New!SponzaScene(this);
    }
}

void main(string[] args)
{
    DemoGame game = New!DemoGame(1280, 720, false, "Dagon Sponza", args);
    game.run();
    Delete(game);
    logInfo("Allocated memory: ", allocatedMemory);
}
