class Cu.View.ToolContent extends Backbone.View
  id: 'fullscreen'

  initialize: ->
    boxUrl = window.boxServer
    @model.publishToken (token) =>
      obj =
        source:
          apikey: window.user.effective.apiKey
          url: "#{boxUrl}/#{@model.get 'box'}/#{token}"

      frag = encodeURIComponent JSON.stringify(obj)
      @setupEasyXdm "#{boxUrl}/#{@model.get 'box'}/#{token}/http/container.html##{frag}"
  
  setupEasyXdm: (url) ->
    # Box acgjtgi for dev
    transport = new easyXDM.Socket
     remote: url
     container: 'fullscreen'
     onReady: ->
       transport.postMessage 'Hello from custard!'
     onMessage: (message, origin) ->
       transport.postMessage "This is a message received from #{location}"

