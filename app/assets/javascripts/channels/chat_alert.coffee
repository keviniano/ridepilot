show_chat_alert_dialog = () ->
  console.log "chat_alert"

App.chat_alerts ||= App.chat_alerts || {}

@create_chat_alert_channel = (run_id, callback) ->
  if App.chat_alerts[run_id]
    return

  console.log run_id

  App.chat_alerts[run_id] = App.cable.subscriptions.create {
      channel: "ChatAlertChannel",
      run_id: run_id
    },
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      # Called when there's incoming data on the websocket for this channel
      callback(data);

  