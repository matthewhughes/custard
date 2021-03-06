class Cu.View.Subnav extends Backbone.View
  className: 'subnav-wrapper'

  render: ->
    @$el.html("""
      <div class="btn-toolbar" id="subnav-path">
        <h1 class="btn-group">
          <a class="btn btn-link" href="#{@options.url or window.location.href}">#{@options.text}</a>
        </h1>
      </div>
      <hr>""")
    @

  # THIS IS NOT USED
  # TODO: actually inherit >:/
  setDocumentTitle: (model) =>
    if model?
      t = "#{model.get 'displayName'} | "
    else if @options.text
      t = "#{@options.text} | "
    else
      t = ''
    window.document.title = """#{t}ScraperWiki"""


class Cu.View.DataHubNav extends Backbone.View
  className: 'subnav-wrapper'

  events:
    'click .context-switch li': 'liClick'
    'click .new-dataset': 'showChooser'
    'focus .context-switch input': 'focusContextSearch'
    'keyup .context-switch input': 'keyupContextSearch'
    'mouseenter .context-search-result': 'hoverContextSearchResult'
    'keyup #subnav-options .search-query': 'keyupPageSearch'

  render: ->
    h1 = """<h1 class="btn-group context-switch">
        <a class="btn btn-link dropdown-toggle" data-toggle="dropdown">
          <img src="#{window.user.effective.logoUrl or window.user.effective.avatarUrl}" />#{window.user.effective.displayName or window.user.effective.shortName}&rsquo;s data hub<span class="caret"></span>
        </a>
        <ul id="user-contexts" class="dropdown-menu">
        </ul>
      </h1>"""

    @$el.html("""
      <div class="btn-toolbar" id="subnav-path">#{h1}</div>
      <div class="btn-toolbar" id="subnav-options">
        <div class="btn-group">
          <a class="btn new-dataset"><i class="icon-plus"></i> New Dataset</a>
        </div>
        <div class="btn-group">
          <input type="text" class="input-medium search-query">
        </div>
      </div>""")

    @displayContexts()

    # close the tool chooser if it's open
    # (ie: if we've just used the back button to close it)
    if $('#chooser').length
      $('#chooser').fadeOut 200, ->
        $(this).remove()
      $(window).off('keyup')
    @

  displayContexts: ->
    $userContexts = $('#user-contexts').empty()
    return if $userContexts.is(':visible')

    users = Cu.CollectionManager.get Cu.Collection.User
    users.fetch
      success: =>
        if users.length <= 1
          $('.context-switch > a').attr('data-toggle', null)
           .removeClass('dropdown-toggle', null)
           .css('cursor', 'default')
           .children('span').remove()
        users.each @appendContextUser

  appendContextUser: (user) ->
    $userContexts = $('#user-contexts')
    $userContexts.append """<li class="context-search-result">
      <a href="/switch/#{user.get 'shortName'}/" data-nonpushstate>
        <img src="#{user.get('logoUrl') or user.get('avatarUrl') or '/image/avatar.png'}" alt="#{user.get 'shortName'}" />
        #{user.get 'displayName' or user.get 'shortName'}
      </a>
    </li>"""

  liClick: (e) ->
    # stops the dropdown menu disappearing when you click inside it
    e.stopPropagation()

  showChooser: ->
    app.navigate "/chooser", trigger: true

  # TODO: should use user collection
  focusContextSearch: ->
    $.ajax
      url: '/api/user/'
      dataType: 'json'
      success: (latestUsers) ->
        window.users = for user in latestUsers
          user
        if $('.context-switch input').is('.loading')
          $('.context-switch input').removeClass('loading').trigger 'keyup'
      error: (jqXHR, textStatus, errorThrown) ->
        $('.context-switch input').removeClass 'loading'
        console.warn 'Could not query users API', errorThrown

  keyupContextSearch: (e) ->
    if e.which == 40
      e.preventDefault()
      @highlightNextResult()
    else if e.which == 38
      e.preventDefault()
      @highlightPreviousResult()
    else if e.which == 13
      e.preventDefault()
      @activateHighlightedResult()
    else
      @refreshContextResults()

  refreshContextResults: ->
    li = $('.context-switch li.search')
    input = li.children('input')
    t = input.val()
    results = $('.context-search-result')
    if t != ''
      results.remove()
      tophits = []
      runnersup = []
      if window.users?
        for user in window.users
          if user.shortName == window.user.effective.shortName
            continue
          m1 = if user.displayName? then user.displayName.toLowerCase().search(t.toLowerCase()) else -1
          m2 = if user.shortName? then user.shortName.toLowerCase().search(t.toLowerCase()) else -1
          if m1 == 0 or m2 == 0
            tophits.push user
          else if m1 > 0 or m2 > 0
            runnersup.push user
        if runnersup.length + tophits.length > 0
          for runnerup in runnersup
            li.after """<li class="context-search-result">
              <a href="/switch/#{runnerup.shortName}/" data-nonpushstate>
                <img src="#{runnerup.logoUrl or runnerup.avatarUrl or '/image/avatar.png'}" alt="#{runnerup.shortName}" />
                #{runnerup.displayName or runnerup.shortName}
              </a>
            </li>"""
          for tophit in tophits
            li.after """<li class="context-search-result">
              <a href="/switch/#{tophit.shortName}/" data-nonpushstate>
                <img src="#{tophit.logoUrl or tophit.avatarUrl or '/image/avatar.png'}" alt="#{tophit.shortName}" />
                #{tophit.displayName or tophit.shortName}
              </a>
            </li>"""
        else
          # No users match the search term!
          li.after """<li class="context-search-result no-matches">No results for &ldquo;#{t}&rdquo;</li>"""
      else
        # Oops! window.users isn't ready yet. Show loading spinner.
        # (It'll be hidden by the ajax success call in @focusContextSearch())
        $('.context-switch input').addClass 'loading'
    else if t == ''
      results.remove()

  highlightNextResult: ->
    $selected = $('.context-search-result.selected')
    if $selected.length
      if $selected.next('.context-search-result').length
        $selected.removeClass('selected').next('.context-search-result').addClass('selected')
    else
      $('.context-search-result').first().addClass('selected')

  highlightPreviousResult: ->
    $selected = $('.context-search-result.selected')
    if $selected.length
      if $selected.prev('.context-search-result').length
        $selected.removeClass('selected').prev('.context-search-result').addClass('selected')
    else
      $('.context-search-result').last().addClass('selected')

  activateHighlightedResult: ->
    $results = $('.context-search-result')
    $selected = $('.context-search-result.selected')
    if $selected.length
      window.location = $('a', $selected).attr('href')
    else if $results.length == 1
      $first = $results.first().addClass('selected')
      window.location = $('a', $first).attr('href')
    else
      @highlightNextResult()

  hoverContextSearchResult: ->
    $('.context-search-result.selected').removeClass('selected')

  keyupPageSearch: (e) ->
    $input = $(e.target)
    if e.keyCode is 27
      $('.dataset.tile').show()
      $input.val('').blur()
    else
      t = $input.val()
      if t != ''
        $('.dataset.tile').each ->
          if $(this).children('h3').text().toUpperCase().indexOf(t.toUpperCase()) >= 0
            $(this).show()
          else
            $(this).hide()
      else if t == ''
        $('.dataset.tile').show()


