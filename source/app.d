import std.stdio;
import std.typecons;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

alias Coord = Tuple!(int, int);

int main() {
	bool[Coord] grid;
	// TODO: replace bool with byte?


	// FIXME: test grid
	grid[tuple(2,2)] = true;
	grid[tuple(-3,2)] = true;
	grid[tuple(0,1)] = true;
	grid[tuple(1,0)] = true;
	grid[tuple(-1,0)] = true;
	grid[tuple(-1,-1)] = true;
	grid[tuple(-1,1)] = true;

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	// TODO: dynamic video mode
	auto mode = sfVideoMode(800, 600, 32);
	auto window = sfRenderWindow_create(mode, "Game of Life experiment", sfResize | sfClose, null);
	if (!window)
    return 1;
	
	sfEvent event;

	while (sfRenderWindow_isOpen(window)) {
		// TODO: game of life algo
		sfRenderWindow_clear(window, sfBlack);

		while (sfRenderWindow_pollEvent(window, &event)) {
			if (event.type == sfEvtClosed)
				sfRenderWindow_close(window);
		}


		// FIXME: drawing cells
		foreach (key, value; grid) {
			//writefln("Drawing cell %d %d", key[0], key[1]);
			auto rectangle = sfRectangleShape_create();
			sfRectangleShape_setFillColor(rectangle, sfWhite);
			sfRectangleShape_setSize(rectangle, sfVector2f(1,1));
			sfRectangleShape_setOrigin(rectangle, sfVector2f(key[0]-400,key[1]-300));

			sfRenderWindow_drawRectangleShape(window, rectangle, null);
  	}

		sfRenderWindow_display(window);
	}

	return 0;
}
