# http://roguebasin.roguelikedevelopment.org/index.php?title=Dungeon-Building_Algorithm

class Dungeon
  BLANK_TILE = 0
  FLOOR_TILE = 1
  WALL_TILE = 2
  DOOR_TILE = 3
  CORRIDOR_TILE = 4

  random: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min;

  distance: (x1, y1, x2, y2) ->
    Math.sqrt(Math.pow((y2 - y1), 2) + Math.pow((x2 - x1), 2))

  # Returns true if there is an entity collision
  collides: (x, y, distance) ->
    caller = this
    _.some @entities, (entity) ->
      caller.distance(x, y, entity.x, entity.y) < distance


  collision_map: ->
    _.map @tiles, (row) ->
      _.map row, (tile) ->
        if tile == WALL_TILE
          FLOOR_TILE
        else
          BLANK_TILE

  collisionMap: ->
    map = {}
    _.each @tiles, (row, yIndex) ->
      _.each row, (tile, xIndex) ->
        key = x + ',' + y
        if tile == WALL_TILE
          map[key] = FLOOR_TILE
        else
          map[key] = BLANK_TILE
    map

  background_map: ->
    _.map @tiles, (row) ->
      _.map row, (tile) ->
        if tile == WALL_TILE
          BLANK_TILE
        else if tile == DOOR_TILE
          FLOOR_TILE
        else
          tile

  constructor: (@map_width, @map_height, @max_features, @room_chance) ->
    @tiles = []
    @current_features = 0
    @fill_map()
    @up_stairs_pos = { x: 0, y: 0}
    @down_stairs_pos = { x: 0, y: 0}
    @monsters = []
    @entities = []

    # Dig out a single room in the center of the map
    x = Math.floor(@map_width / 2)
    y = Math.floor(@map_height / 2)
    dir = @random(0, 3)
    @make_room(x, y, 8, 8, dir)
    @current_features += 1

    # Star the main loop
    counting_tries = 0
    while counting_tries < 1000
      break if @current_features == @max_features

      # Pick a random wall
      newx = 0
      xmod = 0
      newy = 0
      ymod = 0
      valid_tile = -1

      # 1000 chances to find a suitable object (room or corridor)
      testing = 0
      while testing < 1000
        newx = @random(1, @map_width - 2)
        newy = @random(1, @map_height - 2)
        valid_tile = -1

        if @get_tile(newx, newy) == WALL_TILE || @get_tile(newx, newy) == CORRIDOR_TILE
          # check if we can reach the place
          if @get_tile(newx, newy + 1) == FLOOR_TILE || @get_tile(newx, newy + 1) == CORRIDOR_TILE
            valid_tile = 0
            xmod = 0
            ymod = -1
          else if @get_tile(newx - 1, newy) == FLOOR_TILE || @get_tile(newx - 1, newy) == CORRIDOR_TILE
            valid_tile = 1
            xmod = 1
            ymod = 0
          else if @get_tile(newx, newy - 1) == FLOOR_TILE || @get_tile(newx, newy - 1) == CORRIDOR_TILE
            valid_tile = 2
            xmod = 0
            ymod = 1
          else if @get_tile(newx + 1, newy) == FLOOR_TILE || @get_tile(newx + 1, newy) == CORRIDOR_TILE
            valid_tile = 3
            xmod = -1
            ymod = 0

          # check that we don't have another door nearby, so we won't get clustered openings
          if valid_tile > -1
            if @get_tile(newx, newy) == DOOR_TILE # north
              valid_tile = -1
            else if @get_tile(newx - 1, newy) == DOOR_TILE # east
              valid_tile = -1
            else if @get_tile(newx, newy - 1) == DOOR_TILE # south
              valid_tile = -1
            else if @get_tile(newx + 1, newy) == DOOR_TILE # west
              valid_tile = -1

          # If we can, jump out of the loop and continue with the rest
          break if valid_tile > -1

        testing += 1

      if valid_tile > -1
        # Chose what to build at our newly found place, and what direction
        feature = @random(0, 100)
        if feature <= @room_chance
          if @make_room((newx + xmod), (newy + ymod), 8, 8, valid_tile)
            @current_features += 1

            # Mark the wall opening with a door
            @set_tile(newx, newy, DOOR_TILE)

            # Clean up in front of the door so we can reach it
            @set_tile((newx + xmod), (newy + ymod), FLOOR_TILE)
        else if feature >= @room_chance
          if @make_corridor((newx + xmod), (newy + ymod), 6, valid_tile)
            @current_features += 1

            @set_tile(newx, newy, DOOR_TILE)
            @set_tile((newx + xmod), (newy + ymod), FLOOR_TILE)

      counting_tries += 1

    # Sprinkle bonus stuff (stairs, chests, etc)
    newx = 0
    newy = 0
    ways = 0
    state = 0
    while state != 10
      testing = 0
      while testing < 1000
        newx = @random(1, @map_width - 1)
        newy = @random(1, @map_height - 2)

        # From how many directions can we reach the random spot
        # less is better
        ways = 4

        north_tile = @get_tile(newx, newy + 1)
        east_tile = @get_tile(newx - 1, newy)
        south_tile = @get_tile(newx, newy - 1)
        west_tile = @get_tile(newx + 1, newy)

        if north_tile == FLOOR_TILE
          ways -= 1
        if east_tile == FLOOR_TILE
          ways -= 1
        if south_tile == FLOOR_TILE
          ways -= 1
        if west_tile == FLOOR_TILE
          ways -= 1

        pos = { x: newx, y: newy }

        if state == 0 && ways == 0 && !@collides(newx, newy, 2)
          # We're in state 0, lets set the up stairs location
          @up_stairs_pos.x = newx
          @up_stairs_pos.y = newy
          @entities.push pos
          state = 1
          break
        else if state == 1 && ways == 0 && @distance(@up_stairs_pos.x, @up_stairs_pos.y, newx, newy) > 2 && !@collides(newx, newy, 2)
          # Make sure the downstairs aren't too close
          @down_stairs_pos.x = newx
          @down_stairs_pos.y = newy
          @entities.push pos
          state = 2
          break
        else if state == 2 && ways == 0 && !@collides(newx, newy, 3)
          @monsters.push pos
          @entities.push pos
          state = 10 if @monsters.length > 10
        testing += 1


  fill_map: ->
    for y in [1..@map_height]
      row = []
      for x in [1..@map_width]
        row.push(BLANK_TILE)
      @tiles.push(row)

  make_room: (x, y, width, height, direction) ->
    room = new Room(x, y, width, height, direction, this)
    room.build()

  make_corridor: (x, y, length, direction) ->
    corridor = new Corridor(x, y, length, direction, this)
    corridor.build()

  get_tile: (x, y) ->
    @tiles[y][x]

  set_tile: (x, y, tile) ->
    @tiles[y][x] = tile

  is_blank_tile: (x, y) ->
    @get_tile(x, y) == BLANK_TILE

  set_wall_tile: (x, y) ->
    @set_tile(x, y, WALL_TILE)

  set_floor_tile: (x, y) ->
    @set_tile(x, y, FLOOR_TILE)

