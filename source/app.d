module main;

import std.stdio;
import std.getopt;
import std.conv;
import std.string;
import std.file;
import std.json;
import std.typecons;

import core.thread;
import core.sync.mutex;
import core.atomic;

import bindbc.sdl;

import grid;
import renderer;

// Platform-dependent font paths
version (Windows) {
	enum string[] FONT_SEARCH_PATHS = [
		"arial.ttf",
		"C:\\Windows\\Fonts\\arial.ttf",
		"C:\\Windows\\Fonts\\segoeui.ttf",
		"C:\\Windows\\Fonts\\tahoma.ttf"
	];
}
else version (OSX) {
	enum string[] FONT_SEARCH_PATHS = [
		"arial.ttf",
		"/System/Library/Fonts/Helvetica.ttc",
		"/System/Library/Fonts/SFNS.ttf",
		"/Library/Fonts/Arial.ttf",
		"/System/Library/Fonts/Supplemental/Arial.ttf"
	];
}
else version (linux) {
	enum string[] FONT_SEARCH_PATHS = [
		"arial.ttf",
		"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
		"/usr/share/fonts/TTF/DejaVuSans.ttf",
		"/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
		"/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
		"/usr/share/fonts/noto/NotoSans-Regular.ttf",
		"/usr/share/fonts/truetype/freefont/FreeSans.ttf"
	];
}
else {
	enum string[] FONT_SEARCH_PATHS = [
		"arial.ttf"
	];
}

bool loadSDLLibraries() {
	version (Windows) {
		auto sdlRet = loadSDL("SDL2.dll");
		if (sdlRet != sdlSupport) {
			writeln("Failed to load SDL2.dll");
			return false;
		}
		auto ttfRet = loadSDLTTF("SDL2_ttf.dll");
		if (ttfRet != sdlTTFSupport) {
			writeln("Failed to load SDL2_ttf.dll");
			return false;
		}
	}
	else version (OSX) {
		auto sdlRet = loadSDL();
		if (sdlRet != sdlSupport) {
			sdlRet = loadSDL("/Library/Frameworks/SDL2.framework/SDL2");
			if (sdlRet != sdlSupport) {
				writeln("Failed to load SDL2 framework");
				return false;
			}
		}
		auto ttfRet = loadSDLTTF();
		if (ttfRet != sdlTTFSupport) {
			ttfRet = loadSDLTTF("/Library/Frameworks/SDL2_ttf.framework/SDL2_ttf");
			if (ttfRet != sdlTTFSupport) {
				writeln("Failed to load SDL2_ttf framework");
				return false;
			}
		}
	}
	else version (linux) {
		auto sdlRet = loadSDL();
		if (sdlRet != sdlSupport) {
			sdlRet = loadSDL("libSDL2-2.0.so.0");
			if (sdlRet != sdlSupport) {
				sdlRet = loadSDL("libSDL2.so");
				if (sdlRet != sdlSupport) {
					writeln("Failed to load libSDL2");
					return false;
				}
			}
		}
		auto ttfRet = loadSDLTTF();
		if (ttfRet != sdlTTFSupport) {
			ttfRet = loadSDLTTF("libSDL2_ttf-2.0.so.0");
			if (ttfRet != sdlTTFSupport) {
				ttfRet = loadSDLTTF("libSDL2_ttf.so");
				if (ttfRet != sdlTTFSupport) {
					writeln("Failed to load libSDL2_ttf");
					return false;
				}
			}
		}
	}
	else {
		auto sdlRet = loadSDL();
		if (sdlRet != sdlSupport) {
			writeln("Failed to load SDL2");
			return false;
		}
		auto ttfRet = loadSDLTTF();
		if (ttfRet != sdlTTFSupport) {
			writeln("Failed to load SDL2_ttf");
			return false;
		}
	}
	return true;
}

string findFont() {
	foreach (fontPath; FONT_SEARCH_PATHS) {
		if (exists(fontPath)) {
			return fontPath;
		}
	}
	return null;
}

struct Color {
	ubyte r, g, b, a;
}

