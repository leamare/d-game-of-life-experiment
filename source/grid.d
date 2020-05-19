module grid;

import std.typecons;
import std.algorithm;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int windowWidth, windowHeight, gridWidth, gridHeight;
  int leftOffset, topOffset;
  int scale;

  bool[Coord] alive;
  byte[Coord] dead;

  void recalculateScale() {
    if (this.windowWidth < this.gridWidth || this.windowHeight < this.gridHeight) {
      this.scale = 1;
    } else {
      this.scale = min(this.windowWidth/this.gridWidth, this.windowHeight/this.gridHeight);
    }
    
		this.leftOffset = (this.windowWidth % this.scale)/2;
		this.topOffset = (this.windowHeight % this.scale)/2;
	}

  void generateGrid() {
    this.alive[tuple(5,-5)] = true;
    this.alive[tuple(4,-5)] = true;
    this.alive[tuple(4,-4)] = true;
    this.alive[tuple(4,-3)] = true;
    this.alive[tuple(4,-2)] = true;
    this.alive[tuple(4,-1)] = true;
    this.alive[tuple(3,-1)] = true;

    this.alive[tuple(5, 5)] = true;
    this.alive[tuple(4, 5)] = true;
    this.alive[tuple(4, 4)] = true;
    this.alive[tuple(4, 3)] = true;
    this.alive[tuple(4, 2)] = true;
    this.alive[tuple(4, 1)] = true;
    this.alive[tuple(3, 1)] = true;

    this.alive[tuple(2,-2)] = true;
    this.alive[tuple(2,-1)] = true;
    this.alive[tuple(2,-0)] = true;
    this.alive[tuple(2, 1)] = true;
    this.alive[tuple(2, 2)] = true;

    this.alive[tuple(1,-2)] = true;
    this.alive[tuple(1, 2)] = true;

    this.alive[tuple(0, -5)] = true;
    this.alive[tuple(0, -4)] = true;
    this.alive[tuple(0, -3)] = true;
    this.alive[tuple(0, -2)] = true;

    this.alive[tuple(0, 0)] = true;

    this.alive[tuple(0, 2)] = true;
    this.alive[tuple(0, 3)] = true;
    this.alive[tuple(0, 4)] = true;
    this.alive[tuple(0, 5)] = true;

    this.alive[tuple(-1,-2)] = true;
    this.alive[tuple(-1, 2)] = true;

    this.alive[tuple(-2,-2)] = true;
    this.alive[tuple(-2,-1)] = true;
    this.alive[tuple(-2, 1)] = true;
    this.alive[tuple(-2, 2)] = true;

    this.alive[tuple(-5,-5)] = true;
    this.alive[tuple(-4,-5)] = true;
    this.alive[tuple(-4,-4)] = true;
    this.alive[tuple(-4,-3)] = true;
    this.alive[tuple(-4,-2)] = true;
    this.alive[tuple(-4,-1)] = true;
    this.alive[tuple(-3,-1)] = true;

    this.alive[tuple(-5, 5)] = true;
    this.alive[tuple(-4, 5)] = true;
    this.alive[tuple(-4, 4)] = true;
    this.alive[tuple(-4, 3)] = true;
    this.alive[tuple(-4, 2)] = true;
    this.alive[tuple(-4, 1)] = true;
    this.alive[tuple(-3, 1)] = true;
  }

  this(int ww, int wh, int gw, int gh) {
    this.windowHeight = wh;
    this.windowWidth = ww;
    this.gridHeight = gh;
    this.gridWidth = gw;

    this.recalculateScale();
    this.generateGrid();
  }

  int calculateX(int coord) {
    return coord * this.scale - this.windowWidth/2 + this.scale/2;
  }

  int calculateY(int coord) {
    return coord * this.scale - this.windowHeight/2 + this.scale/2;
  }

  void iterate() {}
}
