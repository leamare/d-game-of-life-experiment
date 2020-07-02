module main;

import std.stdio;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

import grid;
import renderer;

int main() {
	const auto baseColor = sfColor(0, 96, 255, 192);
	const auto cellColor = sfColor(255, 255, 255, 255);
	const ubyte fadeOutSpeed = 4;
	const ubyte ditFadeOutSpeed = 6;
	const ubyte deadMaxColor = baseColor.a / fadeOutSpeed;
	const byte deadInitialTrail = cast(byte)(cellColor.r / (ditFadeOutSpeed*fadeOutSpeed) - 2);

	const uint gridMultiplier = 24;
	const uint renderMultiplier = 100;

	auto grid = GridStruct(16*gridMultiplier, 9*gridMultiplier, deadMaxColor);
	auto render = Renderer(16*renderMultiplier, 9*renderMultiplier, &grid);

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	auto mode = sfVideoMode(render.windowWidth, render.windowHeight);
	auto window = sfRenderWindow_create(mode, "Game of Life experiment", sfResize | sfClose, null);

	if (!window)
    return 1;

	auto rectangle = sfRectangleShape_create();

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

		auto color = sfColor(baseColor.r, baseColor.g, baseColor.b, 0);

		foreach (key, value; grid.dead) {
			color.a = cast(ubyte)( baseColor.a - (value-1)*fadeOutSpeed );
			// color.a = cast(ubyte)( baseColor.a / (1+value/fadeOutSpeed) );
			if (value < deadInitialTrail) {
				color.r = cast(ubyte)( cellColor.r - (value+2)*ditFadeOutSpeed*fadeOutSpeed );
			} else {
				color.r = baseColor.r;
			}
			
			sfRectangleShape_setFillColor(rectangle, color);
			sfRectangleShape_setSize(rectangle, sfVector2f(render.scale, render.scale));
			sfRectangleShape_setOrigin(rectangle, sfVector2f(
				render.calculateX(key[0]), 
				render.calculateY(key[1])
			));
			sfRenderWindow_drawRectangleShape(window, rectangle, null);
  	}

		foreach (key, value; grid.alive) {
			sfRectangleShape_setFillColor(rectangle, cellColor);
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
