module grid.sparse;

import grid.gridinterface;

import std.typecons;
import std.algorithm;
import std.random;

import std.stdio;
import std.conv;
import std.string;
import core.stdc.string : strlen;

// import std.parallelism;
// import std.atomic;

class GridSparse : GridStruct {
  int gridWidth, gridHeight;
  ubyte deadMaxColor;

  bool[int] ruleB;
  bool[int] ruleS;

  bool[Coord] alive;
  ubyte[Coord] dead;

  bool isFixed;

  void initGrid(string buf) {
    auto const sz = buf.length;
    writeln(sz);
    if (sz) {
      if (buf.length > 4 && buf[0..4] == "[M2]") {
        generateMacrocellGrid(buf);
      } else if (buf.length > 6 && buf[0..6] == "#MCell") {
        generateMCellGrid(buf);
      } else {
        generateRLEGrid(buf.dup);
      }
    } else {
      generateRandomGrid();
    }
  }

  void setRule(string rule) {
    bool[int] b;
    bool[int] s;
    bool isb = false;
    auto const sz = rule.length;
    for (int i = 0; i < sz; i++) {
      if (rule[i] == '/') {
        isb = false;
      } else if (rule[i] == 'b' || rule[i] == 'B') {
        isb = true;
      } else if (rule[i] == 's' || rule[i] == 'S') {
        isb = false;
      } else if (rule[i] >= '0' && rule[i] <= '9') {
        if (isb) {
          b[ rule[i]-'0' ] = true;
        } else {
          s[ rule[i]-'0' ] = true;
        }
      }
    }
    this.ruleB = b;
    this.ruleS = s;
  }

