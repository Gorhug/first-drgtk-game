def tick args
  args.state.player_rect ||= { x: 576,
                             y: 200,
                             w: 100,
                             h: 80 }
  speed = 25
  dead_zone = 0.10
  # args.outputs.labels  << { x: 640,
  #                           y: 600,
  #                           text: 'Hello World!',
  #                           size_px: 30,
  #                           anchor_x: 0.5,
  #                           anchor_y: 0.5 }



  args.outputs.sprites << { x: args.state.player_rect.x,
                            y: args.state.player_rect.y,
                            w: args.state.player_rect.w,
                            h: args.state.player_rect.h,
                            path: 'sprites/misc/dragon-0.png',
                            # angle: args.state.tick_count
                          }



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

  # wraparound
  if args.state.player_rect.x > 1280
    args.state.player_rect.x = 0
  elsif args.state.player_rect.x < 0
    args.state.player_rect.x = 1280
  end

  if args.state.player_rect.y > 720
    args.state.player_rect.y = 0
  elsif args.state.player_rect.y < 0
    args.state.player_rect.y = 720
  end
end