class Cu.View.EditableSubnav extends Backbone.View
  className: 'subnav-wrapper'

  initialize: ->
    @model.on 'change', @setDocumentTitle, @
    @model.on 'change', @render, this
    # set this so we can override it in Cu.View.ViewNav
    # (where the model to save is in fact the parent dataset's model)
    @modelToSave = @model

  nameClicked: (e) ->
    e.preventDefault()
    $a = @$el.find('.editable')
    $a.next().show(0, ->
      $(@).children('input').focus()
    ).children('input').val(@model.get 'displayName').css('width', $a.width() + 30)
    $a.hide()

  editableNameBlurred: ->
    $label = @$el.find('.editable')
    $wrapper = $label.next()
    $input = $wrapper.children('input')
    @newName = $.trim($input.val())
    @oldName = $label.text()
    if @newName == '' or @newName == $label.text()
      $label.show()
      $wrapper.hide()
    else
      $wrapper.hide()
      $label.text(@newName).show()
      @model.set 'displayName', @newName
      @modelToSave.save {},
        success: =>
          $label.addClass 'saved'
          setTimeout ->
            $label.removeClass 'saved'
          , 1000
        error: (e) =>
          $label.text(@oldName).addClass 'error'
          setTimeout ->
            $label.removeClass 'error'
          , 1000
          @model.set 'displayName', @oldName
          console.warn 'error saving new name', e

  editableNameEscaped: (e) ->
    e.preventDefault()
    @$el.find('.editable').show().next().hide().children('input').val('')

  keypressOnEditableName: (e) ->
    @editableNameBlurred(e) if e.keyCode is 13
    @editableNameEscaped(e) if e.keyCode is 27


