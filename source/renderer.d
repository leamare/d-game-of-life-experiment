module renderer;

import grid;
import std.algorithm;

struct Renderer {
  int windowWidth, windowHeight;
  int leftOffset, topOffset;
  int scale;
  GridStruct grid;

  this(int ww, int wh, GridStruct* grid) {
    this.windowHeight = wh;
    this.windowWidth = ww;
    this.grid = *grid;

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

  int calculateX(int coord) {
    return coord * this.scale - this.windowWidth/2 + this.scale/2;
  }

  int calculateY(int coord) {
    return coord * this.scale - this.windowHeight/2 + this.scale/2;
  }
}