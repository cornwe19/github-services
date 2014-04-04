class Service::GroupMe < Service
  string :bot_id

  def receive_push
    http.url_prefix = "https://api.groupme.com/v3/bots/"

    payload['commits'].size
    message = "%s pushed %d commits to %s - %s" % [
      payload['pusher']['name'],
      payload['commits'].size,
      payload['repository']['name'],
      payload['compare']
    ]

    http_post "post", { "bot_id" => data['bot_id'], "text" => message }.to_json
  end

end
