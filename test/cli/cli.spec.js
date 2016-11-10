'use strict';

var Commander = require('commander');
var Command = Commander.Command;
var Option = Commander.Option;
var cli = require('../../lib/cli/cli');
var path = require('path');
var Mocha = require('../../');

var testArgs1 = [
  '/usr/bin/nodejs',
  '/random/path/mocha/bin/_mocha',
  '--opts', 'test/cli/test.opts',
  'test/cli/cli.spec.js'
];

var testArgs2 = [
  '/usr/bin/nodejs',
  '/random/path/mocha/bin/_mocha',
  '--opts', 'test/cli/test.opts',
  'test/cli/parser.spec.js'
];

var testOpts = [
  '--require', 'should',
  '--require', './test/setup',
  '--reporter', 'dot',
  '--ui', 'bdd',
  '--globals', 'okGlobalA,okGlobalB',
  '--globals', 'okGlobalC',
  '--globals', 'callback*',
  '--timeout', '200'
];

describe('Cli', function () {
  describe('.makeCommand()', function () {
    var program = cli.makeCommand();

    it('should have these properties before parsing', function () {
      program.should.be.an.instanceOf(Command);
      program.should.have.property('_makeCommand', true);
      program.parseOptions.should.be.a.Function;
      // ensure its correctly set before parsing
      program.opts.should.be.a.Function;
    });

    it('should not mutate arguments', function () {
      // this is to make sure using multiple instances doesn't break
      var program1 = cli.makeCommand();
      var program2 = cli.makeCommand();
      var program3 = cli.makeCommand();

      program1.parseOptions(testArgs1);
      program2.parseOptions(testArgs1);
      program3.parseOptions(testArgs1);

      program1.globals.should.be.an.Array;
      program1.globals.should.deepEqual([
        'okGlobalA',
        'okGlobalB',
        'okGlobalC',
        'callback*'
      ]);
      program1.require.should.be.an.Array;
      program1.require.should.deepEqual([
        'should',
        path.resolve('./test/setup')
      ]);

      program2.globals.should.be.an.Array;
      program2.globals.should.deepEqual([
        'okGlobalA',
        'okGlobalB',
        'okGlobalC',
        'callback*'
      ]);
      program2.require.should.be.an.Array;
      program2.require.should.deepEqual([
        'should',
        path.resolve('./test/setup')
      ]);

      program3.globals.should.be.an.Array;
      program3.globals.should.deepEqual([
        'okGlobalA',
        'okGlobalB',
        'okGlobalC',
        'callback*'
      ]);
      program3.require.should.be.an.Array;
      program3.require.should.deepEqual([
        'should',
        path.resolve('./test/setup')
      ]);
    });

    it('should have these properties after only option parsing', function () {
      var program1 = cli.makeCommand();

      var parsed = program1.parseOptions(testArgs1);
      parsed.should.be.an.Object;
      parsed.should.deepEqual({
        args: [
          '/usr/bin/nodejs',
          '/random/path/mocha/bin/_mocha',
          'test/cli/cli.spec.js'
        ],
        unknown: []
      });

      // ensure its correctly set after parsing
      program1.opts.should.be.a.Function;
      program1.globals.should.be.an.Array;
      program1.globals.should.deepEqual([
        'okGlobalA',
        'okGlobalB',
        'okGlobalC',
        'callback*'
      ]);
      program1.require.should.be.an.Array;
      program1.require.should.deepEqual([
        'should',
        path.resolve('./test/setup')
      ]);

      program1.timeout.should.eql('200');
      program1.ui.should.eql('bdd');
      program1.reporter.should.eql('dot');

      // rawArgs should not be set, since parseOptions doesn't set it by default
      expect(program1.rawArgs).to.not.be.ok;
    });

    it('should have these properties after parsing', function () {
      program.parse(testArgs1);

      // ensure its correctly set after parsing
      program.opts.should.be.a.Function;
      program.globals.should.be.an.Array;
      program.globals.should.deepEqual([
        'okGlobalA',
        'okGlobalB',
        'okGlobalC',
        'callback*'
      ]);
      program.require.should.be.an.Array;
      program.require.should.deepEqual([
        'should',
        path.resolve('./test/setup')
      ]);

      program.timeout.should.eql('200');
      program.ui.should.eql('bdd');
      program.reporter.should.eql('dot');

      // make sure rawArgs is set to the updated args
      program.rawArgs.should.deepEqual(
        testArgs1
          .slice(0, 2)
          .concat(testOpts)
          .concat(testArgs1.slice(2))
      );
    });
  });

  describe('.addActions()', function () {
    var program = cli.makeCommand();
    cli.addActions(program);

    it('should have options and commands', function () {
      program.optionFor('--reporters').should.be.instanceOf(Option);
      program.optionFor('--interfaces').should.be.instanceOf(Option);
      program.optionFor('--watch').should.be.instanceOf(Option);
      // sanity test.
      expect(program.optionFor('--doesntexist')).to.not.be.ok;

      program.commands[0].name().should.be.eql('init');
    });
  });

  xdescribe('.setMochaOptions()', function () {
    xit('should set options on mocha', function () {
      var program = cli.makeCommand();
      program.parse(testArgs1);
      var mocha = new Mocha();
      cli.setMochaOptions(mocha, program.opts());

      // how to test this? we should test as many options being set as possible
    });

    xit('should separate global scope per instance', function () {
      var program = cli.makeCommand();
      program.parse(testArgs1);
    });
  });

  xdescribe('.run()', function () {
    var program1 = cli.makeCommand();
    program1.parse(testArgs2);

    it('should run mocha ', function () {
      var mocha = new Mocha();
      cli.setMochaOptions(mocha, program1.opts());
      // how to test this?

      cli.run(mocha, program1.opts(), cli.resolveFiles(program1.args, program1.opts()));
    });
  });

  describe('.resolveFiles()', function () {
    it('should resolve a single file', function () {
      var files = cli.resolveFiles(['test/cli/cli.spec.js']);

      files.should.have.length(1);
      files[0].should.be.eql(path.resolve('test/cli/cli.spec.js'));
    });

    it('should recursively resolve and sort files', function () {
      var files = cli.resolveFiles(['test/cli'], {
        recursive: true,
        sort: true
      });

      files.should.have.length(2);
      files[0].should.be.eql(path.resolve('test/cli/cli.spec.js'));
      files[1].should.be.eql(path.resolve('test/cli/parser.spec.js'));
    });

    it('should resolve test.opts', function () {
      var files = cli.resolveFiles(['test/cli/test.opts'], {
        watchExtensions: 'opts'
      });

      files.should.have.length(1);
      files[0].should.be.eql(path.resolve('test/cli/test.opts'));
    });
  });

  xdescribe('.loadOptsFile()', function () {
    it('should configure mocha from opts file', function () {
      var mocha = new Mocha();
      cli.loadOptsFile('test/cli/test.opts', mocha);

      // how to test this? is reliant on setMochaOptions
    });
  });
});