  void generateRandomGrid() {
    const int halfWidth = this.gridWidth/2;
    const int halfHeight = this.gridHeight/2;
    auto key = tuple(0,0);
    for (int i = -halfWidth; i < halfWidth; i++) {
      for (int j = -halfHeight; j < halfHeight; j++) {
        const auto nv = uniform(0, 20);
        if (nv > 17) { // a workaround to get a better looking result
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

          if ("rule" in vars) {
            this.setRule(vars["rule"]);
          }

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

  void generateMacrocellGrid(string buf) {
    import std.array : split, array;
    import std.string : strip, startsWith, indexOf;
    import std.math : pow;
    
    auto lines = buf.split("\n");
    
    struct MCNode {
      int level;
      bool[64] leafPattern;
      int[4] children;
    }
    
    MCNode[] nodes;
    // Node 0 is implicitly empty (all zeros)
    nodes ~= MCNode(3, (bool[64]).init, [0,0,0,0]);
    
    foreach (line; lines) {
      line = strip(line);
      if (line.length == 0) continue;
      
      if (line.startsWith("[M2]")) continue;
      
      if (line.startsWith("#R ") || line.startsWith("#r ")) {
        this.setRule(line[3..$]);
        continue;
      }
      
      if (line.startsWith("#")) continue;
      
      if (line.indexOf('$') != -1 || (line.length > 0 && (line[0] == '.' || line[0] == '*'))) {
        bool[64] pattern;
        int px = 0, py = 0;
        
        foreach (c; line) {
          if (c == '$') {
            py++;
            px = 0;
          } else if (c == '*') {
            if (px < 8 && py < 8) {
              pattern[py * 8 + px] = true;
            }
            px++;
          } else if (c == '.') {
            px++;
          }
        }
        
        nodes ~= MCNode(3, pattern, [0,0,0,0]);
        continue;
      }
      
      auto parts = line.split(" ");
      if (parts.length >= 5) {
        try {
          int level = parse!int(parts[0]);
          int[4] children;
          for (int i = 0; i < 4; i++) {
            children[i] = parse!int(parts[i + 1]);
          }
          nodes ~= MCNode(level, (bool[64]).init, children);
        } catch (Exception e) {
          continue;
        }
      }
    }
    
    if (nodes.length <= 1) {
      writeln("No valid nodes found in macrocell file");
      generateRandomGrid();
      return;
    }
    
    int rootIdx = cast(int)(nodes.length - 1);
    int rootLevel = nodes[rootIdx].level;
    
    enum int MAX_EXTRACT_SIZE = 16384;
    enum int MAX_CELLS = 10_000_000;
    
    long fullSize = cast(long)1 << rootLevel;
    writeln("Macrocell pattern size: 2^", rootLevel, " = ", fullSize, " x ", fullSize);
    
    int extractSize = MAX_EXTRACT_SIZE;
    if (fullSize < extractSize) extractSize = cast(int)fullSize;
    
    int extractOffset = extractSize / 2;
    
    long centerX = fullSize / 2;
    long centerY = fullSize / 2;
    long minX = centerX - extractOffset;
    long maxX = centerX + extractOffset;
    long minY = centerY - extractOffset;
    long maxY = centerY + extractOffset;
    
    this.gridWidth = extractSize;
    this.gridHeight = extractSize;
    
    int cellCount = 0;
    
    void extractCells(int nodeIdx, long x, long y, int level) {
      if (nodeIdx == 0) return;
      if (nodeIdx < 0 || nodeIdx >= nodes.length) return;
      if (cellCount >= MAX_CELLS) return;
      
      long nodeSize = cast(long)1 << level;
      
      if (x + nodeSize <= minX || x >= maxX || y + nodeSize <= minY || y >= maxY) {
        return;
      }
      
      auto node = nodes[nodeIdx];
      
      if (level == 3) {
        for (int py = 0; py < 8 && cellCount < MAX_CELLS; py++) {
          for (int px = 0; px < 8 && cellCount < MAX_CELLS; px++) {
            if (node.leafPattern[py * 8 + px]) {
              long cellX = x + px;
              long cellY = y + py;
              if (cellX >= minX && cellX < maxX && cellY >= minY && cellY < maxY) {
                auto key = tuple(cast(int)(cellX - centerX), cast(int)(cellY - centerY));
                this.alive[key] = true;
                cellCount++;
              }
            }
          }
        }
        return;
      }
      
      long halfSize = nodeSize / 2;
      
      // NW, NE, SW, SE
      extractCells(node.children[0], x, y, level - 1);
      extractCells(node.children[1], x + halfSize, y, level - 1);
      extractCells(node.children[2], x, y + halfSize, level - 1);
      extractCells(node.children[3], x + halfSize, y + halfSize, level - 1);
    }
    
    extractCells(rootIdx, 0, 0, rootLevel);
    writeln("Extracted ", this.alive.length, " cells from macrocell pattern (limited to ", extractSize, "x", extractSize, " region)");
  }
  
  void generateMCellGrid(string buf) {
    import std.array : split;
    import std.string : strip, startsWith;
    
    auto lines = buf.split("\n");
    
    int gridX = 0, gridY = 0;
    bool inPattern = false;
    int xOffset = 0, yOffset = 0;
    int maxX = 0, maxY = 0;
    
    foreach (line; lines) {
      line = strip(line);
      
      if (line.startsWith("#RULE ")) {
        this.setRule(line[6..$]);
      } else if (line.startsWith("#BOARD ")) {
        auto parts = line[7..$].split("x");
        if (parts.length >= 2) {
          try {
            maxX = parse!int(parts[0]);
            maxY = parse!int(parts[1]);
          } catch (Exception e) {}
        }
      }
    }
    
    foreach (line; lines) {
      line = strip(line);
      
      if (line == "#LIFE") {
        inPattern = true;
        continue;
      }
      
      if (line.startsWith("#")) continue;
      
      if (inPattern && line.length > 0) {
        gridX = 0;
        foreach (c; line) {
          if (c == '*' || c == 'O' || c == 'o') {
            auto key = tuple(gridX - xOffset, gridY - yOffset);
            this.alive[key] = true;
            if (gridX > maxX) maxX = gridX;
          }
          gridX++;
        }
        gridY++;
        if (gridY > maxY) maxY = gridY;
      }
    }
    
    xOffset = maxX / 2;
    yOffset = maxY / 2;
    
    bool[Coord] centered;
    foreach (key, value; this.alive) {
      auto newKey = tuple(key[0] - xOffset, key[1] - yOffset);
      centered[newKey] = true;
    }
    this.alive = centered;
    
    if (this.gridWidth < maxX) this.gridWidth = maxX;
    if (this.gridHeight < maxY) this.gridHeight = maxY;
    
    writeln("Loaded MCell pattern with ", this.alive.length, " cells");
  }

  void iterate() {
    bool[Coord] updated;
    int inb, jnb;

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
          if (this.isFixed && (inb > this.gridWidth || inb < -this.gridWidth || jnb > this.gridHeight || jnb < -this.gridHeight)) {
            continue;
          }
          if (!(tuple(inb, jnb) in updated)) {
            keyNb[0] = inb;
            keyNb[1] = jnb;
            updated[keyNb] = false;
          }
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
        if (nb in this.ruleS) {
          updated[k] = true;
        } else {
          updated.remove(k);
          this.dead[k] = 1;
        }
      } else {
        if (nb in this.ruleB) {
          updated[k] = true;
          if (k in this.dead)
            this.dead.remove(k);
        } else {
          updated.remove(k);
        }
      }
  	}

    this.alive = updated;
  }

  int getWidth() { return this.gridWidth; }
  int getHeight() { return this.gridHeight; }

  this(int gw, int gh, ubyte deadMaxColor, string baseRule, bool isFixed) {
    this.gridHeight = gh;
    this.gridWidth = gw;
    this.deadMaxColor = deadMaxColor;
    this.setRule(baseRule);
    this.isFixed = isFixed;

    //this.generateRandomGrid();
    //this.initGrid();
  }
}
