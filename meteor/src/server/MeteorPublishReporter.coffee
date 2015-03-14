log = new ObjectLogger('MeteorPublishReporter', 'info')


class practical.mocha.MeteorPublishReporter extends practical.mocha.BaseReporter

  # TODO: Change this to use Meteor.bindEnvironment
  @publisher: null

  constructor: (runner, options)->
    try
      log.enter 'constructor', arguments
      super(runner, options)
      @publisher = practical.mocha.MeteorPublishReporter.publisher
      expect(@publisher, '@publisher').to.be.an('object')
      expect(@publisher.ready, '@publisher.ready').to.be.a('function')
      expect(@publisher.added, '@publisher.added').to.be.a('function')
      expect(@publisher.onStop, '@publisher.onStop').to.be.a('function')
      @publisher.onStop =>
        @stopped = true
      @stopped = false
      @sequence = 0

      @runner.on 'start', =>
        try
          log.enter 'onStart', arguments
          @added 'start', {total: @stats.total}
          @publisher.ready()
        finally
          log.return()

      @runner.on 'suite', (suite)=>
        try
          log.enter 'onSuite', arguments
          return if suite.root
          @added 'suite', {title: suite.title, _fullTitle: suite.fullTitle()}
        finally
          log.return()

      @runner.on 'suite end', (suite)=>
        try
          log.enter 'onSuiteEnd', arguments
          return if suite.root
          @added 'suite end', {title: suite.title, _fullTitle: suite.fullTitle()}
        finally
          log.return()

      @runner.on 'test end', (test)=>
        try
          log.enter 'onTestEnd', arguments
          @added 'test end', @clean(test)
        finally
          log.return()

      @runner.on 'pass', (test)=>
        try
          log.enter 'onPass', arguments
          @added 'pass', @clean(test)
        finally
          log.return()

      @runner.on 'fail', (test, error)=>
        try
          log.enter 'onFail', arguments
          @added 'fail', @clean(test)
        finally
          log.return()

      @runner.on 'end', =>
        try
          log.enter 'onEnd', arguments
          @added 'end', @stats
        finally
          log.return()

      @runner.on 'pending', (test)=>
        try
          log.enter 'onPending', arguments
          @added 'pending', @clean(test)
        finally
          log.return()
    finally
      log.return()


  added: (event, data)=>
    try
      log.enter 'added', arguments
      log.info event, data
      return if @stopped is true
      @sequence++
      doc =
        _id: "#{@sequence}"
        event: event
        data: data
      @publisher.added('mochaServerRunEvents', doc._id, doc)
    finally
      log.return()


  ###*
  # Return a plain-object representation of `test`
  # free of cyclic properties etc.
  #
  # @param {Object} test
  # @return {Object}
  # @api private
  ###

  clean: (test) =>
    {
    title: test.title
    _fullTitle: test.fullTitle()
    type: test.type
    state: test.state
    duration: test.duration
    async: test.async
    sync: test.sync
    _timeout: test._timeout
    _slow: test._slow
    err: @errorJSON(test.err or {})
    }

  ###*
  # Transform `error` into a JSON object.
  # @param {Error} err
  # @return {Object}
  ###

  errorJSON: (err) =>
    res = {}
    Object.getOwnPropertyNames(err).forEach (key) ->
      res[key] = err[key]
      return
    , err
    res
