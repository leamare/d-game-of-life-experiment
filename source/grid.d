module grid;

import std.typecons;
import std.algorithm;
import std.random;

import std.stdio;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int gridWidth, gridHeight;
  ubyte deadMaxColor;

  bool[Coord] alive;
  ubyte[Coord] dead;

  void initGrid() {
    // TODO: multiple ways to init grid
  }

  void generateGrid() {
    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    auto key = tuple(0,0);
    for (int i = -halfWidth; i < halfWidth; i++) {
      for (int j = -halfHeight; j < halfHeight; j++) {
        const auto nv = uniform(0, 10);
        if (nv > 7) { // a workaround to get a better looking result
          // uniform 0,1 always returns 0 and unform 0,2 is too cluttered
          // but getting uniform 0,10 and setting true when the value
          // is in the upper half will do the trick
          key[0] = i;
          key[1] = j;
          this.alive[key] = true;
        }
      }
    }
  }

  void iterate() {
    bool[Coord] updated;
    int i, j, inb, jnb;

    foreach (key, value; this.dead) {
      if (value < this.deadMaxColor)
			  this.dead[key]++;
      else
        this.dead.remove(key);
  	}

    auto keyNb = tuple(0,0);
    auto key = tuple(0,0);

    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    for (i = -halfWidth; i < halfWidth; i++) {
      for (j = -halfHeight; j < halfHeight; j++) {
        short nb = 0;
        for (inb = i-1; inb <= i+1; inb++) {
          for (jnb = j-1; jnb <= j+1; jnb++) {
            if (i == inb && j == jnb) continue;
            keyNb[0] = inb;
            keyNb[1] = jnb;
            // if (i < -halfWidth || i > halfWidth) continue;
            // if (j < -halfHeight || j > halfHeight) continue;
            if (keyNb in this.alive && this.alive[keyNb])
              nb++;
          }
        }

        key[0] = i;
        key[1] = j;
        if (key in this.alive && this.alive[key]) {
          if (nb == 2 || nb == 3) {
            updated[key] = true;
          } else {
            this.dead[key] = 1;
          }
        } else {
          if (nb == 3) {
            updated[key] = true;
            if (key in this.dead)
              this.dead.remove(key);
          }
        }
      }
    }

    for (i = -halfWidth; i < halfWidth; i++) {
      for (j = -halfHeight; j < halfHeight; j++) {
        key[0] = i;
        key[1] = j;
        
        if (key in this.alive && this.alive[key]) {
          this.alive.remove(key);
        }

        if (key in updated && updated[key]) {
          this.alive[key] = updated[key];
        }
      }
    }
  }

  this(int gw, int gh, ubyte deadMaxColor) {
    this.gridHeight = gh;
    this.gridWidth = gw;
    this.deadMaxColor = deadMaxColor;

    this.generateGrid();
  }
}
