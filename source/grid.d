module grid;

import std.typecons;
import std.algorithm;
import std.random;

import std.stdio;
import std.conv;
import std.string;
import core.stdc.string : strlen;

alias Coord = Tuple!(int, int);

struct GridStruct {
  int gridWidth, gridHeight;
  ubyte deadMaxColor;

  bool[Coord] alive;
  ubyte[Coord] dead;

  void initGrid(char[] buf) {
    auto const sz = strlen(buf.ptr);
    if (sz) {
      generateRLEGrid(buf);
    } else {
      generateRandomGrid();
    }
  }

  void generateRandomGrid() {
    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    auto key = tuple(0,0);
    for (int i = -halfWidth; i < halfWidth; i++) {
      for (int j = -halfHeight; j < halfHeight; j++) {
        const auto nv = uniform(0, 20);
        if (nv > 16) { // a workaround to get a better looking result
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

  void generateRLEGrid(char[] buf) {
    auto const sz = strlen(buf.ptr);

    int halfWidth = this.gridWidth/2;
    int halfHeight = this.gridHeight/2;

    bool skipline = false;
    bool firstline = true;
    bool varlock = false;
    bool varassign = false;
    
    string assignVar = "";
    string assignVal = "";

    string[string] vars;
    int x, y;

    int cnt = 0;
    int xOffset, yOffset;
    int gridX = 0; int gridY = 0;
    auto key = tuple(0,0);

    for(int i = 0; i < sz; i++) {
      if (buf[i] == '#') {
        skipline = true;
        continue;
      }
      if (buf[i] == '\n' && (!firstline || skipline)) {
        if (!skipline && firstline) firstline = false;
        skipline = false;
        continue;
      }
      if (skipline) {
        continue;
      }
      if (firstline) {
        if (buf[i] == ' ' && !varlock) {
          if (strlen(assignVar.ptr)) {
            varlock = true;
            continue;
          } else {
            continue;
          }
        } else if (buf[i] == '=' && varlock) {
          varassign = true;
          continue;
        } else if (!varlock) {
          assignVar = assignVar ~ buf[i];
        }

        if (varassign) {
          if (buf[i] == ' ') {
            continue;
          } else if (buf[i] == ',' || buf[i] == '\n') {
            vars[assignVar] = assignVal;

            if (assignVar == "x") x = parse!int(assignVal);
            if (assignVar == "y") y = parse!int(assignVal);

            assignVal = "";
            assignVar = "";
            varassign = false;
            varlock = false;
          } else {
            assignVal = assignVal ~ buf[i];
          }
        }

        if (buf[i] == '\n') {
          firstline = false;

          if (this.gridHeight < y) {
            this.gridHeight = y;
            halfHeight = this.gridHeight/2;
          }
          yOffset = y/2;

          if (this.gridWidth < x) {
            this.gridWidth = x;
            halfWidth = this.gridWidth/2;
          }
          xOffset = x/2;

          assignVal = "";

          foreach (k, value; vars) {
            writeln(k ~ " = " ~ value);
          }
        }
      } else {
        if (buf[i] == 'b' || buf[i] == 'o' || buf[i] == '$') {
          if (empty(assignVal)) {
            cnt = 1;
          } else {
            cnt = parse!int(assignVal);
          }

          if (buf[i] == 'b') {
            gridX += cnt;
          } else if (buf[i] == 'o') {
            for (int j = 0; j < cnt; j++) {
              key[0] = gridX - xOffset;
              key[1] = gridY - yOffset;
              this.alive[key] = true;

              gridX++;
            }
          } else {
            gridY++;
            gridX = 0;
          }
          
          assignVal = "";
        } else if (buf[i] != '\n' && buf[i] != '\r') {
          assignVal = assignVal ~ buf[i];
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
    // auto key = tuple(0,0);

    // TODO: C1 - find potential cells, make them false by default

    int limitX, limitY;

    foreach (k, value; this.alive) {
      for (inb = k[0]-1, limitX = k[0]+1; inb <= limitX; inb++) {
        for (jnb = k[1]-1, limitY = k[1]+1; jnb <= limitY; jnb++) {
          keyNb[0] = inb;
          keyNb[1] = jnb;
          updated[keyNb] = false;
        }
      }
  	}

    // TODO: C2 - calculate for all the potential cells, if died - assign dead
    short nb = 0;

    foreach (k, value; updated) {
      nb = 0;

      for (inb = k[0]-1, limitX = k[0]+1; inb <= limitX; inb++) {
        for (jnb = k[1]-1, limitY = k[1]+1; jnb <= limitY; jnb++) {
          if (k[0] == inb && k[1] == jnb) continue;

          keyNb[0] = inb;
          keyNb[1] = jnb;

          if (keyNb in this.alive && this.alive[keyNb])
            nb++;
        }
      }
      
      if (k in this.alive && this.alive[k]) {
        if (nb == 2 || nb == 3) {
          updated[k] = true;
        } else {
          updated.remove(k);
          this.dead[k] = 1;
        }
      } else {
        if (nb == 3) {
          updated[k] = true;
          if (k in this.dead)
            this.dead.remove(k);
        } else {
          updated.remove(k);
        }
      }
  	}

    // TODO: C3 - run over the new grid, remove bad cells

    // foreach (key, value; this.alive) {
    //   this.alive.remove(key);
  	// }

    // foreach (key, value; updated) {
    //   this.alive[key] = value;
  	// }

    this.alive = updated;

    // for (i = -halfWidth; i < halfWidth; i++) {
    //   for (j = -halfHeight; j < halfHeight; j++) {
    //     key[0] = i;
    //     key[1] = j;
        
    //     if (key in this.alive && this.alive[key]) {
    //       this.alive.remove(key);
    //     }

    //     if (key in updated && updated[key]) {
    //       this.alive[key] = updated[key];
    //     }
    //   }
    // }
  }

  this(int gw, int gh, ubyte deadMaxColor) {
    this.gridHeight = gh;
    this.gridWidth = gw;
    this.deadMaxColor = deadMaxColor;

    //this.generateRandomGrid();
    //this.initGrid();
  }
}
