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


  if args.inputs.controller_one.left_analog_active? threshold_perc: dead_zone
    args.state.player_rect.x += args.inputs.controller_one.left_analog_x_perc * speed
    args.state.player_rect.y += args.inputs.controller_one.left_analog_y_perc * speed
  else
    if args.inputs.left
      args.state.player_rect.x -= speed
    elsif args.inputs.right
      args.state.player_rect.x += speed
    end

    if args.inputs.down
      args.state.player_rect.y -= speed
    elsif args.inputs.up
      args.state.player_rect.y += speed
    end
  end

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
  if args.state.player_rect.x +  player_w > args.grid.w
    args.state.player_rect.x = args.grid.w - player_w
  end

  if args.state.player_rect.x < 0
    args.state.player_rect.x = 0
  end

  if args.state.player_rect.y + player_h > args.grid.h
    args.state.player_rect.y = args.grid.h - player_h
  end

  if args.state.player_rect.y < 0
    args.state.player_rect.y = 0
  end

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
