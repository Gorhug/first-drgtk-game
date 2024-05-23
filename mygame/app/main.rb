def tick args
  args.state.player_rect ||= { x: 576,
                             y: 200,
                             w: 100,
                             h: 80,
                            #  path: 'sprites/misc/dragon-0.png',
                            speed: 24, }
  args.state.fireballs ||= []
  speed = args.state.player_rect.speed
  player_sprite_index = 0.frame_index count: 6, hold_for: 8, repeat: true
  args.state.player_rect.path = "sprites/misc/dragon-#{player_sprite_index}.png"
  dead_zone = 0.10
  # args.outputs.labels  << { x: 640,
  #                           y: 600,
  #                           text: 'Hello World!',
  #                           size_px: 30,
  #                           anchor_x: 0.5,
  #                           anchor_y: 0.5 }

  x_movement = 0
  y_movement = 0
  if args.inputs.controller_one.left_analog_active? threshold_perc: dead_zone
    x_movement = args.inputs.controller_one.left_analog_x_perc * speed
    y_movement = args.inputs.controller_one.left_analog_y_perc * speed
  else

    if args.inputs.left
      x_movement = -speed
    elsif args.inputs.right
      x_movement = speed
    end

    if args.inputs.down
      y_movement = -speed
    elsif args.inputs.up
      y_movement = speed
    end
  end

  total_movement = x_movement.abs + y_movement.abs
  if total_movement > speed
    x_movement = x_movement / (total_movement / speed)
    y_movement = y_movement / (total_movement / speed)
  end
  args.state.player_rect.x += x_movement
  args.state.player_rect.y += y_movement

  ## wraparound
  # if args.state.player_rect.x > 1280
  #   args.state.player_rect.x = 0
  # elsif args.state.player_rect.x < 0
  #   args.state.player_rect.x = 1280
  # end

  # if args.state.player_rect.y > 720
  #   args.state.player_rect.y = 0
  # elsif args.state.player_rect.y < 0
  #   args.state.player_rect.y = 720
  # end

  ## bound to screen
  player_w = args.state.player_rect.w
  player_h = args.state.player_rect.h

  args.state.player_rect.x = args.state.player_rect.x.clamp 0, args.grid.w - player_w
  args.state.player_rect.y = args.state.player_rect.y.clamp 0, args.grid.h - player_h

  if args.inputs.keyboard.key_down.z ||
      args.inputs.keyboard.key_down.j ||
      args.inputs.controller_one.key_down.a
    args.state.fireballs << {
      x: args.state.player_rect.x,
      y: args.state.player_rect.y,
      text: 'fireball'
    }
  end

  args.state.fireballs.each do |fireball|
    fireball.x += speed + 2
    if fireball.x > args.grid.w
      fireball.dead = true
      next
    end
  end
  args.state.fireballs.reject! { |fireball| fireball.dead }
  #args.gtk.notify! "Fireballs: #{args.state.fireballs.length}"
  args.outputs.labels << args.state.fireballs

  args.outputs.sprites << args.state.player_rect
end
