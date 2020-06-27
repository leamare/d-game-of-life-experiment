module grid;

import std.typecons;
import std.algorithm;
import std.random;

import std.stdio;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int gridWidth, gridHeight;

  bool[Coord] alive;
  ubyte[Coord] dead;

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

  void iterate() {
    bool[Coord] updated;

    foreach (key, value; this.dead) {
      if (value < 64)
			  this.dead[key]++;
  	}

    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    for (int i = -halfWidth; i < halfWidth; i++) {
      for (int j = -halfHeight; j < halfHeight; j++) {
        short nb = 0;
        for (int inb = i-1; inb <= i+1; inb++) {
          for (int jnb = j-1; jnb <= j+1; jnb++) {
            if (i == inb && j == jnb) continue;
            // if (i < -halfWidth || i > halfWidth) continue;
            // if (j < -halfHeight || j > halfHeight) continue;
            if (tuple(inb,jnb) in this.alive && this.alive[tuple(inb,jnb)])
              nb++;
          }
        }
        if (tuple(i,j) in this.alive && this.alive[tuple(i,j)]) {
          if (nb == 2 || nb == 3) {
            updated[tuple(i,j)] = true;
          } else {
            this.dead[tuple(i,j)] = 1;
          }
        } else {
          if (nb == 3) {
            updated[tuple(i,j)] = true;
            if (tuple(i,j) in this.dead)
              this.dead.remove(tuple(i,j));
          }
        }
      }
    }

    this.alive = updated;
  }

  this(int gw, int gh) {
    this.gridHeight = gh;
    this.gridWidth = gw;

    this.generateGrid();
  }
}
