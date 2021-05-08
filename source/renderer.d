module renderer;

import grid;
import std.algorithm;

import std.stdio;

struct Renderer {
  int windowWidth, windowHeight;
  int leftOffset, topOffset;
  int viewX, viewY;
  int scale;
  GridStruct grid;

  this(int ww, int wh, GridStruct grid) {
    this.windowHeight = wh;
    this.windowWidth = ww;
    this.grid = grid;
    this.viewX = 0;
    this.viewY = 0;
    
    this.recalculateScale();
  }

  void recalculateScale() {
    writeln(this.grid);
    auto gw = this.grid.getWidth();
    auto gh = this.grid.getHeight();

    if (this.windowWidth < gw || this.windowHeight < gh) {
      this.scale = 1;
    } else {
      this.scale = min(this.windowWidth/gw, this.windowHeight/gh);
    }
    
		this.leftOffset = (this.windowWidth % this.scale)/2;
		this.topOffset = (this.windowHeight % this.scale)/2;
	}

  void setViewportPos(int x, int y) {
    this.viewX = x;
    this.viewY = y;
  }

  void shiftViewportPosX(int x) {
    this.viewX += x;
  }

  void shiftViewportPosY(int y) {
    this.viewY += y;
  }

  void shiftViewportPos(int x, int y) {
    this.shiftViewportPosX(x);
    this.shiftViewportPosY(y);
  }

  void shiftScale(int mod) {
    this.scale += mod;
    if (this.scale < 1) this.scale = 1;
  }

  void setScale(int val) {
    this.scale = val;
  }

  int calculateX(int coord) {
    return (coord + this.viewX) * this.scale - this.windowWidth/2 + this.scale/2;
  }

  int calculateY(int coord) {
    return (coord + this.viewY) * this.scale - this.windowHeight/2 + this.scale/2;
  }
}