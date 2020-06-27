module main;

import std.stdio;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

import grid;
import renderer;

int main() {
	auto grid = GridStruct(160, 90);
	auto render = Renderer(800, 600, &grid);

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	auto mode = sfVideoMode(render.windowWidth, render.windowHeight);
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
				render.windowWidth = event.size.width;
				render.windowHeight = event.size.height;
				render.recalculateScale();
    	}
		}

		grid.iterate();

		// FIXME: drawing cells
		foreach (key, value; grid.alive) {
			auto rectangle = sfRectangleShape_create();
			sfRectangleShape_setFillColor(rectangle, sfWhite);
			sfRectangleShape_setSize(rectangle, sfVector2f(render.scale, render.scale));
			sfRectangleShape_setOrigin(rectangle, sfVector2f(
				render.calculateX(key[0]), 
				render.calculateY(key[1])
			));
			sfRenderWindow_drawRectangleShape(window, rectangle, null);
  	}

		sfRenderWindow_display(window);
	}

	return 0;
}
