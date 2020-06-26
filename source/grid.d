module grid;

import std.typecons;
import std.algorithm;
import std.random;

import std.stdio;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int gridWidth, gridHeight;

  bool[Coord] alive;
  byte[Coord] dead;

  void initGrid() {
    // TODO: multiple ways to init grid
  }

  void generateGrid() {
    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    for (int i = -halfWidth; i < halfWidth; i++) {
      for (int j = -halfHeight; j < halfHeight; j++) {
        const auto nv = uniform(0, 10);
        if (nv > 6) { // a workaround to get a better looking result
          // uniform 0,1 always returns 0 and unform 0,2 is too cluttered
          // but getting uniform 0,10 and setting true when the value
          // is in the upper half will do the trick
          this.alive[tuple(i,j)] = true;
        }
      }
    }
  }

  this(int gw, int gh) {
    this.gridHeight = gh;
    this.gridWidth = gw;

    this.generateGrid();
  }

  void iterate() {
    this.alive[tuple(5,-9)] = true;
    this.alive[tuple(4,-9)] = true;
    this.alive[tuple(4,-9)] = true;
    this.alive[tuple(4,-9)] = true;
    this.alive[tuple(4,-9)] = true;
    this.alive[tuple(4,-9)] = true;
    this.alive[tuple(3,-9)] = true;
  }
}
