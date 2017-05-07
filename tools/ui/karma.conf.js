try {
  const fs = require('fs');
  const firefoxFlags = [
      '-headless',
      '--window-size=1024,768',
  ];
  const chromeFlags = [
    '--headless',
    '--disable-gpu',
    '--disable-translate',
    '--disable-extensions',
    '--enable-crash-reporter',
    '--window-size=1024,768',
    '--remote-debugging-port=TMPL_DEBUG_PORT'
  ];
  const debugChromeFlags = chromeFlags.concat([
    '--enable-logging=stderr',
    '--v=1',
  ]);

  const browsers = [TMPL_BROWSERS];

  // WEB_TEST_METADATA is configured in rules_webtesting based on value
  // of the browsers attribute passed to ts_web_test_suite
  // We setup the karma configuration based on the values in this object
  if (process.env['WEB_TEST_METADATA']) {
    const webTestMetadata = JSON.parse(fs.readFileSync(process.env['WEB_TEST_METADATA'], 'utf8'));
    if (webTestMetadata['environment'] === 'local') {
      // When a local chrome or firefox browser is chosen such as
      // "@io_bazel_rules_webtesting//browsers:chromium-local" or
      // "@io_bazel_rules_webtesting//browsers:firefox-local"
      // then the 'environment' will equal 'local' and
      // 'webTestFiles' will contain the path to the binary to use
      webTestMetadata['webTestFiles'].forEach(webTestFiles => {
        const webTestNamedFiles = webTestFiles['namedFiles'];
        if (webTestNamedFiles['CHROMIUM']) {
          // When karma is configured to use Chrome it will look for a CHROME_BIN
          // environment variable.
          process.env.CHROME_BIN = webTestNamedFiles['CHROMIUM'];
          const browser = process.env['DISPLAY'] ? 'Chrome' : 'ChromeHeadless';
          browsers.push(browser);
        }
        if (webTestNamedFiles['FIREFOX']) {
          // When karma is configured to use Firefox it will look for a
          // FIREFOX_BIN environment variable.
          process.env.FIREFOX_BIN = webTestNamedFiles['FIREFOX'];
          browsers.push(process.env['DISPLAY'] ? 'Firefox' : 'FirefoxHeadless');
        }
      });
    } else {
      console.warn(`Unknown WEB_TEST_METADATA environment '${webTestMetadata['environment']}'`);
    }
  }

  const proxies = {};
  const files = [
    TMPL_FILES
  ];

  [
    TMPL_TEMPLATES
  ].forEach(f => {
    files.push({pattern: f, included: false});
    proxies['/base/' + f] = '/absolute/' + f;
  });

  if (!browsers.length) {
    throw new Error('No browsers configured.');
  }

  var SpecReporter = require('jasmine-spec-reporter');
  module.exports = function (config) {
    config.set({
      basePath: 'TMPL_PATH',
      frameworks: [
        'jasmine'
      ],
      preprocessors: {
        'TMPL_BASE_URL/**/*.js': [
          TMPL_PREPROCESSORS
        ]
      },
      exclude: [],
      plugins: [
        'karma-chrome-launcher',
        'karma-firefox-launcher',
        'karma-sourcemap-loader',
        'karma-coverage',
        'karma-jasmine',
      ],
      reporters: [
        'progress',
        'coverage'
      ],
      port: TMPL_PORT,
      listenAddress: 'localhost',
      hostname: 'localhost',
      colors: true,
      autoWatch: false,
      singleRun: true,
      browsers: browsers,
      customLaunchers: {
          FirefoxHeadless: {
              base: 'Firefox',
              flags: firefoxFlags
          },
          FirefoxHeadlessDeveloper: {
              base: 'FirefoxDeveloper',
              flags: firefoxFlags
          },
          ChromiumHeadless: {
              base: 'Chromium',
              flags: chromeFlags
          },
          ChromiumHeadlessDebug: {
              base: 'Chromium',
              flags: debugChromeFlags
          },
          ChromeHeadless: {
              base: 'Chrome',
              flags: chromeFlags
          },
          ChromeHeadlessDebug: {
              base: 'Chrome',
              flags: debugChromeFlags
          }
      },
      browserNoActivityTimeout: TMPL_TIMEOUT,
      coverageReporter: {
        type: 'html'
      },
      onPrepare: function () {
        jasmine.getEnv().addReporter(new SpecReporter({displayStacktrace: 'all'}));
      },
      logLevel: config.TMPL_LOG_LEVEL,
      files,
      proxies,
    });
  };

} catch (e) {
  console.error('Error in karma configuration', e.toString());
  throw e;
}