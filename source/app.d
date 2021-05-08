module main;

import std.stdio;
import std.getopt;
import std.conv;
import std.string;
import std.file;
import std.json;

import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.sfml2.graphics;

import grid;
import renderer;

int main(string[] args) {
	string rlesrc = "";

	// args

	auto helpInformation = getopt(
    args,
    "file|f", "Path to RLE file containing a pattern", &rlesrc,
  );

	if (helpInformation.helpWanted)
  {
    defaultGetoptPrinter("Some information about the program.",
      helpInformation.options);
		return 0;
  }

	// config init

	string configFname;
	if (exists("config.json")) configFname = "config.json";
	else configFname = "config.example.json";

	JSONValue jsonConf;

	if (exists(configFname)) {
		jsonConf = parseJSON(readText(configFname));
	}
	

	// TODO: there may be a version of default config

	// init defaults

	const auto baseColor = sfColor(
		cast(byte)(jsonConf["baseColor"]["r"].integer), 
		cast(byte)(jsonConf["baseColor"]["g"].integer), 
		cast(byte)(jsonConf["baseColor"]["b"].integer), 
		cast(byte)(jsonConf["baseColor"]["a"].integer)
	);

	const auto cellColor = sfColor(
		cast(byte)(jsonConf["aliveColor"]["r"].integer), 
		cast(byte)(jsonConf["aliveColor"]["g"].integer), 
		cast(byte)(jsonConf["aliveColor"]["b"].integer), 
		cast(byte)(jsonConf["aliveColor"]["a"].integer)
	);

	const auto fontSize = jsonConf["fontSize"].integer;
	bool showGenInfo = jsonConf["showGenInfo"].boolean;
	bool showHelp = false;

	const string baseRule = jsonConf["baseRule"].str;

	const ubyte fadeOutSpeed = cast(byte)(jsonConf["fadeOutSpeed"].integer);
	const ubyte ditFadeOutSpeed = cast(byte)(jsonConf["ditFadeOutSpeed"].integer);

	const ubyte ditFadeOutSpeedMulti = cast(byte)((cellColor.r-baseColor.r) / (ditFadeOutSpeed*2));
	const ubyte deadMaxColor = baseColor.a / fadeOutSpeed;
	const byte deadInitialTrail = cast(byte)(cellColor.r / (ditFadeOutSpeed*fadeOutSpeed) - 2);

	const uint gridMultiplier = cast(uint)(jsonConf["gridMultiplier"].integer);
	const uint renderMultiplier = cast(uint)(jsonConf["renderMultiplier"].integer);
	const ubyte aspectRatioX = cast(byte)(jsonConf["aspectRatioX"].integer);
	const ubyte aspectRatioY = cast(byte)(jsonConf["aspectRatioY"].integer);

	const int windowWidth = aspectRatioX * renderMultiplier;
	const int windowHeight = aspectRatioY * renderMultiplier;
	
	const int gridWidth = aspectRatioX * gridMultiplier;
	const int gridHeight = aspectRatioY * gridMultiplier;

	const bool isFixed = cast(bool)(jsonConf["boardFixed"].boolean);

	// load grid from file

	string buf = "";

	if (rlesrc.length && exists(rlesrc)) {
		buf = readText(rlesrc);
	}

	// init grid

	uint gen = 0;

	auto grid = GridStruct(gridWidth, gridHeight, deadMaxColor, baseRule, isFixed);

	grid.initGrid(buf);

	auto render = Renderer(windowWidth, windowHeight, &grid);

	DerelictSFML2Graphics.load("libs\\csfml-graphics-2.dll");
	DerelictSFML2Graphics.load("libs\\csfml-system-2.dll");
	DerelictSFML2Window.load("libs\\csfml-window-2.dll");

	auto defFont = sfFont_createFromFile("C:\\windows\\fonts\\arial.ttf");

	auto mode = sfVideoMode(render.windowWidth, render.windowHeight);
	auto window = sfRenderWindow_create(mode, "Game of Life experiment", sfResize | sfClose, null);

	if (!window)
    return 1;

	auto GenNum = sfText_create();
	sfText_setFont(GenNum, defFont);
	sfText_setPosition(GenNum, sfVector2f(10, 10));
	sfText_setCharacterSize(GenNum, cast(int) fontSize);
	sfText_setColor(GenNum, sfWhite);
	sfText_setStyle(GenNum, sfTextBold);

	auto infoBlockBg = sfRectangleShape_create();
	auto textContainer = sfText_getGlobalBounds(GenNum);
	sfRectangleShape_setFillColor(infoBlockBg, sfColor(0, 0, 0, 164));
	sfRectangleShape_setOrigin(infoBlockBg, sfVector2f(0, 0));

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

		// key presses

		if (sfKeyboard_isKeyPressed(sfKeyLeft) || sfKeyboard_isKeyPressed(sfKeyA)) {
			render.shiftViewportPosX(-1);
		}
		if (sfKeyboard_isKeyPressed(sfKeyRight) || sfKeyboard_isKeyPressed(sfKeyD)) {
			render.shiftViewportPosX(1);
		}
		if (sfKeyboard_isKeyPressed(sfKeyUp) || sfKeyboard_isKeyPressed(sfKeyW)) {
			render.shiftViewportPosY(-1);
		}
		if (sfKeyboard_isKeyPressed(sfKeyDown) || sfKeyboard_isKeyPressed(sfKeyS)) {
			render.shiftViewportPosY(1);
		}

		if (sfKeyboard_isKeyPressed(sfKeyAdd) || sfKeyboard_isKeyPressed(sfKeyEqual)) {
			render.shiftScale(1);
		}
		if (sfKeyboard_isKeyPressed(sfKeyDash) || sfKeyboard_isKeyPressed(sfKeySubtract)) {
			render.shiftScale(-1);
		}
		if (sfKeyboard_isKeyPressed(sfKeyDelete) || sfKeyboard_isKeyPressed(sfKeyBack)) {
			render.recalculateScale();
		}
		if (sfKeyboard_isKeyPressed(sfKeyHome) || sfKeyboard_isKeyPressed(sfKeyReturn)) {
			render.setViewportPos(0, 0);
		}
		if (event.key.type == sfEvtKeyReleased && event.key.code == sfKeyF2) {
			showGenInfo = !showGenInfo;
			event.key.code = 0;
		}

		
		grid.iterate();

		gen++;

		// Drawing cells

		auto color = sfColor(baseColor.r, baseColor.g, baseColor.b, 0);
		int wx, wy;
		sfRectangleShape_setSize(rectangle, sfVector2f(render.scale, render.scale));

		foreach (key, value; grid.dead) {
			color.a = cast(ubyte)( baseColor.a - (value-1)*fadeOutSpeed );
			// color.a = cast(ubyte)( baseColor.a / (1+value/fadeOutSpeed) );
			if (value < deadInitialTrail) {
				color.r = cast(ubyte)( cellColor.r - (value-1)*2*ditFadeOutSpeedMulti);
			} else {
				color.r = baseColor.r;
			}
			sfRectangleShape_setFillColor(rectangle, color);
			
			wx = render.calculateX(key[0]);
			wy = render.calculateY(key[1]);
			if (wx <= 0+render.scale && wx >= -render.windowWidth-render.scale && 
				wy <= 0+render.scale && wy >= -render.windowHeight-render.scale) {
				sfRectangleShape_setOrigin(rectangle, sfVector2f(
					wx, 
					wy
				));
				sfRenderWindow_drawRectangleShape(window, rectangle, null);
			}
  	}

		sfRectangleShape_setFillColor(rectangle, cellColor);
		foreach (key, value; grid.alive) {
			wx = render.calculateX(key[0]);
			wy = render.calculateY(key[1]);
			
			if (wx <= 0+render.scale && wx >= -render.windowWidth-render.scale && 
				wy <= 0+render.scale && wy >= -render.windowHeight-render.scale) {
				sfRectangleShape_setOrigin(rectangle, sfVector2f(
					wx, 
					wy
				));
				sfRenderWindow_drawRectangleShape(window, rectangle, null);
			}
		}

		// displaying info

		if (showGenInfo) {
			sfText_setString(GenNum, std.string.toStringz(format("Generation %d\nscale: %d", gen, render.scale)));
			textContainer = sfText_getGlobalBounds(GenNum);
			sfRectangleShape_setSize(infoBlockBg, sfVector2f(textContainer.width + 20, textContainer.height + 30));

			sfRenderWindow_drawRectangleShape(window, infoBlockBg, null);
			sfRenderWindow_drawText(window, GenNum, null);
		}

		sfRenderWindow_display(window);
	}

	return 0;
}
