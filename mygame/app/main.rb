class Dragon
  attr :x, :y, :w, :h, :speed, :dead
  attr_gtk
  def initialize args
    @args = args
    # @grid = grid
    # @inputs = inputs
    @x = 576
    @y = 200
    @w    = 100
    @h    = 80
    @speed    = 12
    @path = ''
    @dead = false
  end

  def move
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
    @x = @x.clamp 0, grid.w - @w
    @y = @y.clamp 0, grid.h - @h
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
    ffi_draw.draw_sprite @x, @y, @w, @h, @path unless @dead
  end
end

class Fireball
  attr :x, :y, :w, :h, :speed, :dead
  attr_gtk
  def initialize args
    @args = args
    @x = state.player.x + state.player.w - 12
    @y = state.player.y + 10
    @w    = 48
    @h    = 48
    @speed    = state.player.speed + 2
    @path = 'sprites/misc/fireball.png'
    @dead = false
    @anim_start = state.tick_count - 1
  end

  def move
    @x += @speed
    if @x > grid.w
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
    # @grid = grid
    @x = rand(grid.w * 0.4) + grid.w * 0.6 - size
    @y = rand(grid.h - size * 2) + size
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
    ffi_draw.draw_sprite @x, @y, @w, @h, @path
  end
end

class Solid
  attr :x, :y, :w, :h, :r, :g, :b, :a, :anchor_x, :anchor_y, :blendmode_enum

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
  attr :x, :y, :w, :h, :speed, :r, :g, :b, :a
  attr_gtk

  def initialize args, size_m, speed_m
    @args = args
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
      @x = grid.w
      @y = rand grid.h
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

HIGH_SCORE_FILE = "high-score.txt"
class Game
  attr_gtk

  def initialize args
    @args = args
  end

  def fire_input?
    inputs.keyboard.key_down.z ||
      inputs.keyboard.key_down.j ||
      inputs.controller_one.key_down.a
  end


  def game_over_tick
    state.high_score ||= (gtk.read_file HIGH_SCORE_FILE).to_i

    state.timer -= 1

    if !state.saved_high_score && state.score > state.high_score
      gtk.write_file HIGH_SCORE_FILE, state.score.to_s
      state.saved_high_score = true
    end

    labels = []
    labels << {
      x: 40,
      y: grid.h - 40,
      text: "Game Over!",
      size_enum: 10,
      font: "fonts/PressStart2P-Regular.ttf"
    }
    labels << {
      x: 40,
      y: grid.h - 90,
      text: "Score: #{state.score}",
      size_enum: 7,
      font: "fonts/PressStart2P-Regular.ttf"
    }

    if state.score > state.high_score
      labels << {
        x: 40,
        y: grid.h - 140,
        text: "New high-score!",
        size_enum: 4,
        font: "fonts/PressStart2P-Regular.ttf"
      }
    else
      labels << {
        x: 40,
        y: args.grid.h - 140,
        text: "Score to beat: #{args.state.high_score}",
        size_enum: 3,
        font: "fonts/PressStart2P-Regular.ttf"
      }
    end

    labels << {
      x: 40,
      y: 90,
      text: "Fire to restart",
      size_enum: 2,
      font: "fonts/PressStart2P-Regular.ttf"
    }
    outputs.labels << labels

    if state.timer < -30 && fire_input?
      $gtk.reset
    end
  end
end

def tick args
  # if args.state.tick_count == 1
  #   args.audio[:music] = { input: "sounds/a-worthy-challenge.ogg", looping: true }
  # end
  args.state.score ||= 0
  args.state.player ||= Dragon.new args
  args.state.blue_sky ||= BlueSky.new args.grid
  args.state.fireballs ||= []
  args.state.target_count ||= 3
  # args.state.targets ||= args.state.target_count.map { |i| Target.new args.grid}
  args.state.targets ||= []
  args.state.cloud_count ||= 10
  args.state.cloud_layers ||= 4
  # args.state.clouds ||= []
  args.state.clouds ||= args.state.cloud_layers.map { |j| args.state.cloud_count.map { |i| Cloud.new args, 1/(j+1), 1/(j+1)} }
  if args.state.tick_count == 0
    args.state.clouds.reverse!
    args.outputs.static_solids << args.state.blue_sky
    args.outputs.static_sprites << args.state.player
  end

  # args.state.player.dead = true
  # args.state.timer ||= 0
  # game_over_tick args
  # return
  # args.outputs.solids << [args.state.blue_sky, args.state.clouds]
  # args.state.clouds.each { |layer| layer.each {|cloud| cloud.move }}
  args.state.player.move
  if fire_input? args.inputs
    args.audio[:fireball] = {input: "sounds/creature1.ogg"}
    args.state.fireballs << (Fireball.new args)
  end
  args.state.fireballs.each do |fireball|
    fireball.move

    args.state.targets.each do |target|
      if args.geometry.intersect_rect? target, fireball
        args.audio[:hit] = {input: "sounds/explosion#{(rand 4)+1}.ogg"}
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
