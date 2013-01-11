class Cu.View.ToolContent extends Backbone.View

  initialize: ->
    Backbone.once 'tool:installed', @onInstalled, this

  render: ->
    @$el.html """<p class="loading">Loading tool</p>"""
    @model.install (ajaxObj, status) =>
      if status == 'success'
        @model.setup (buffer) =>
          @$el.html buffer.toString()
      else
        $('p.loading').text "Error: #{status}"

   onInstalled: ->
     user = window.user.effective
     console.log 'B4', window.datasets
     dataset = new Cu.Model.Dataset
       user: user.shortName
       name: @model.get 'name'
       displayName: @model.get 'name'
       box: @model.get 'boxName'

     dataset.new = true

     dataset.save {},
       wait: true
       success: ->
         console.log 'AFTER', window.datasets
         delete dataset.new
         window.app.navigate "/dataset/#{dataset.id}", {trigger: true}
       error: (model, xhr, options) ->
         console.log "Error saving dataset (xhr status: #{xhr.status} #{xhr.statusText})"
