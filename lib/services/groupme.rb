class Service::GroupMe < Service
  string :bot_id

  def receive_push
    raise_config_error "Requires a bot id" if data['bot_id'].to_s.empty?

    http.url_prefix = "https://api.groupme.com/v3/bots/"

    payload['commits'].size
    message = "%s pushed %d commits to %s/%s - %s" % [
      payload['pusher']['name'],
      payload['commits'].size,
      payload['repository']['name'],
      payload['ref'].gsub!('refs/heads/', ''),
      shorten_url( payload['compare'] )
    ]

    commits = payload['commits']
    for i in 0...[3,commits.size].min
      message += '%s - %s' % [newline, truncate(commits[i]['message'])]
    end

    http_post "post", { "bot_id" => data['bot_id'], "text" => message }.to_json
  end

  def truncate msg
    if msg.size > 50
      msg[0...47] + "..."
    else
      msg
    end
  end

  def newline
    [0x0A].pack('c*')
  end

end
