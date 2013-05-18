// Generated by CoffeeScript 1.6.2
var Dungeon;

Dungeon = (function() {
  var BLANK_TILE, FLOOR_TILE, WALL_TILE;

  BLANK_TILE = 0;

  FLOOR_TILE = 1;

  WALL_TILE = 2;

  function Dungeon(map_width, map_height, max_features, room_chance) {
    this.map_width = map_width;
    this.map_height = map_height;
    this.max_features = max_features;
    this.room_chance = room_chance;
    this.tiles = [];
    this.fill_map();
  }

  Dungeon.prototype.fill_map = function() {
    var row, x, y, _i, _j, _ref, _ref1, _results;

    _results = [];
    for (y = _i = 1, _ref = this.map_height; 1 <= _ref ? _i <= _ref : _i >= _ref; y = 1 <= _ref ? ++_i : --_i) {
      row = [];
      for (x = _j = 1, _ref1 = this.map_width; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; x = 1 <= _ref1 ? ++_j : --_j) {
        row.push(BLANK_TILE);
      }
      _results.push(this.tiles.push(row));
    }
    return _results;
  };

  return Dungeon;

})();