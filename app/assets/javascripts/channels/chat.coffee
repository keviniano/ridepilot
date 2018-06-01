App.chats ||= App.chats || {}

@create_chat_channel = (provider_id, driver_id) ->
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
      # TODO: show new message
      console.log(data.message);

    create: (message) ->
      @perform 'create', body: message, driver_id: driver_id