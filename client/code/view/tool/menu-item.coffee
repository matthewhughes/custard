# This should be passed a dataset/view model, not a tool archetype model
class Cu.View.ToolMenuItem extends Backbone.View
  tagName: 'li'
  events:
    'click .hide': 'hideTool'
    'click .ssh-in': (event) ->
      event.preventDefault()
      event.stopPropagation()
      if @model instanceof Cu.Model.Dataset
        Cu.Helpers.showOrAddSSH @model.get('box'), @model.get('displayName'), 'dataset'
      else if @model instanceof Cu.Model.View
        Cu.Helpers.showOrAddSSH @model.get('box'), @model.get('displayName'), 'view'

  hideTool: (e) ->
    e.preventDefault()
    e.stopPropagation()
    if @model instanceof Cu.Model.View
      $('.hide', @$el).hide 0, =>
        @$el.slideUp =>
          @model.set 'state', 'deleted'
          @model.get('plugsInTo').save {},
            error: (e) =>
              @$el.slideDown()
              console.warn 'View could not be deleted!'

  initialize: ->
    @model.on 'change', @render, this

  render: ->
    hideable = true
    toolName = @model.get('tool').get('name')

    if @model instanceof Cu.Model.Dataset
      href = "/dataset/#{@model.get 'box'}/settings"
      hideable = false
    else
      href = "/dataset/#{@model.get('plugsInTo').get('box')}/view/#{@model.get 'box'}"

    if toolName is "datatables-view-tool"
      hideable = false

    html = JST['tool-menu-item']
      manifest: @model.get('tool').get('manifest')
      href: href
      id: "instance-#{@model.get 'box'}"
      hideable: hideable
      toolName: toolName
    @$el.html html
    @

# This should be passed a tool archetype model, not a dataset/view model
class Cu.View.ArchetypeMenuItem extends Backbone.View
  tagName: 'li'

  initialize: ->
    @options.archetype.on 'change', @render, this

  events:
    'click a': 'clicked'

  render: ->
    if app.tools().length
      html = JST['tool-menu-item']
        manifest: @options.archetype.get 'manifest'
      @$el.html html
    @

  showLoading: ->
    $inner = @$el.find('.tool-icon-inner')
    $inner.empty().css('background-image', 'none')
    Spinners.create($inner, {
      radius: 7,
      height: 8,
      width: 2.5,
      dashes: 12,
      opacity: 1,
      padding: 3,
      rotation: 1000,
      color: '#fff'
    }).play()

  clicked: (e) ->
    e.stopPropagation()
    @install(e) unless @active

  # Copied from client/code/view/tool/tile.coffee
  install: (e) ->
    e.preventDefault()
    @active = true
    $('#content').html """<p class="loading">Installing tool&hellip;</p>"""

    dataset = Cu.Model.Dataset.findOrCreate
      user: window.user.effective.shortName
      box: @options.dataset.id

    dataset.fetch
      success: (dataset, resp, options) =>
        dataset.installPlugin @options.archetype.get('name'), (err, view) =>
          console.warn 'Error', err if err?
          window.app.navigate "/dataset/#{dataset.id}/view/#{view.id}", trigger: true
      error: (model, xhr, options) ->
        @active = false
        console.warn xhr
