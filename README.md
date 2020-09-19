# Conway's Game of Life Experiment in Dlang (C GOLED)

Conway's Gamee of Life implementation in D.

SFML used for graphics. Capable of loading RLE files or generating a random grid.

TODO: 
 - [x] Sparse implementation (using Dlang's assoc arrays)
 - [ ] Different rules
   - [ ] Primary rule
   - [ ] Allow rule override from RLE (config)
   - [ ] Parse B/S notation
 - [ ] Camera movement
 - [ ] Multithreading
 - [ ] Saving resulting generations as BMPs
 - [ ] GPU computations
 - [ ] Switchable implementation, dense implementation using hashlife

## Build and install

1. Install DUB and Dlang compiler. My go-to choice is DMD compiler specifically
2. Get some libs to either ./libs/... directory or your system
  - You need CSFML libs, you can find them on the SFML website
  - path is platform dependant
3. `dub run`

## cli

- `-h / --help`
- `-f / --file` - path to RLE file

## config

Use config.example.json as reference, it uses config.json by default, or config.example.json, or just use default params.
