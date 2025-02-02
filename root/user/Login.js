/*
 * @flow strict-local
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {CatalystContext} from '../context.mjs';
import Layout from '../layout/index.js';
import DBDefs from '../static/scripts/common/DBDefs.mjs';
import PostParameters, {
  type PostParametersT,
} from '../static/scripts/common/components/PostParameters.js';
import FormCsrfToken
  from '../static/scripts/edit/components/FormCsrfToken.js';
import FormRowCheckbox
  from '../static/scripts/edit/components/FormRowCheckbox.js';
import FormRowText from '../static/scripts/edit/components/FormRowText.js';
import FormSubmit from '../static/scripts/edit/components/FormSubmit.js';
import * as manifest from '../static/manifest.mjs';
import returnUri from '../utility/returnUri.js';

type PropsT = {
  +isLoginBad?: boolean,
  +isLoginRequired?: boolean,
  +isSpammer?: boolean,
  +loginAction: string,
  +loginForm: ReadOnlyFormT<{
    +csrf_token: ReadOnlyFieldT<string>,
    +password: ReadOnlyFieldT<string>,
    +remember_me: ReadOnlyFieldT<boolean>,
    +username: ReadOnlyFieldT<string>,
  }>,
  +postParameters: PostParametersT | null,
};

const Login = ({
  isLoginBad = false,
  isLoginRequired = false,
  isSpammer = false,
  loginAction,
  loginForm,
  postParameters,
}: PropsT): React$Element<typeof Layout> => {
  const $c = React.useContext(CatalystContext);
  return (
    <Layout fullWidth title={l('Log In')}>
      <h1>{l('Log In')}</h1>

      {isLoginRequired ? (
        <p>
          <strong>{l('You need to be logged in to view this page.')}</strong>
        </p>
      ) : null}

      <p>
        {exp.l(
          `Don't have an account? {uri|Create one now}!`,
          {uri: returnUri($c, '/register')},
        )}
      </p>

      <form action={loginAction} method="post">
        <FormCsrfToken form={loginForm} />

        {isLoginBad ? (
          <div className="row no-label">
            <span className="error">
              <strong>{l('Incorrect username or password')}</strong>
            </span>
          </div>
        ) : null}

        {isSpammer ? (
          <div className="row no-label">
            <span className="error">
              <p>
                <strong>
                  {l(`You cannot log in because this account
                      has been marked as a spam account.`)}
                </strong>
              </p>
              <p>
                {exp.l(
                  `If you think this is a mistake, please contact
                   <code>support@musicbrainz.org</code>
                   with the name of your account.`,
                )}
              </p>
            </span>
          </div>
        ) : null}

        <FormRowText
          field={loginForm.field.username}
          label={l('Username:')}
          required
          uncontrolled
        />

        <FormRowText
          field={loginForm.field.password}
          label={l('Password:')}
          required
          type="password"
          uncontrolled
        />

        {(DBDefs.DB_STAGING_SERVER && DBDefs.DB_STAGING_SERVER_SANITIZED) ? (
          <div className="row no-label">
            <span className="input-note sanitized-password-note">
              {l(`This is a development server;
                  all passwords have been reset to "mb".`)}
            </span>
          </div>
        ) : null}

        <FormRowCheckbox
          field={loginForm.field.remember_me}
          label={l('Keep me logged in')}
          uncontrolled
        />

        {postParameters ? <PostParameters params={postParameters} /> : null}

        <div className="row no-label">
          <FormSubmit className="login" label={l('Log In')} />
        </div>
      </form>

      <p>
        {exp.l('Forgot your {link1|username} or {link2|password}?', {
          link1: '/lost-username',
          link2: '/lost-password',
        })}
      </p>

      {manifest.js('user/login', {async: 'async'})}
    </Layout>
  );
};

export default Login;
