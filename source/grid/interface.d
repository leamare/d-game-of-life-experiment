module grid.gridinterface;

import std.typecons;

alias Coord = Tuple!(int, int);

interface GridStruct {
  // int gridWidth, gridHeight;
  // ubyte deadMaxColor;

  // bool[int] ruleB;
  // bool[int] ruleS;

  // bool[Coord] alive;
  // ubyte[Coord] dead;

  // bool isFixed;

  // this(int gw, int gh, ubyte deadMaxColor, string baseRule, bool isFixed);
  void iterate();
  void generateRLEGrid(char[] buf);
  void generateRandomGrid();
  void setRule(string rule);
  void initGrid(string buf);

  int getWidth();
  int getHeight();
}