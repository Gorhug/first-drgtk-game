# Copyright Ilkka Forsblom

def audio_pan pos, full
  pos.to_f * 2.0 / full.to_f - 1.0
end

class Dragon
  attr :x, :y, :w, :h, :speed, :dead, :angle
  attr_gtk

  # waypoint code for mouse/touch control adapted from
  # https://github.com/DragonRidersUnite/touch_playground/
  # +angle+ is expected to be in degrees with 0 being facing right
  def vel_from_angle(angle, speed)
    [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
  end

  # returns diametrically opposed angle
  # uses degrees
  def opposite_angle(angle)
    add_to_angle(angle, 180)
  end

  # returns a new angle from the og `angle` one summed with the `diff`
  # degrees! of course
  def add_to_angle(angle, diff)
    ((angle + diff) % 360).abs
  end

  def deg_to_rad(deg)
    (deg * Math::PI / 180).round(4)
  end

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
    @angle = 0
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
    # outputs.debug << "Total movement: #{total_movement}"
    if total_movement > @speed
      x_movement = x_movement / (total_movement / @speed)
      y_movement = y_movement / (total_movement / @speed)
    end
    if total_movement > 0
      state.waypoint = nil
      @x += x_movement
      @y += y_movement
    elsif inputs.mouse.click || inputs.touch.finger_left
        state.waypoint = {
          x: (inputs.mouse.click.x || inputs.touch.finger_left.x) - @w + 10,
          y: (inputs.mouse.click.y || inputs.touch.finger_left.y),
          w: 16,
          h: 16,
          anchor_x: 0.5,
          anchor_y: 0.5,
          primitive_marker: :border
        }
        wp = state.waypoint
        wp.x = wp.x.clamp 0, grid.w
        wp.y = wp.y.clamp 0, grid.h
    end
    # outputs.debug << "Waypoint: #{state.waypoint}"
    wp = state.waypoint
    if wp
      # p_center = {x: @x+@w -32, y: @y, w: 48, h: 48}
      # wp_center = {x: wp.x+wp.w/2, y: wp.y+wp.h/2}
      @angle = opposite_angle geometry.angle_from self, wp
      x_vel, y_vel = vel_from_angle @angle, @speed
      @x += x_vel
      @y += y_vel
      outputs.debug << [wp, {x: @x, y: @y, w: @w, h: @h, primitive_marker: :border}]
      @angle = 0
      if wp.intersect_rect? self
        state.waypoint = nil
      end
    end
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
    @y = state.player.y
    @w    = 48
    @h    = 48
    @speed    = state.player.speed + 2
    @x = state.player.x + state.player.w - @w
    @path = 'sprites/misc/fireball.png'
    @dead = false
    @anim_start = Kernel.tick_count - 1
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
  attr :x, :y, :w, :h, :speed, :dead, :angle, :dx, :dy
  attr_gtk

  def sleep_time
    3 * FPS * (state.timer / (20*FPS)) + 30
  end

  def initialize args
    @args = args
    size = 64
    # @grid = grid
    @x = rand(grid.w * 0.4) + grid.w * 0.6 - size
    @y = rand(grid.h - size * 2) + size
    @w    = size
    @h    = size
    # @speed    = speed
    @path = 'sprites/misc/target_red3.png'
    @dead = false
    @angle = 0
    @sleep = sleep_time
    @dx = 0
    @dy = 0
    @speed = 25
  end

  def move
    @sleep -= 1
    @dx *= 0.9
    @dy *= 0.9
    if @sleep <= 0
      @angle = rand 360
      @sleep = sleep_time
      @dx = @angle.vector_x @speed
      @dy = @angle.vector_y @speed
      audio[:whoosh] = {
              input: 'sounds/jump1.ogg',
              gain: 0.6,
              pitch: rand + 0.5,
              x: (audio_pan @x, grid.w),
              y: (audio_pan @y, grid.h),
            }
    end
    @x += @dx
    @y += @dy
    @x = @x.clamp 0, grid.w - @w
    @y = @y.clamp 0, grid.h - @h
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

class Horizon
  attr_sprite
  attr_gtk

  def initialize args
    @args = args
    @w = 1024
    @h = 1024
    @x = 0 # grid.left
    @y = grid.top
    # @anchor_x = 0.0
    @anchor_y = 1.0
    @path = "sprites/uncolored_peaks.png"
    # @anim_start = - @x
    @r = 0
    @g = 128
  end

  def draw_override ffi_draw
    # first move then draw

    # move
    # return
    2.times do |i|
      ffi_draw.draw_sprite_5 @x + i*@w, @y, @w, @h,
      @path,
      nil, #@angle,
      nil, @r, @g, nil, #@alpha, @r, @g, @blue_saturation,
      nil, nil, nil, nil, #@tile_x, @tile_y, @tile_w, @tile_h,
      nil, nil, #@flip_horizontally, @flip_vertically,
      nil, nil, #@angle_anchor_x, @angle_anchor_y,
      nil, nil, nil, nil, #@source_x, @source_y, @source_w, @source_h,
      nil, #@blendmode_enum,
      @anchor_x, @anchor_y
    end
      # The argument order for ffi_draw.draw_sprite_5 is:
    # x, y, w, h,
    # path,
    # angle,
    # alpha, red_saturation, green_saturation, blue_saturation
    # tile_x, tile_y, tile_w, tile_h,
    # flip_horizontally, flip_vertically,
    # angle_anchor_x, angle_anchor_y,
    # source_x, source_y, source_w, source_h,
    # blendmode_enum
    # anchor_x
    # anchor_y
  end
end

HIGH_SCORE_FILE = "saves/high-score.txt"
FPS = 60
class Game
  attr_gtk

  def initialize args
    @args = args
    state.score = 0
    # state.player ||= Dragon.new args
    # state.blue_sky ||= BlueSky.new grid
    state.fireballs = []
    state.target_count = 3
    state.targets = []
    state.timer = 20 * FPS
    state.saved_high_score = false
    state.high_score = (gtk.read_file HIGH_SCORE_FILE).to_i
    state.fg_clouds = nil
  end

  def fire_input?
    inputs.keyboard.key_down.z ||
      inputs.keyboard.key_down.j ||
      inputs.controller_one.key_down.a ||
      !state.fs_touched &&
      (inputs.mouse.click ||
      inputs.touch.finger_right)
  end

  def prepare_tick
    state.player.move
    state.label.prepare ||= state.default_font.merge({
      x: grid.w / 2,
      y: grid.top - 280,
      text: "PREPARE!",
      size_enum: 6,
      alignment_enum: 1
    })
    if audio.key? :begin
      outputs.labels << state.label.prepare
    else
      audio[:music].paused = false
      state.scene = "gameplay"
    end
  end

  def prepare_for_prepare
    state.reset_game = "prepare"
    state.player.dead = false
    audio[:music].paused = true
    audio[:begin] = {input: "sounds/success.ogg"}
  end

  def game_over_tick

    # state.timer -= 1

    if !state.saved_high_score && state.score > state.high_score
      gtk.write_file HIGH_SCORE_FILE, state.score.to_s
      state.saved_high_score = true
    end
    labels = []
    if !audio.key? :gameover
      audio[:music].paused = false
      prepare_for_prepare if fire_input?
      labels << {
        x: 40,
        y: 90,
        text: "Fire to restart",
        size_enum: 2,
    }
    end


    labels << {
      x: 40,
      y: grid.h - 40,
      text: "Game Over!",
      size_enum: 10,
    }
    labels << {
      x: 40,
      y: grid.h - 90,
      text: "Score: #{state.score}",
      size_enum: 7,
    }

    if state.score > state.high_score
      labels << {
        x: 40,
        y: grid.h - 140,
        text: "New high-score!",
        size_enum: 4,
      }
    else
      labels << {
        x: 40,
        y: grid.h - 140,
        text: "Score to beat: #{state.high_score}",
        size_enum: 3,
      }
    end
    outputs.labels << labels.map {|l| state.default_font.merge l}
  end

  def gameplay_tick
    state.timer -= 1
    if state.timer <= 0
      audio[:music].paused = true
      # audio[:music].gain = 0.25
      audio[:gameover] = {input: "sounds/failure.ogg"}
      state.scene = "game_over"
      state.player.dead = true
      return
    end
    state.fg_clouds ||= state.cloud_count.map do |i|
      cloud = Cloud.new args, 1.5, 1.5
      cloud.x += 2*grid.w
      cloud
    end
    # outputs.solids << [state.blue_sky, state.clouds]
    # state.clouds.each { |layer| layer.each {|cloud| cloud.move }}
    state.player.move
    if state.game.fire_input?
      audio[:fireball] = {
        input: "sounds/creature1.ogg",
        x: (audio_pan state.player.x, grid.w),
        y: (audio_pan state.player.y, grid.h),
      }
      state.fireballs << (Fireball.new args)
      # audio[:gameover] = {input: "sounds/Failure.wav"}
    end
    if audio.key? :fireball
      outputs.debug << "Fireball sound x: #{audio.fireball.x}, y: #{audio.fireball.y}"
    end
    state.fireballs.each do |fireball|
      fireball.move

      state.targets.each do |target|
        if geometry.intersect_rect? target, fireball
          audio[:hit] = {
            input: "sounds/explosion#{(rand 4)+1}.ogg",
            x: (audio_pan target.x, grid.w),
            y: (audio_pan target.y, grid.h),
          }
          target.dead = true
          fireball.dead = true
          state.score += 1
        end
      end
    end
    state.fireballs.reject! { |fireball| fireball.dead }
    state.targets.reject! { |target| target.dead }

    while state.targets.length < state.target_count do
      t = nil
      until t do
        t = Target.new args
        state.targets.each do |existing|
          conflict = geometry.intersect_rect? existing, t
          if conflict
            t = nil
            break
          end
        end
      end
      state.targets << t
    end
    # outputs.static_sprites.reject! { |fireball| fireball.dead}
    # player_sprite_index = 1.frame_index count: 9, hold_for: 30, repeat: true
    # outputs.debug << "Fireballs: #{state.fireballs.length}"
    # outputs.debug << "Frame index: #{player_sprite_index}"
    # outputs.debug << "Clouds: #{state.clouds[0][0]}"
    # puts "Fireballs: #{state.fireballs.length}"
    outputs.primitives << [state.fireballs, state.targets, state.fg_clouds ]
    outputs.labels << [{
      x: 40,
      y: grid.h - 40,
      text: "Score: #{state.score}",
      size_enum: 4,
    },{
      x: grid.w - 40,
      y: grid.h - 40,
      text: "Time Left: #{(state.timer / FPS).round}",
      size_enum: 2,
      alignment_enum: 2,
    }].map {|t| state.default_font.merge t}
    # outputs.debug << "Touch: #{gtk.platform? :touch}"
    # outputs.debug << "Tick: #{state.tick_count}"
    # outputs.debug << gtk.framerate_diagnostics_primitives
  end

  def title_tick
    # state.title_ending ||= false
    prepare_for_prepare if fire_input? #&& !state.title_ending

    state.player.dead = false
    state.player.move

    labels = []
    labels << {
      x: grid.w / 2,
      y: grid.top - 290,
      text: "Target Practice",
      size_enum: 6,
      alignment_enum: 1,
    }
    labels << {
      x: grid.w / 2,
      y: grid.top - 350,
      text: "Hit the targets!",
      alignment_enum: 1,
    }
    controls_text = ""
    # outputs.debug << "Last active: #{inputs.last_active}"
    case inputs.last_active
    when :keyboard
      controls_text = "Arrows or WASD to move, Z or J to fire"
    when :controller
      controls_text = "D-pad or left analog to move, A-button to fire"
    when :mouse
      controls_text = "Click to fire and move to pointed spot"
    end
    if gtk.platform? :touch
      labels << {
        x: 40,
        y: 160,
        text: "Touch left side to move, right side to fire",
      }
    else
      labels << {
        x: 40,
        y: 160,
        text: "Mouse, keyboard, gamepad supported",
      }
    end
    labels << {
      x: 40,
      y: 120,
      text: controls_text,
    }
    labels << {
      x: 40,
      y: 80,
      text: "Fire to start",
      size_enum: 2,
    }
    labels.map! {|l| state.default_font.merge l}
    labels <<  {
      x: grid.w / 2,
      y: grid.top - 200,
      text: "Gorhug presents",
      font: "fonts/jacquard12.ttf",
      size_enum: 28,
      alignment_enum: 1,
    }
    outputs.labels << labels
  end

end

class Main
  attr_gtk

  def initialize args
    @args = args
  end

  def tick
    state.scene ||= "title"
    state.default_font ||= {
      font: "fonts/press_start_2p.ttf",
      # size_enum: 4,
    }
    # outputs.debug << "Touch left: #{inputs.finger_left}"
    if Kernel.tick_count == 1
      audio[:music] = { input: "sounds/a-worthy-challenge.ogg",
      looping: true,
      # gain: 0.1
    }
    end
    if (!gtk.platform? :touch) && (!inputs.keyboard.has_focus &&
        # gtk.production? &&
        Kernel.tick_count != 0)
      outputs.background_color = [0, 0, 0]
      outputs.labels << state.default_font.merge({ x: 640,
                          y: 360,
                          text: "Game Paused (click to resume).",
                          alignment_enum: 1,
                          r: 0, g: 0, b: 0,
                          size_enum: 6,
                        })
      audio.volume = 0.0
      return
    else
      audio.volume = 1.0
    end
    state.fsb_rect ||= layout.rect row: 0, col: 12, w: 2, h: 2
    state.fullscreen_button ||= state.fsb_rect.center.merge(
      # x: grid.w / 2,
      # y: grid.top,
      w: 96, h: 96,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/misc/transparent_dark28.png"
    )
    state.last_fs_touch ||= -30
    state.fs_touched = false
    # outputs.debug << "Touch: #{inputs.touch}"
    touches = inputs.touch.values
    touches << inputs.mouse.click if inputs.mouse.click
    if ["title", "game_over"].include? state.scene
      if (touches.any? {|t| t.inside_rect? state.fullscreen_button}) &&
        (state.last_fs_touch.elapsed_time > FPS)
        state.last_fs_touch = Kernel.tick_count
        state.fs_touched = true
      end
      outputs.primitives << state.fullscreen_button
    end
    if (inputs.keyboard.key_down.enter && inputs.keyboard.key_held.alt) || state.fs_touched
      gtk.set_window_fullscreen !gtk.window_fullscreen? # if gtk.production?
      # gtk.notify! "Fullscreen toggled at tick: #{state.tick_count}"
    end

    state.player ||= Dragon.new args
    state.blue_sky ||= BlueSky.new grid
    state.cloud_count ||= 10
    state.cloud_layers ||= 4
    state.horizon = Horizon.new args
    state.clouds ||= state.cloud_layers.map { |j| state.cloud_count.map { |i| Cloud.new args, 1/(j+1), 1/(j+1)} }
    if Kernel.tick_count == 0
      state.clouds.reverse!
      outputs.static_solids << state.blue_sky
      outputs.static_sprites << [state.horizon, state.clouds, state.player]
      gtk.set_cursor "sprites/misc/target_b.png", 16, 16
      # gtk.set_window_fullscreen true if gtk.platform? :touch
      # outputs.static_primitives << state.fullscreen_button # if gtk.platform? :touch
    end
    state.game ||= Game.new args
    if state.reset_game
      state.scene = state.reset_game
      state.reset_game = nil
      state.game = Game.new args
      state.player.dead = false
    end
    # args.outputs.primitives << args.layout.debug_primitives
    state.game.send "#{state.scene}_tick"
  end

end

def tick args
  args.state.m = Main.new args
  args.state.m.tick
end