alias Coord = Tuple!(int, int);

struct GridSnapshot {
	bool[Coord] alive;
	ubyte[Coord] dead;
	uint generation;
}

// Shared state between threads
shared bool computeRunning = true;
shared bool simulationPaused = false;
__gshared Mutex gridMutex;
__gshared GridSnapshot renderSnapshot;
__gshared uint currentGeneration = 0;

void computeThread(GridSparse grid) {
	while (atomicLoad(computeRunning)) {
		if (!atomicLoad(simulationPaused)) {
			grid.iterate();
			
			// Update shared snapshot
			gridMutex.lock();
			scope(exit) gridMutex.unlock();
			
			renderSnapshot.alive = grid.alive.dup;
			renderSnapshot.dead = grid.dead.dup;
			currentGeneration++;
			renderSnapshot.generation = currentGeneration;
		} else {
			// When paused, sleep briefly to avoid busy-waiting
			Thread.sleep(dur!"msecs"(10));
		}
	}
}

int main(string[] args) {
	string rlesrc = "";

	auto helpInformation = getopt(
		args,
		"file|f", "Path to RLE file containing a pattern", &rlesrc,
	);

	if (helpInformation.helpWanted) {
		defaultGetoptPrinter("Some information about the program.",
			helpInformation.options);
		return 0;
	}

	if (!loadSDLLibraries()) {
		writeln("Error: Could not load SDL libraries");
		return 1;
	}

	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		writeln("SDL_Init Error: ", SDL_GetError().fromStringz);
		return 1;
	}
	scope(exit) SDL_Quit();

	if (TTF_Init() != 0) {
		writeln("TTF_Init Error: ", TTF_GetError().fromStringz);
		return 1;
	}
	scope(exit) TTF_Quit();

	// config init

	string configFname;
	if (exists("config.json")) configFname = "config.json";
	else configFname = "config.example.json";

	JSONValue jsonConf;

	if (exists(configFname)) {
		jsonConf = parseJSON(readText(configFname));
	}

	// init defaults

	Color baseColor = Color(
		cast(ubyte)(jsonConf["baseColor"]["r"].integer), 
		cast(ubyte)(jsonConf["baseColor"]["g"].integer), 
		cast(ubyte)(jsonConf["baseColor"]["b"].integer), 
		cast(ubyte)(jsonConf["baseColor"]["a"].integer)
	);

	Color cellColor = Color(
		cast(ubyte)(jsonConf["aliveColor"]["r"].integer), 
		cast(ubyte)(jsonConf["aliveColor"]["g"].integer), 
		cast(ubyte)(jsonConf["aliveColor"]["b"].integer), 
		cast(ubyte)(jsonConf["aliveColor"]["a"].integer)
	);

	const auto fontSize = cast(int)(jsonConf["fontSize"].integer);
	bool showGenInfo = jsonConf["showGenInfo"].boolean;

	const string baseRule = jsonConf["baseRule"].str;
	const auto gridType = to!GridType(jsonConf["gridType"].str);

	const ubyte fadeOutSpeed = cast(ubyte)(jsonConf["fadeOutSpeed"].integer);
	const ubyte ditFadeOutSpeed = cast(ubyte)(jsonConf["ditFadeOutSpeed"].integer);

	const ubyte ditFadeOutSpeedMulti = cast(ubyte)((cellColor.r - baseColor.r) / (ditFadeOutSpeed * 2));
	const ubyte deadMaxColor = cast(ubyte)(baseColor.a / fadeOutSpeed);
	const byte deadInitialTrail = cast(byte)(cellColor.r / (ditFadeOutSpeed * fadeOutSpeed) - 2);

	const uint gridMultiplier = cast(uint)(jsonConf["gridMultiplier"].integer);
	const uint renderMultiplier = cast(uint)(jsonConf["renderMultiplier"].integer);
	const ubyte aspectRatioX = cast(ubyte)(jsonConf["aspectRatioX"].integer);
	const ubyte aspectRatioY = cast(ubyte)(jsonConf["aspectRatioY"].integer);

	int windowWidth = aspectRatioX * renderMultiplier;
	int windowHeight = aspectRatioY * renderMultiplier;
	
	const int gridWidth = aspectRatioX * gridMultiplier;
	const int gridHeight = aspectRatioY * gridMultiplier;

	const bool isFixed = jsonConf["boardFixed"].boolean;

	// load grid from file

	string buf = "";

	if (rlesrc.length && exists(rlesrc)) {
		buf = readText(rlesrc);
	}

	// init grid

	GridSparse grid;

	if (gridType == GridType.sparse) {
		grid = new GridSparse(gridWidth, gridHeight, deadMaxColor, baseRule, isFixed);
	}

	grid.initGrid(buf);

	// Initialize shared state
	gridMutex = new Mutex();
	renderSnapshot.alive = grid.alive.dup;
	renderSnapshot.dead = grid.dead.dup;
	renderSnapshot.generation = 0;

	auto render = Renderer(windowWidth, windowHeight, grid);

	auto window = SDL_CreateWindow(
		"Game of Life experiment",
		SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		render.windowWidth, render.windowHeight,
		SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
	);

	if (!window) {
		writeln("SDL_CreateWindow Error: ", SDL_GetError().fromStringz);
		return 1;
	}
	scope(exit) SDL_DestroyWindow(window);

	auto sdlRenderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
	if (!sdlRenderer) {
		writeln("SDL_CreateRenderer Error: ", SDL_GetError().fromStringz);
		return 1;
	}
	scope(exit) SDL_DestroyRenderer(sdlRenderer);

	SDL_SetRenderDrawBlendMode(sdlRenderer, SDL_BLENDMODE_BLEND);

	string fontPath = findFont();
	TTF_Font* font = null;
	if (fontPath !is null) {
		font = TTF_OpenFont(fontPath.toStringz, fontSize);
		if (!font) {
			writeln("Warning: Could not load font from ", fontPath, ": ", TTF_GetError().fromStringz);
		}
	} else {
		writeln("Warning: No font found in search paths");
	}
	scope(exit) if (font) TTF_CloseFont(font);

	// Start computation thread
	auto compThread = new Thread(() => computeThread(grid));
	compThread.start();
	scope(exit) {
		atomicStore(computeRunning, false);
		compThread.join();
	}

	bool running = true;
	SDL_Event event;

	// Local copy for rendering
	bool[Coord] localAlive;
	ubyte[Coord] localDead;
	uint localGen = 0;

	while (running) {
		// Event handling
		while (SDL_PollEvent(&event) != 0) {
			if (event.type == SDL_QUIT) {
				running = false;
			}
			else if (event.type == SDL_WINDOWEVENT) {
				if (event.window.event == SDL_WINDOWEVENT_RESIZED) {
					render.windowWidth = event.window.data1;
					render.windowHeight = event.window.data2;
					render.recalculateScale();
				}
			}
			else if (event.type == SDL_KEYUP) {
				if (event.key.keysym.sym == SDLK_F2) {
					showGenInfo = !showGenInfo;
				}
				else if (event.key.keysym.sym == SDLK_SPACE) {
					// Toggle pause
					bool currentPause = atomicLoad(simulationPaused);
					atomicStore(simulationPaused, !currentPause);
				}
			}
		}

		// Key presses
		auto keyState = SDL_GetKeyboardState(null);

		if (keyState[SDL_SCANCODE_LEFT] || keyState[SDL_SCANCODE_A]) {
			render.shiftViewportPosX(-1);
		}
		if (keyState[SDL_SCANCODE_RIGHT] || keyState[SDL_SCANCODE_D]) {
			render.shiftViewportPosX(1);
		}
		if (keyState[SDL_SCANCODE_UP] || keyState[SDL_SCANCODE_W]) {
			render.shiftViewportPosY(-1);
		}
		if (keyState[SDL_SCANCODE_DOWN] || keyState[SDL_SCANCODE_S]) {
			render.shiftViewportPosY(1);
		}

		if (keyState[SDL_SCANCODE_KP_PLUS] || keyState[SDL_SCANCODE_EQUALS]) {
			render.shiftScale(1);
		}
		if (keyState[SDL_SCANCODE_MINUS] || keyState[SDL_SCANCODE_KP_MINUS]) {
			render.shiftScale(-1);
		}
		if (keyState[SDL_SCANCODE_DELETE] || keyState[SDL_SCANCODE_BACKSPACE]) {
			render.recalculateScale();
		}
		if (keyState[SDL_SCANCODE_HOME] || keyState[SDL_SCANCODE_RETURN]) {
			render.setViewportPos(0, 0);
		}

		// Get snapshot of grid state (minimize lock time)
		{
			gridMutex.lock();
			scope(exit) gridMutex.unlock();
			localAlive = renderSnapshot.alive.dup;
			localDead = renderSnapshot.dead.dup;
			localGen = renderSnapshot.generation;
		}

		// Clear screen
		SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 255);
		SDL_RenderClear(sdlRenderer);

		// Drawing cells
		int wx, wy;
		SDL_Rect rect;
		rect.w = render.scale;
		rect.h = render.scale;

		// Draw dead cells
		foreach (key, value; localDead) {
			ubyte alpha = cast(ubyte)(baseColor.a - (value - 1) * fadeOutSpeed);
			ubyte r;
			if (value < deadInitialTrail) {
				r = cast(ubyte)(cellColor.r - (value - 1) * 2 * ditFadeOutSpeedMulti);
			} else {
				r = baseColor.r;
			}
			
			wx = render.calculateX(key[0]);
			wy = render.calculateY(key[1]);
			
			if (wx <= 0 + render.scale && wx >= -render.windowWidth - render.scale && 
				wy <= 0 + render.scale && wy >= -render.windowHeight - render.scale) {
				rect.x = -wx;
				rect.y = -wy;
				SDL_SetRenderDrawColor(sdlRenderer, r, baseColor.g, baseColor.b, alpha);
				SDL_RenderFillRect(sdlRenderer, &rect);
			}
		}

		// Draw alive cells
		SDL_SetRenderDrawColor(sdlRenderer, cellColor.r, cellColor.g, cellColor.b, cellColor.a);
		foreach (key, value; localAlive) {
			wx = render.calculateX(key[0]);
			wy = render.calculateY(key[1]);
			
			if (wx <= 0 + render.scale && wx >= -render.windowWidth - render.scale && 
				wy <= 0 + render.scale && wy >= -render.windowHeight - render.scale) {
				rect.x = -wx;
				rect.y = -wy;
				SDL_RenderFillRect(sdlRenderer, &rect);
			}
		}

		// Display info
		if (showGenInfo && font) {
			bool isPaused = atomicLoad(simulationPaused);
			string infoText = format("Generation %d\nscale: %d%s", localGen, render.scale, 
				isPaused ? "\n[PAUSED]" : "");
			
			SDL_Color textColor = {255, 255, 255, 255};
			auto lines = infoText.split("\n");
			int yPos = 10;
			int maxWidth = 0;
			int totalHeight = 0;
			
			foreach (line; lines) {
				int w, h;
				TTF_SizeText(font, line.toStringz, &w, &h);
				if (w > maxWidth) maxWidth = w;
				totalHeight += h;
			}
			
			SDL_Rect bgRect = {0, 0, maxWidth + 20, totalHeight + 20};
			SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 164);
			SDL_RenderFillRect(sdlRenderer, &bgRect);
			
			foreach (line; lines) {
				auto surface = TTF_RenderText_Blended(font, line.toStringz, textColor);
				if (surface) {
					auto texture = SDL_CreateTextureFromSurface(sdlRenderer, surface);
					if (texture) {
						SDL_Rect dstRect = {10, yPos, surface.w, surface.h};
						SDL_RenderCopy(sdlRenderer, texture, null, &dstRect);
						SDL_DestroyTexture(texture);
					}
					yPos += surface.h;
					SDL_FreeSurface(surface);
				}
			}
		}

		SDL_RenderPresent(sdlRenderer);
	}

	return 0;
}
