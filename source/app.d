import std.stdio;
import std.typecons;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

alias Coord = Tuple!(int, int);

int main() {
	bool[Coord] grid;
	// TODO: replace bool with byte?



	int scale = 24;
	int ww = 800;
	int wh = 600;
	int leftOffset, topOffset;
	leftOffset = (ww % scale)/2;
	topOffset = (wh % scale)/2;

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	// TODO: dynamic video mode
	auto mode = sfVideoMode(ww, wh);
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
			auto rectangle = sfRectangleShape_create();
			sfRectangleShape_setFillColor(rectangle, sfWhite);
			sfRectangleShape_setSize(rectangle, sfVector2f(scale, scale));
			sfRectangleShape_setOrigin(rectangle, sfVector2f(
				leftOffset + key[1] * scale - ww/2 - scale/2, 
				topOffset  + key[0] * scale - wh/2 - scale/2
			));
			//writefln("Drawing cell at %d %d", key[0]*scale, key[1]*scale);

			sfRenderWindow_drawRectangleShape(window, rectangle, null);
  	}

		sfRenderWindow_display(window);

		//readln();
	}

	return 0;
}
