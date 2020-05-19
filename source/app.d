module main;

import std.stdio;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

import grid;

int main() {
	// TODO: Split globals and management funcs to different files/modules
	auto grid = GridStruct(800, 600, 64, 64);

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	// TODO: dynamic video mode
	auto mode = sfVideoMode(grid.windowWidth, grid.windowHeight);
	auto window = sfRenderWindow_create(mode, "Game of Life experiment", sfResize | sfClose, null);

	if (!window)
    return 1;

	sfEvent event;
	while (sfRenderWindow_isOpen(window)) {
		sfRenderWindow_clear(window, sfBlack);

		while (sfRenderWindow_pollEvent(window, &event)) {
			if (event.type == sfEvtClosed)
				sfRenderWindow_close(window);
			if (event.type == sfEvtResized) {
        // update the view to the new size of the window
        auto visibleArea = sfFloatRect(0, 0, event.size.width, event.size.height);
        sfRenderWindow_setView(window, sfView_createFromRect(visibleArea));
				grid.windowWidth = event.size.width;
				grid.windowHeight = event.size.height;
				grid.recalculateScale();
    	}
		}

		grid.iterate();

		// FIXME: drawing cells
		foreach (key, value; grid.alive) {
			auto rectangle = sfRectangleShape_create();
			sfRectangleShape_setFillColor(rectangle, sfWhite);
			sfRectangleShape_setSize(rectangle, sfVector2f(grid.scale, grid.scale));
			sfRectangleShape_setOrigin(rectangle, sfVector2f(
				grid.calculateX(key[1]), 
				grid.calculateY(key[0])
			));
			sfRenderWindow_drawRectangleShape(window, rectangle, null);
  	}

		sfRenderWindow_display(window);
	}

	return 0;
}
