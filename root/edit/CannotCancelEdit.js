/*
 * @flow
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import Layout from '../layout';
import EditLink from '../static/scripts/common/components/EditLink';

type Props = {
  +$c: CatalystContextT,
  +edit: EditT,
};

const CannotCancelEdit = (
  {$c, edit}: Props,
): React.Element<typeof Layout> => {
  const editDisplay = 'edit #' + edit.id;
  const editLink = <EditLink content={editDisplay} edit={edit} />;
  return (
    <Layout $c={$c} fullWidth title={l('Error Cancelling Edit')}>
      <h1>{l('Error Cancelling Edit')}</h1>
      <p>
        {exp.l(
          'There was a problem cancelling {edit}.',
          {edit: editLink},
        )}
      </p>
      <p>
        {exp.l(
          `Only the user who created an edit can cancel it,
           either you did not create {edit} or perhaps
           it has already been closed.`,
          {edit: editLink},
        )}
      </p>
    </Layout>
  );
};

export default CannotCancelEdit;
