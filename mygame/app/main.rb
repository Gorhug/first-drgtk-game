class Dragon
  attr_accessor :x, :y, :w, :h, :speed
  def initialize grid
    @grid = grid
    # @inputs = inputs
    @x = 576
    @y = 200
    @w    = 100
    @h    = 80
    @speed    = 12
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
  def initialize x, y, speed, grid, started
    @grid = grid
    @x = x
    @y = y
    @w    = 48
    @h    = 48
    @speed    = speed
    @path = 'sprites/misc/fireball.png'
    @dead = false
    @anim_start = started -1
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
    rot_mul = @anim_start.frame_index count: 40, hold_for: 1, repeat: true
    # first move then draw

    # move
    # return
    # The argument order for ffi.draw_sprite is:
    # x, y, w, h, path
    ffi_draw.draw_sprite_2 @x, @y, @w, @h, @path, rot_mul * -9, 200
  end
end

class Target
  attr_accessor :x, :y, :w, :h, :speed, :dead
  def initialize grid
    size = 64
    @grid = grid
    @x = rand(@grid.w * 0.4) + @grid.w * 0.6 - size
    @y = rand(@grid.h - size * 2) + size
    @w    = size
    @h    = size
    # @speed    = speed
    @path = 'sprites/misc/target_red3.png'
    @dead = false
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

class Cloud
  attr_accessor :x, :y, :w, :h, :speed, :r, :g, :b, :a
  def initialize grid, size_m, speed_m
    @grid = grid
    @x = rand grid.w
    @y = rand grid.h
    @w = 190 * size_m
    @h = 127 * size_m
    @r = 256
    @g = 256
    @b = 256
    @a = 256 * size_m
    @speed = 2 * speed_m
    @path = "sprites/misc/cloud#{(rand 9) + 1}.png"
    # @anim_start = - @x
  end
  def move
    # sprite_index = @anim_start.frame_index count: 9, hold_for: 30, repeat: true
    # sprite_index += 1
    # @path = "sprites/misc/cloud#{sprite_index}.png"
    @x -= @speed
    if @x < -@w
      @x = @grid.w
      @y = rand @grid.h
    end
  end
  def draw_override ffi_draw
    # first move then draw

    move
    # return
    # The argument order for ffi.draw_sprite is:
    # x, y, w, h, path
    ffi_draw.draw_sprite_2 @x, @y, @w, @h, @path, nil, @a
  end
end
def tick args
  args.state.score ||= 0
  args.state.player ||= Dragon.new args.grid
  args.state.blue_sky ||= BlueSky.new args.grid
  args.state.fireballs ||= []
  args.state.target_count ||= 3
  # args.state.targets ||= args.state.target_count.map { |i| Target.new args.grid}
  args.state.targets ||= []
  args.state.cloud_count ||= 10
  args.state.cloud_layers ||= 4
  # args.state.clouds ||= []
  args.state.clouds ||= args.state.cloud_layers.map { |j| args.state.cloud_count.map { |i| Cloud.new args.grid, 1/(j+1), 1/(j+1)} }
  if args.state.tick_count == 0
    args.state.clouds.reverse!
    args.outputs.static_solids << args.state.blue_sky
    args.outputs.static_sprites << args.state.player
  end

  # args.outputs.solids << [args.state.blue_sky, args.state.clouds]
  # args.state.clouds.each { |layer| layer.each {|cloud| cloud.move }}
  args.state.player.move args.inputs
  if args.inputs.keyboard.key_down.z ||
      args.inputs.keyboard.key_down.j ||
      args.inputs.controller_one.key_down.a
    new_ball = Fireball.new args.state.player.x + args.state.player.w - 12,
                                        args.state.player.y + 10,
                                        args.state.player.speed + 2,
                                        args.grid, args.state.tick_count
    args.state.fireballs << new_ball
    # args.outputs.static_sprites << new_ball
  end
  args.state.fireballs.each do |fireball|
    fireball.move

    args.state.targets.each do |target|
      if args.geometry.intersect_rect? target, fireball
        target.dead = true
        fireball.dead = true
        args.state.score += 1
      end
    end
  end
  args.state.fireballs.reject! { |fireball| fireball.dead }
  args.state.targets.reject! { |target| target.dead }

  while args.state.targets.length < args.state.target_count do
    t = nil
    until t do
      t = Target.new args.grid
      args.state.targets.each do |existing|
        conflict = args.geometry.intersect_rect? existing, t
        if conflict
          t = nil
          break
        end
      end
    end
    args.state.targets << t
  end
  # args.outputs.static_sprites.reject! { |fireball| fireball.dead}
  # player_sprite_index = 1.frame_index count: 9, hold_for: 30, repeat: true
  # args.outputs.debug << "Fireballs: #{args.state.fireballs.length}"
  # args.outputs.debug << "Frame index: #{player_sprite_index}"
  # args.outputs.debug << "Clouds: #{args.state.clouds[0][0]}"
  # puts "Fireballs: #{args.state.fireballs.length}"
  args.outputs.sprites << [args.state.clouds, args.state.fireballs, args.state.targets ]
  args.outputs.labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Score: #{args.state.score}",
    size_enum: 4,
    font: "fonts/PressStart2P-Regular.ttf",
  }
  # args.outputs.debug << "Tick: #{args.state.tick_count}"
  # args.outputs.debug << args.gtk.framerate_diagnostics_primitives
end
