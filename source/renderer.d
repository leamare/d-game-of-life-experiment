module renderer;

import grid;
import std.algorithm;
import std.math;

import std.stdio;

struct Renderer {
	int windowWidth, windowHeight;
	int leftOffset, topOffset;
	int viewX, viewY;
	int scale;
	GridStruct grid;

	this(int ww, int wh, GridStruct grid) {
		this.windowHeight = wh;
		this.windowWidth = ww;
		this.grid = grid;
		this.viewX = 0;
		this.viewY = 0;
		
		this.recalculateScale();
	}

	void recalculateScale() {
		writeln(this.grid);
		auto gw = this.grid.getWidth();
		auto gh = this.grid.getHeight();

		if (this.windowWidth < gw || this.windowHeight < gh) {
			// Need to zoom out - use negative scale
			int cellsPerPixelX = (gw + this.windowWidth - 1) / this.windowWidth;
			int cellsPerPixelY = (gh + this.windowHeight - 1) / this.windowHeight;
			int cellsPerPixel = max(cellsPerPixelX, cellsPerPixelY);
			this.scale = -cellsPerPixel;
		} else {
			this.scale = min(this.windowWidth / gw, this.windowHeight / gh);
			if (this.scale < 1) this.scale = 1;
		}
		
		this.recalculateOffsets();
	}

	void recalculateOffsets() {
		int pixelSize = this.getPixelSize();
		this.leftOffset = (this.windowWidth % pixelSize) / 2;
		this.topOffset = (this.windowHeight % pixelSize) / 2;
	}

	void setViewportPos(int x, int y) {
		this.viewX = x;
		this.viewY = y;
	}

	void shiftViewportPosX(int x) {
		this.viewX += x;
	}

	void shiftViewportPosY(int y) {
		this.viewY += y;
	}

	void shiftViewportPos(int x, int y) {
		this.shiftViewportPosX(x);
		this.shiftViewportPosY(y);
	}

	void shiftScale(int mod) {
		int newScale = this.scale + mod;
		// Skip 0 and -1
		if (this.scale > 0 && newScale <= 0) {
			this.scale = -2;
		} else if (this.scale < 0 && newScale >= 0) {
			this.scale = 1;
		} else if (newScale == -1) {
			this.scale = mod > 0 ? 1 : -2;
		} else {
			this.scale = newScale;
		}
		this.recalculateOffsets();
	}

	void setScale(int val) {
		if (val == 0) val = 1;
		this.scale = val;
		this.recalculateOffsets();
	}

	int getPixelSize() {
		return this.scale > 0 ? this.scale : 1;
	}

	int getCellsPerPixel() {
		return this.scale > 0 ? 1 : -this.scale;
	}
	int calculateX(int coord) {
		if (this.scale > 0) {
			return (coord - this.viewX) * this.scale + this.windowWidth / 2 - this.scale / 2;
		} else {
			int cellsPerPixel = -this.scale;
			int groupX = cast(int)floor(cast(float)(coord - this.viewX) / cellsPerPixel);
			return groupX + this.windowWidth / 2;
		}
	}

	int calculateY(int coord) {
		if (this.scale > 0) {
			return (coord - this.viewY) * this.scale + this.windowHeight / 2 - this.scale / 2;
		} else {
			int cellsPerPixel = -this.scale;
			int groupY = cast(int)floor(cast(float)(coord - this.viewY) / cellsPerPixel);
			return groupY + this.windowHeight / 2;
		}
	}

	int getCellGroupX(int cellX) {
		if (this.scale > 0) return cellX;
		int cellsPerPixel = -this.scale;
		return cast(int)floor(cast(float)(cellX - this.viewX) / cellsPerPixel);
	}

	int getCellGroupY(int cellY) {
		if (this.scale > 0) return cellY;
		int cellsPerPixel = -this.scale;
		return cast(int)floor(cast(float)(cellY - this.viewY) / cellsPerPixel);
	}

	string getScaleString() {
		import std.format;
		if (this.scale > 0) {
			return format("%d:1", this.scale);
		} else {
			return format("1:%d", -this.scale);
		}
	}
}
