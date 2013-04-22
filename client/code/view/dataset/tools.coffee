class Cu.View.DatasetTools extends Backbone.View
  className: 'dropdown-menu pull-right'
  tagName: 'div'
  id: 'dataset-tools'

  initialize: ->
    if @options.view?
      @selectedTool = @options.view
    else
      @selectedTool = @model

    @toolInstances = @model.get('views').visible()
    app.tools().on 'add', @addToolArchetype, @
    @model.on 'relational:change:tool', @addToolInstance, @
    @model.on 'all', (e) ->
      console.log e
    @model.get('views').on 'change:tool', @addToolInstance, @

  render: ->
    @$el.html """<ul class="tools"></ul>
      <ul class="archetypes"></ul>
      <ul class="more">
        <li><a class="new-view">More tools&hellip;</a></li>
      </ul>"""
    @addToolInstance @model
    views = @model.get('views').visible()
    views.each (view) =>
      @addToolInstance view
    app.tools().each (archetype) =>
      @addToolArchetype archetype
    @

  addToolArchetype: (toolModel) ->
    # The setTimeout thing is because we can't work out Backbone (Relational) model loading:
    # without the setTimeout, instance.get('tool') is undefined.
    setTimeout =>
      console.log toolModel
      if toolModel.isBasic()
        item = $("[data-toolname=#{toolModel.get 'name'}]", @$el)
        if item.length > 0
          return
        v = new Cu.View.ArchetypeMenuItem { archetype: toolModel, dataset: @model }
        $('.archetypes', @$el).append v.render().el
    , 0

  addToolInstance: (instance, b, c) ->
    console.log b,c
    id = "instance-#{instance.get 'box'}"
    l = $("##{id}", @$el)
    if not instance.isVisible()
      # Don't show "hidden" tool instances
      return
    if l.length > 0
      # Already added as a menu item; don't add again.
      return
    if not instance.get 'tool'
      # Tool relation not loaded yet, so we don't know what to display.
      return
    v = new Cu.View.ToolMenuItem model: instance
    el = v.render().el
    $('a', el).addClass('active') if instance is @selectedTool

    if instance instanceof Cu.Model.Dataset
      # So that the tool that imported is at the top.
      $('.tools', @$el).prepend el
    else
      $('.tools', @$el).append el
