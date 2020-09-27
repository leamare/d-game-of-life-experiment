module renderer;

import grid;
import std.algorithm;

struct Renderer {
  int windowWidth, windowHeight;
  int leftOffset, topOffset;
  int viewX, viewY;
  int scale;
  GridStruct grid;

  this(int ww, int wh, GridStruct* grid) {
    this.windowHeight = wh;
    this.windowWidth = ww;
    this.grid = *grid;
    this.viewX = 0;
    this.viewY = 0;

    this.recalculateScale();
  }

  void recalculateScale() {
    if (this.windowWidth < this.grid.gridWidth || this.windowHeight < this.grid.gridHeight) {
      this.scale = 1;
    } else {
      this.scale = min(this.windowWidth/this.grid.gridWidth, this.windowHeight/this.grid.gridHeight);
    }
    
		this.leftOffset = (this.windowWidth % this.scale)/2;
		this.topOffset = (this.windowHeight % this.scale)/2;
	}

  void setViewportPos(int x, int y) {
    this.viewX = x;
    this.viewY = y;
  }

  void shiftViewportPos(int x, int y) {
    this.viewX += x;
    this.viewY += y;
  }

  int calculateX(int coord) {
    return (coord + this.viewX) * this.scale - this.windowWidth/2 + this.scale/2;
  }

  int calculateY(int coord) {
    return (coord + this.viewY) * this.scale - this.windowHeight/2 + this.scale/2;
  }
}