class Room
  constructor: (@x, @y, @width, @height, @direction, @dungeon) ->
    @xlen = @dungeon.random(4, @width)
    @ylen = @dungeon.random(4, @height)
    @dir = 0
    @dir = @direction if @direction > 0 && @direction < 4

  build: ->
    if @dir == 0 && @has_enough_space_north()
      @build_north()

    else if @dir == 1 && @has_enough_space_east()
      @build_east()

    else if @dir == 2 && @has_enough_space_south()
      @build_south()

    else if @dir == 3 && @has_enough_space_west()
      @build_west()

    else
      false

  has_enough_space_north: ->
    ytemp = @y
    while ytemp > (@y - @ylen)
      return false if ytemp < 0 || ytemp >= @dungeon.map_height

      xtemp = @x - Math.floor(@xlen / 2)
      while xtemp < (@x + Math.floor((@xlen + 1) / 2))
        return false if xtemp < 0 || xtemp >= @dungeon.map_width
        return false unless @dungeon.is_blank_tile(xtemp, ytemp)
        xtemp += 1
      ytemp -= 1
    true

  build_north: ->
    ytemp = @y
    while ytemp > (@y - @ylen)
      xtemp = @x - Math.floor(@xlen / 2)
      while xtemp < (@x + Math.floor((@xlen + 1) / 2))
        # Start with walls
        if xtemp == (@x - Math.floor(@xlen / 2))
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if xtemp == (@x + Math.floor((@xlen - 1) / 2))
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == (@y - @ylen + 1)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else
          @dungeon.set_floor_tile(xtemp, ytemp)
        xtemp += 1
      ytemp -= 1

  has_enough_space_east: ->
    ytemp = (@y - Math.floor(@ylen / 2))
    while ytemp < (@y + Math.floor((@ylen + 1) / 2))
      return false if ytemp < 0 || ytemp >= @dungeon.map_height

      xtemp = @x
      while xtemp < @x + @xlen
        return false if xtemp < 0 || xtemp >= @dungeon.map_width
        return false unless @dungeon.is_blank_tile(xtemp, ytemp)
        xtemp += 1
      ytemp += 1
    true

  build_east: ->
    ytemp = (@y - Math.floor(@ylen / 2))
    while ytemp < (@y + Math.floor((@ylen + 1) / 2))
      xtemp = @x
      while xtemp < @x + @xlen
        if xtemp == @x
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if xtemp == @x + @xlen - 1
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y - Math.floor(@ylen / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y + Math.floor((@ylen - 1) / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else
          @dungeon.set_floor_tile(xtemp, ytemp)
        xtemp +=1
      ytemp +=1

  has_enough_space_south: ->
    ytemp = @y
    while ytemp < @y + @ylen
      return false if ytemp < 0 || ytemp >= @dungeon.map_height

      xtemp = @x - Math.floor(@xlen / 2)
      while xtemp < @x + Math.floor((@xlen + 1) / 2)
        return false if xtemp < 0 || xtemp >= @dungeon.map_width
        return false unless @dungeon.is_blank_tile(xtemp, ytemp)
        xtemp += 1
      ytemp += 1
    true

  build_south: ->
    ytemp = @y
    while ytemp < @y + @ylen
      xtemp = @x - Math.floor(@xlen / 2)
      while xtemp < @x + Math.floor((@xlen + 1) / 2)
        if xtemp == @x - Math.floor(@xlen / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if xtemp == @x + Math.floor((@xlen - 1) / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y + @ylen - 1
          @dungeon.set_wall_tile(xtemp, ytemp)
        else
          @dungeon.set_floor_tile(xtemp, ytemp)
        xtemp += 1
      ytemp += 1
    true


  has_enough_space_west: ->
    ytemp = @y - Math.floor(@ylen / 2)
    while ytemp < @y + Math.floor((@ylen + 1) / 2)
      return false if ytemp < 0 || ytemp >= @dungeon.map_height

      xtemp = @x
      while xtemp > @x - @xlen
        return false if xtemp < 0 || xtemp >= @dungeon.map_width
        return false unless @dungeon.is_blank_tile(xtemp, ytemp)
        xtemp -= 1
      ytemp += 1
    true

  build_west: ->
    ytemp = @y - Math.floor(@ylen / 2)
    while ytemp < @y + Math.floor((@ylen + 1) / 2)
      xtemp = @x
      while xtemp > @x - @xlen
        if xtemp == @x
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if xtemp == @x - @xlen + 1
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y - Math.floor(@ylen / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else if ytemp == @y + Math.floor((@ylen - 1) / 2)
          @dungeon.set_wall_tile(xtemp, ytemp)
        else
          @dungeon.set_floor_tile(xtemp, ytemp)
        xtemp -= 1
      ytemp += 1

class Corridor extends Room
  constructor: (@x, @y, @length, @direction, @dungeon) ->
    horizontal = @dungeon.random(0, 1)
    if horizontal
      @xlen = @dungeon.random(3, @length)
      @ylen = 3
    else
      @xlen = 3
      @ylen = @dungeon.random(3, @length)

    @dir = 0
    @dir = @direction if @direction > 0 && @direction < 4