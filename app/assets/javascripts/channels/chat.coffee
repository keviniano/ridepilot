App.chats ||= App.chats || {}

@create_chat_channel = (provider_id, driver_id, new_message_callback) ->
  App.chats[[provider_id, driver_id]] = App.cable.subscriptions.create {
      channel: "ChatChannel",
      provider_id: provider_id,
      driver_id: driver_id
    },
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      if new_message_callback
        new_message_callback(data.id)

    create: (message) ->
      @perform 'create', body: message, driver_id: driver_id