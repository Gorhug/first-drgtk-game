class Dragon
  attr_accessor :x, :y, :w, :h, :speed
  def initialize grid
    @grid = grid
    # @inputs = inputs
    @x = 576
    @y = 200
    @w    = 100
    @h    = 80
    @speed    = 24
    @path = ''
  end

  def dead
    false
  end

  def move inputs
    player_sprite_index = 0.frame_index count: 6, hold_for: 8, repeat: true
    @path = "sprites/misc/dragon-#{player_sprite_index}.png"
    dead_zone = 0.10
    x_movement = 0
    y_movement = 0
    if inputs.controller_one.left_analog_active? threshold_perc: dead_zone
      x_movement = inputs.controller_one.left_analog_x_perc * @speed
      y_movement = inputs.controller_one.left_analog_y_perc * @speed
    else

      if inputs.left
        x_movement = -@speed
      elsif inputs.right
        x_movement = @speed
      end

      if inputs.down
        y_movement = -@speed
      elsif inputs.up
        y_movement = @speed
      end
    end

    total_movement = x_movement.abs + y_movement.abs
    if total_movement > @speed
      x_movement = x_movement / (total_movement / @speed)
      y_movement = y_movement / (total_movement / @speed)
    end
    @x += x_movement
    @y += y_movement
    @x = @x.clamp 0, @grid.w - @w
    @y = @y.clamp 0, @grid.h - @h
  end

  # if the object that is in args.outputs.sprites (or static_sprites)
  # respond_to? :draw_override, then the method is invoked giving you
  # access to the class used to draw to the canvas.
  def draw_override ffi_draw
    # first move then draw

    # move
    # return
    # The argument order for ffi.draw_sprite is:
    # x, y, w, h, path
    ffi_draw.draw_sprite @x, @y, @w, @h, @path
  end
end

class Fireball
  attr_accessor :x, :y, :w, :h, :speed, :dead
  def initialize x, y, speed, grid
    @grid = grid
    @x = x
    @y = y
    @w    = 32
    @h    = 32
    @speed    = speed
    @path = 'sprites/misc/fireball.png'
    @dead = false
  end

  def move
    @x += @speed
    if @x > @grid.w
      @dead = true
    end
  end

  # if the object that is in args.outputs.sprites (or static_sprites)
  # respond_to? :draw_override, then the method is invoked giving you
  # access to the class used to draw to the canvas.
  def draw_override ffi_draw
    # first move then draw

    move
    # return
    # The argument order for ffi.draw_sprite is:
    # x, y, w, h, path
    ffi_draw.draw_sprite @x, @y, @w, @h, @path if !@dead
  end
end

class Solid
  attr_accessor :x, :y, :w, :h, :r, :g, :b, :a, :anchor_x, :anchor_y, :blendmode_enum

  def primitive_marker
    :solid # or :border
  end
end

# Inherit from type
class BlueSky < Solid
  # constructor
  def initialize grid
    @x = 0
    @y = 0
    @w = grid.w
    @h = grid.h
    @r = 92
    @g = 120
    @b = 230
  end
end

def tick args

  args.state.player ||= Dragon.new args.grid
  args.state.blue_sky ||= BlueSky.new args.grid
  if args.state.tick_count == 0
    # args.outputs.static_sprites << args.state.player
    args.outputs.static_solids << args.state.blue_sky
  end
  args.state.fireballs ||= []

  args.state.player.move args.inputs
  if args.inputs.keyboard.key_down.z ||
      args.inputs.keyboard.key_down.j ||
      args.inputs.controller_one.key_down.a
    new_ball = Fireball.new args.state.player.x + args.state.player.w - 12,
                                        args.state.player.y + 10,
                                        args.state.player.speed + 2,
                                        args.grid
    args.state.fireballs << new_ball
    # args.outputs.static_sprites << new_ball
  end

  args.state.fireballs.reject! { |fireball| fireball.dead }
  # args.outputs.static_sprites.reject! { |fireball| fireball.dead}
  # args.gtk.notify! "Fireballs: #{args.state.fireballs.length}"
  # args.outputs.solids << args.state.blue_sky
  args.outputs.sprites << [args.state.fireballs, args.state.player ]
end
