/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

const React = require('react');
const {l} = require('../static/scripts/common/i18n');
const {lp_attributes} = require('../static/scripts/common/i18n/attributes');
const AreaContainmentLink = require('../static/scripts/common/components/AreaContainmentLink');
const EntityHeader = require('../components/EntityHeader');

type Props = {|
  +area: AreaT,
  +page: string,
|};

const AreaHeader = ({area, page}: Props) => {
  const areaType = area.typeName ? lp_attributes(area.typeName, 'area_type') : l('Area');
  let subHeading = areaType;
  if (area.containment && area.containment.length) {
    const parentAreas = <AreaContainmentLink area={area} />;
    subHeading = l('{area_type} in {parent_areas}', {
      area_type: areaType,
      parent_areas: parentAreas,
    });
  }
  return (
    <EntityHeader
      entity={area}
      headerClass="areaheader"
      page={page}
      subHeading={subHeading}
    />
  );
};

export default AreaHeader;
