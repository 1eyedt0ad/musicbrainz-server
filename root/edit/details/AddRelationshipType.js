/*
 * @flow strict-local
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import IntentionallyRawIcon from '../components/IntentionallyRawIcon';
import Cardinality from '../../static/scripts/common/components/Cardinality';
import OrderableDirection
  from '../../static/scripts/common/components/OrderableDirection';
import {ENTITY_NAMES} from '../../static/scripts/common/constants';

type AddRelationshipTypeEditT = {
  ...EditT,
  +display_data: {
    +attributes: $ReadOnlyArray<{
      ...LinkTypeAttrTypeT,
      +typeName: string,
    }>,
    +child_order: number,
    +description: string | null,
    +documentation: string | null,
    +entity0_cardinality?: number,
    +entity0_type: CoreEntityTypeT,
    +entity1_cardinality?: number,
    +entity1_type: CoreEntityTypeT,
    +link_phrase: string,
    +long_link_phrase: string,
    +name: string,
    +orderable_direction?: number,
    +reverse_link_phrase: string,
  },
};

type Props = {
  +edit: AddRelationshipTypeEditT,
};

const AddRelationshipType = ({edit}: Props): React.Element<'table'> => {
  const display = edit.display_data;
  const entity0Type = ENTITY_NAMES[display.entity0_type]();
  const entity1Type = ENTITY_NAMES[display.entity1_type]();

  // Always display entity placeholders for ease of understanding
  let longLinkPhrase = display.long_link_phrase;
  if (longLinkPhrase && !longLinkPhrase.match('{entity0}')) {
    longLinkPhrase = '{entity0} ' + longLinkPhrase;
  }
  if (longLinkPhrase && !longLinkPhrase.match('{entity1}')) {
    longLinkPhrase = longLinkPhrase + ' {entity1}';
  }

  const rawIconSection = (
    <>
      {' '}
      <IntentionallyRawIcon />
    </>
  );

  return (
    <table className="details add-relationship-type">
      <tr>
        <th>{addColonText(l('Name'))}</th>
        <td>
          {display.name}
          {rawIconSection}
        </td>
      </tr>

      <tr>
        <th>{addColonText(l('Description'))}</th>
        <td>
          {nonEmpty(display.description)
            ? (
              <>
                {display.description}
                {rawIconSection}
              </>
            ) : lp('(none)', 'description')}
          {}
        </td>
      </tr>

      <tr>
        <th>
          {addColon(exp.l('Type of {entity_placeholder}', {
            entity_placeholder: <code>{'{entity0}'}</code>,
          }))}
        </th>
        <td>{entity0Type}</td>
      </tr>

      <tr>
        <th>
          {addColon(exp.l('Type of {entity_placeholder}', {
            entity_placeholder: <code>{'{entity1}'}</code>,
          }))}
        </th>
        <td>{entity1Type}</td>
      </tr>

      <tr>
        <th>{l('Link phrase:')}</th>
        <td>
          {display.link_phrase}
          {rawIconSection}
        </td>
      </tr>

      <tr>
        <th>{l('Reverse link phrase:')}</th>
        <td>
          {display.reverse_link_phrase}
          {rawIconSection}
        </td>
      </tr>

      <tr>
        <th>{l('Long link phrase:')}</th>
        <td>
          {longLinkPhrase ? (
            <>
              {longLinkPhrase}
              {rawIconSection}
            </>
          ) : lp('(none)', 'link_phrase')}
        </td>
      </tr>

      <tr>
        <th>{l('entity0 cardinality:')}</th>
        <td>
          <Cardinality cardinality={display.entity0_cardinality || 0} />
        </td>
      </tr>
      <tr>
        <th>{l('entity1 cardinality:')}</th>
        <td>
          <Cardinality cardinality={display.entity1_cardinality || 0} />
        </td>
      </tr>

      <tr>
        <th>{l('Orderable direction:')}</th>
        <td>
          <OrderableDirection direction={display.orderable_direction || 0} />
        </td>
      </tr>

      {display.attributes.length > 0 ? (
        <tr>
          <th>{addColonText(l('Attributes'))}</th>
          <td>
            <ul>
              {display.attributes.map((attribute, index) => (
                <li key={'attribute-' + index}>
                  {addColon(l_relationships(attribute.typeName))}
                  {' '}
                  {attribute.min}
                  {'-'}
                  {attribute.max}
                </li>
              ))}
            </ul>
          </td>
        </tr>
      ) : null}

      <tr>
        <th>{addColonText(l('Documentation'))}</th>
        <td>
          {nonEmpty(display.documentation)
            ? (
              <>
                {display.documentation}
                {rawIconSection}
              </>
            ) : lp('(none)', 'documentation')}
        </td>
      </tr>
    </table>
  );
};

export default AddRelationshipType;
