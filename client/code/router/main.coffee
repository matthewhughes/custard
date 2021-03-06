class Cu.Router.Main extends Backbone.Router
  tools: ->
    Cu.CollectionManager.get Cu.Collection.Tools

  datasets: ->
    Cu.CollectionManager.get Cu.Collection.Datasets

  initialize: ->
    @appView = new Cu.AppView '#content'
    @subnavView = new Cu.AppView '#subnav'
    @overlayView = new Cu.AppView '#overlay'
    @navView ?= new Cu.View.Nav()

    # Move somewhere better
    $('#logo').click ->
      event.preventDefault()
      window.app.navigate "/", {trigger: true}

    # TODO: this isn't a great place for this constant
    window.latestTerms = 1
    
    if window.user?.real
      if isNaN(window.user.real.acceptedTerms) or window.user.real.acceptedTerms < window.latestTerms
        @termsAlertView = new Cu.View.TermsAlert
        $("#header").after @termsAlertView.render().el

    # Backbone seems to reverse route order
    # TODO: revert to standard routes?
    @route RegExp('.*'), 'fourOhFour'
    @route RegExp('^/?$'), 'main'
    @route RegExp('(?:docs|help)/?'), 'help'
    @route RegExp('(?:docs|help)/([^/]+)/?'), 'help'
    @route RegExp('pricing/?'), 'pricing'
    @route RegExp('pricing/([^/]+)/?'), 'pricing'
    @route RegExp('tools/?'), 'toolShop'
    @route RegExp('chooser/?'), 'toolChooser'
    @route RegExp('tools/people-pack/?'), 'peoplePack'
    @route RegExp('dataset/([^/]+)/?'), 'dataset'
    @route RegExp('dataset/([^/]+)/settings/?'), 'datasetSettings'
    @route RegExp('dataset/([^/]+)/chooser/?'), 'datasetToolChooser'
    @route RegExp('dataset/([^/]+)/view/([^/]+)/?'), 'view'
    @route RegExp('create-profile/?'), 'createProfile'
    @route RegExp('set-password/([^/]+)/?'), 'setPassword'
    @route RegExp('signup/([^/]+)/?'), 'signUp'
    @route RegExp('subscribe/([^/]+)/?'), 'subscribe'
    @route RegExp('terms/?'), 'terms'
    @route RegExp('terms/enterprise-agreement/?'), 'termsEnterpriseAgreement'

  main: ->
    if window.user.effective?
      @homeLoggedIn()
    else
      @homeAnonymous()

  homeAnonymous: ->
    contentView = new Cu.View.Home
    @appView.showView contentView
    @subnavView.hideView()

  homeLoggedIn: ->
    contentView = new Cu.View.DatasetList
    subnavView = new Cu.View.DataHubNav
    @appView.showView contentView
    @subnavView.showView subnavView

  pricing: (upgrade) ->
    subnavView = new Cu.View.Subnav {text: 'Pricing'}
    contentView = new Cu.View.Pricing upgrade: upgrade
    @appView.showView contentView
    @subnavView.showView subnavView

  signUp: (plan) ->
    contentView = new Cu.View.SignUp {plan: plan}
    subnavView = new Cu.View.SignUpNav {plan: plan}
    @appView.showView contentView
    @subnavView.showView subnavView

  toolChooser: ->
    chooserView = new Cu.View.ToolList {type: 'importers'}
    @overlayView.showView chooserView

  datasetToolChooser: (box) ->
    model = Cu.Model.Dataset.findOrCreate box: box
    model.fetch
      success: =>
        chooserView = new Cu.View.ToolList
          type: 'nonimporters'
          dataset: model
        @overlayView.showView chooserView

  subscribe: (plan) ->
    # TODO: make this a backbone model
    # TODO: handle unknown plan in sign api?
    shortName = window.user.effective.shortName
    $.ajax
      type: 'GET'
      url: "/api/#{shortName}/subscription/#{plan}/sign"
      success: (signature) =>
        contentView = new Cu.View.Subscribe {plan: plan, signature: signature}
        subnavView = new Cu.View.SignUpNav {plan: plan}
        @appView.showView contentView
        @subnavView.showView subnavView

  dataset: (box) ->
    doNotNavigate = false
    render = (dataTablesView) =>
        subnavView = new Cu.View.DatasetNav {model: model, view: dataTablesView}
        @subnavView.showView subnavView
        contentView = new Cu.View.PluginContent {model: dataTablesView}
        @appView.showView contentView
        contentView.showContent()
        doNotNavigate = false

    model = Cu.Model.Dataset.findOrCreate box: box, merge: true
    toolsDone = app.tools().fetch()
    modelDone = model.fetch()
    $.when.apply( null, [modelDone, toolsDone] ).done =>
      views = model.get 'views'
      subnavView = new Cu.View.DatasetNav {model: model}
      @subnavView.showView subnavView

      setTimeout =>
        views.findByToolName 'datatables-view-tool', (dataTablesView) =>
          if dataTablesView?
            render dataTablesView
          else
            app.navigate "/dataset/#{model.id}/settings", trigger: true
      , 0

  datasetSettings: (box) ->
    mod = Cu.Model.Dataset.findOrCreate box: box
    mod.fetch
      success: (model) =>
        subnavView = new Cu.View.DatasetNav model: model
        contentView = new Cu.View.AppContent model: model
        @appView.showView contentView
        @subnavView.showView subnavView
        contentView.showContent()
      error: (x,y,z) ->
        # TODO: factor into function
        contentView = new Cu.View.Error title: "Sorry, we couldn't find that dataset.", message: "Are you sure you're logged into the right account?"
        subnavView = new Cu.View.Subnav text: "Dataset not found"
        @appView.showView contentView
        @subnavView.showView subnavView

  view: (datasetID, viewID) ->
    dataset = Cu.Model.Dataset.findOrCreate
      user: window.user.effective.shortName
      box: datasetID

    dataset.fetch
      success: (dataset, resp, options) =>
        v = dataset.get('views').findById(viewID)
        contentView = new Cu.View.PluginContent model: v
        subnavView = new Cu.View.DatasetNav model: dataset, view: v
        @appView.showView contentView
        @subnavView.showView subnavView
        contentView.showContent()
      error: (model, xhr, options) ->
        console.warn xhr

  toolShop: ->
    app.navigate '/tools/people-pack/', true

  peoplePack: ->
    subnavView = new Cu.View.ToolShopNav {name: 'People Pack', url: '/tools/people-pack'}
    contentView = new Cu.View.PeoplePack()
    @appView.showView contentView
    @subnavView.showView subnavView

  createProfile: ->
    subnavView = new Cu.View.Subnav {text: 'Create Profile'}
    contentView = new Cu.View.CreateProfile()
    @appView.showView contentView
    @subnavView.showView subnavView

  setPassword: ->
    subnavView = new Cu.View.Subnav {text: 'Set your password'}
    contentView = new Cu.View.SetPassword()
    @appView.showView contentView
    @subnavView.showView subnavView

  fourOhFour: ->
    subnavView = new Cu.View.Subnav {text: '404: Not Found'}
    contentView = new Cu.View.FourOhFour()
    @appView.showView contentView
    @subnavView.showView subnavView

  help: (section) ->
    section ?= 'home'
    subnavView = new Cu.View.HelpNav {section: section}
    contentView = new Cu.View.Help {template: "help-#{section}"}
    @appView.showView contentView
    @subnavView.showView subnavView

  terms: ->
    subnavView = new Cu.View.Subnav {text: 'Terms & Conditions'}
    contentView = new Cu.View.Terms()
    @appView.showView contentView
    @subnavView.showView subnavView

  termsEnterpriseAgreement: ->
    subnavView = new Cu.View.Subnav {text: 'ScraperWiki Enterprise Agreement'}
    contentView = new Cu.View.TermsEnterpriseAgreement()
    @appView.showView contentView
    @subnavView.showView subnavView


