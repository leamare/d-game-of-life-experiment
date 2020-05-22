module grid;

import std.typecons;
import std.algorithm;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int gridWidth, gridHeight;

  bool[Coord] alive;
  byte[Coord] dead;

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
