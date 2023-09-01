/* eslint-env node */
'use strict';

module.exports = function(environment) {
  let ENV = {
    modulePrefix: 'calbuilds',
    environment,
    rootURL: '/',
    locationType: 'auto',
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. 'with-controller': true
      },
      EXTEND_PROTOTYPES: {
        // Prevent Ember Data from overriding Date.parse.
        Date: false
      }
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    },
    contentSecurityPolicy: {
      'connect-src': '*',
    },
    'ember-simple-auth': {
      authenticationRoute: 'map',
    },
    admin: {
      email: 'ya@manhangroup.com',
    }
  };

  if (environment === 'development') {
    ENV['host'] = 'http://localhost:3000';
  }

  if (environment === 'staging') {
    //ENV.rootURL = '/calbuilds/'
    //ENV['host'] = 'https://calbuilds-api.herokuapp.com/';
    ENV['host'] = 'https://calbuilds-staging-b6f2e303aef8.herokuapp.com/';
  }

  if (environment === 'production') {
    ENV['host'] = 'https://api.calbuilds.com';
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.locationType = 'none';

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = '#ember-testing';
  }

  return ENV;
};
