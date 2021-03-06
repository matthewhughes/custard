should = require 'should'
{wd40, browser, login_url, home_url, prepIntegration} = require './helper'

describe 'Dataset', ->
  prepIntegration()

  randomname = "New favourite number is #{Math.random()}"

  before (done) ->
    wd40.fill '#username', 'ehg', ->
      wd40.fill '#password', 'testing', -> wd40.click '#login', done
  context 'when I click on an Apricot dataset', ->
    before (done) ->
      # wait for tiles to fade in
      setTimeout ->
        wd40.elementByPartialLinkText 'Apricot', (err, link) ->
          link.click done
      , 500

    it 'takes me to the Apricot dataset page', (done) ->
      wd40.trueURL (err, result) ->
        result.should.match /\/dataset\/(\w+)/
        done()

    it 'shows this dataset was made by the Test App tool', (done) ->
      wd40.elementByPartialLinkText 'Test app', (err, link) ->
        should.exist link
        done()

    it 'has not shown the input box', (done) ->
      wd40.elementByCss '#editable-input', (err, input) ->
        browser.isVisible input, (err, visible) ->
          visible.should.be.false
          done()

    context 'when I hover over the Test App tool name', (done) ->
      before (done) ->
        setTimeout done, 500

      before (done) ->
        wd40.elementByCss '#dataset-tools-toggle', (err, link) ->
          browser.moveTo link, (err) ->
            done()

      it 'more tools appear in a pop-up menu', (done) ->
        browser.isVisible 'css selector', '#dataset-tools', (err, visible) =>
          visible.should.be.true
          wd40.getText '#dataset-tools', (err, text) =>
            @dropdownText = text
            done()

      it '...including the tool that made this dataset', ->
        @dropdownText.should.include 'Test app'

      it '...the view in a table tool', ->
        @dropdownText.should.include 'View in a table'

      it '...the spreadsheet download tool', ->
        @dropdownText.should.include 'Download as spreadsheet'

      it '...(only once)', ->
        @dropdownText.match(/Download as spreadsheet/g).length.should.equal 1

      it '...and a button to pick more tools', ->
        @dropdownText.toLowerCase().should.include 'more tools'

    context 'when I click the title', ->
      before (done) ->
        browser.elementByCssIfExists '#editable-input', (err, wrapper) =>
          @wrapper = wrapper
          browser.elementByCssIfExists '#editable-input input', (err, input) =>
            @input = input
            browser.elementByCssIfExists '#subnav-path .editable', (err, a) =>
              @a = a
              wd40.click '#subnav-path .editable', done

      it 'an input box appears', (done) ->
        should.exist @input
        should.exist @wrapper
        browser.isVisible @wrapper, (err, visible) ->
          visible.should.be.true
          done()

      context 'when I fill in the input box and press enter', ->
        before (done) ->
          @input.clear (err) =>
            browser.type @input, randomname + '\n', ->
              done()

        it 'hides the input box and shows the new title', (done) =>
          browser.waitForVisibleByCss '#subnav-path .editable', 4000, (err) =>
            browser.isVisible 'css selector', '#editable-input', (err, inputVisible) ->
              inputVisible.should.be.false
              done()

        it 'has updated the title', (done) ->
          wd40.getText '#subnav-path .editable', (err, text) ->
            text.should.equal randomname
            done()

      context 'when I go back home', ->
        before (done) ->
          browser.elementByCss '#subnav-path a[href="/"]', (err, link) ->
            link.click done

        # wait for animation :(
        before (done) ->
          setTimeout done, 500

        it 'should display the home page', (done) ->
          browser.url (err, url) ->
            url.should.match /\/$/
            done()

        it 'should show the new dataset new name', (done) ->
          text = wd40.getText 'body', (err, text) ->
            text.should.include randomname
            done()

        context 'when I click the "hide" button on the dataset', ->
          before (done) ->
            browser.elementByPartialLinkText randomname, (err, dataset) =>
              @dataset = dataset
              browser.moveTo @dataset, =>
                @dataset.elementByCss '.hide', (err, hide) ->
                  hide.click done

          it 'the dataset disappears from the homepage immediately', (done) ->
            # TODO: write a waitForInvisible function
            setTimeout =>
              @dataset.isVisible (err, visible) ->
                visible.should.be.false
                done()
            , 400

          context 'when I revisit the homepage', ->
            before (done) ->
              browser.refresh done

            it 'the dataset stays hidden', (done) ->
              wd40.getText 'body', (err, text) ->
                text.should.not.include randomname
                done()