class Cu.View.DatasetNav extends Cu.View.EditableSubnav
  className: 'subnav-wrapper'

  events:
    'click .editable': 'nameClicked'
    'click .new-view': 'showChooser'
    'blur #editable-input input': 'editableNameBlurred'
    'keyup #editable-input input': 'keypressOnEditableName'

  initialize: ->
    super()
    @model.on 'update:tool', @render, @
    @toolsView = new Cu.View.DatasetTools
      model: @model
      view: @options.view

  showChooser: ->
    app.navigate "/dataset/#{@model.get 'box'}/chooser", trigger: true

  close: ->
    @toolsView?.close()
    super()

  render: ->
    @$el.html("""
      <div class="btn-toolbar" id="subnav-path">
        <div class="btn-group">
          <a class="btn btn-link" href="/">
            <img src="#{window.user.effective.logoUrl or window.user.effective.avatarUrl}" />
            <span class="datahub-name">#{window.user.effective.displayName or window.user.effective.shortName}&rsquo;s data hub</span>
          </a>
        </div>
        <div class="btn-group">
          <span class="slash">/</span>
        </div>
        <div class="btn-group">
          <span class="btn btn-link editable">#{@model.get 'displayName'}</span>
          <span class="input-append" id="editable-input">
            <input type="text">
            <button class="btn">Save</button>
          </span>
        </div>
      </div>
      <div class="btn-toolbar" id="subnav-options">
        <div class="btn-group">
          <a class="btn btn-link" id="dataset-tools-toggle"></a>
        </div>
      </div>""")
    setTimeout =>
      if tool is null
        return @
      @$el.find('#dataset-tools-toggle').after(@toolsView.render().el)
      if @options?.view
        tool = @options.view.get 'tool'
      else
        tool = @model.get 'tool'

      currentToolManifest = tool.get 'manifest'
      toggleHtml = JST['tool-menu-toggle']
        manifest: currentToolManifest
      @$el.find('#dataset-tools-toggle').html toggleHtml
    , 0
    @

class Cu.View.SignUpNav extends Backbone.View
  className: 'subnav-wrapper'

  render: ->
    # Assumes @options.plan is set
    plan = @options.plan
    plan = plan.toUpperCase()[0] + plan.toLowerCase()[1..]

    @$el.html("""
      <div class="btn-toolbar" id="subnav-path">
        <h1 class="btn-group">
          <a class="btn btn-link" href="/">Sign Up</a>
        </h1>
        <div class="btn-group">
          <span class="slash">/</span>
        </div>
        <h1 class="btn-group" style="margin-left: 7px">
          <a class="btn btn-link" href="#{window.location.href}">#{plan}</a>
        </h1>
      </div>
      <hr>""")
    @

class Cu.View.HelpNav extends Backbone.View
  className: 'subnav-wrapper'

  render: ->
    switch @options.section
      when 'corporate'
        name = 'Corporate FAQs'
      when 'developer'
        name = 'Developer Docs'
      when 'zig'
        name = 'ZIG'
      when 'twitter-search'
        name = 'Scrape Tweets and download as a spreadsheet'
      when 'upload-and-summarise'
        name = 'Upload and summarise a spreadsheet of data'
      when 'code-in-your-browser'
        name = 'Code a scraper in your browser'
      when 'make-your-own-tool'
        name = 'Make your own tool with HTML, JavaScript & Python'
      when 'whats-new'
        name = 'What’s new?'

    html = """
      <div class="btn-toolbar" id="subnav-path">
        <h1 class="btn-group">
          <a class="btn btn-link" href="/help">Help</a>
        </h1>"""

    if name
      html += """<div class="btn-group">
          <span class="slash">/</span>
        </div>
        <h1 class="btn-group" style="margin-left: 7px">
          <a class="btn btn-link">#{name}</a>
        </h1>"""

    html += "</div><hr>"

    @$el.html html
    @

class Cu.View.ToolShopNav extends Backbone.View
  className: 'subnav-wrapper'

  render: ->
    @$el.html("""
      <div class="btn-toolbar" id="subnav-path">
        <h1 class="btn-group">
          <a class="btn btn-link" href="/tools">Tool Shop</a>
        </h1>
        <div class="btn-group">
          <span class="slash">/</span>
        </div>
        <h1 class="btn-group" style="margin-left: 7px">
          <a class="btn btn-link" href="#{@options.url}">#{@options.name}</a>
        </h1>
      </div>
      <hr>""")
    @
