// This file is part of MusicBrainz, the open internet music database.
// Copyright (C) 2015-2017 MetaBrainz Foundation
// Licensed under the GPL version 2, or (at your option) any later version:
// http://www.gnu.org/licenses/gpl-2.0.txt

const _ = require('lodash');
const path = require('path');
const Raven = require('raven');
const React = require('react');
const ReactDOMServer = require('react-dom/server');

const DBDefs = require('../static/scripts/common/DBDefs');
const getRequestCookie = require('../utility/getRequestCookie').default;
const {bufferFrom} = require('./buffer');

function pathFromRoot(fpath) {
  return path.resolve(__dirname, '../', fpath);
}

function badRequest(err) {
  return bufferFrom(JSON.stringify({
    body: err.stack,
    content_type: 'text/plain',
    status: 400,
  }));
}

function getExport(object) {
  return object.default || object;
}

function getResponse(requestBody, context) {
  let status = null;
  let Page;
  let response;

  Raven.setContext({
    environment: DBDefs.GIT_BRANCH,
    tags: {
      git_commit: DBDefs.GIT_SHA,
    },
  });

  if (context.user) {
    Raven.mergeContext({user: _.pick(context.user, ['id', 'name'])});
  }

  // Set the current translations to be used for this request based on the
  // given 'lang' cookie.
  const gettext = require('./gettext');
  const bcp47Locale = getRequestCookie(context.req, 'lang') || 'en';
  gettext.setLocale(bcp47Locale.replace("-", "_"));

  try {
    Page = getExport(require(pathFromRoot(requestBody.component)));
  } catch (err) {
    if (err.code === 'MODULE_NOT_FOUND') {
      try {
        Page = getExport(require(pathFromRoot('main/404')));
        status = 404;
      } catch (err) {
        Raven.captureException(err);
        return badRequest(err);
      }
    } else {
      Raven.captureException(err);
      return badRequest(err);
    }
  }

  try {
    // N.B. This must be required in the same process that serves the request.
    // Do not move to the top of the file.
    const {CatalystContext} = require('../context');

    response = ReactDOMServer.renderToString(
      React.createElement(
        CatalystContext.Provider,
        {value: context},
        React.createElement(Page, requestBody.props),
      )
    );
  } catch (err) {
    Raven.captureException(err);
    return badRequest(err);
  }

  return bufferFrom(JSON.stringify({
    body: response,
    content_type: 'text/html',
    status,
  }));
}

exports.badRequest = badRequest;
exports.getResponse = getResponse;
