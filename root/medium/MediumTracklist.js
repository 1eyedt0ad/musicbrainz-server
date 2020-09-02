/*
 * @flow strict-local
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import RatingStars from '../components/RatingStars';
import ArtistCreditLink
  from '../static/scripts/common/components/ArtistCreditLink';
import EntityLink, {DeletedLink}
  from '../static/scripts/common/components/EntityLink';
import DataTrackIcon
  from '../static/scripts/common/components/DataTrackIcon';
import formatTrackLength
  from '../static/scripts/common/utility/formatTrackLength';
import loopParity from '../utility/loopParity';

type Props = {
  +allowNew?: boolean,
  +showArtists?: boolean,
  +showRatings?: boolean,
  +tracks?: $ReadOnlyArray<TrackT>,
};

const MediumTracklist = ({
  allowNew,
  showArtists = false,
  showRatings = false,
  tracks,
}: Props): Array<React.Element<'tr'>> => {
  if (!tracks) {
    return [];
  }

  let dataTracksStarted = false;
  const tracklist = [];

  tracks.map((track, index) => {
    const recording = track.recording;

    if (track.isDataTrack && !dataTracksStarted) {
      dataTracksStarted = true;
      tracklist.push(
        <tr className="subh">
          <td colSpan="6">
            <DataTrackIcon />
            {' '}
            {l('Data Tracks')}
          </td>
        </tr>,
      );
    }

    tracklist.push(
      <tr
        className={loopParity(index) + (track.editsPending ? ' mp' : '')}
        id={track.gid}
      >
        <td className="pos t">
          <span style={{display: 'none'}}>
            {track.position}
          </span>
          {track.number}
        </td>
        <td>
          {recording ? (
            <EntityLink
              allowNew={allowNew}
              content={track.name}
              entity={recording}
            />
          ) : (
            <DeletedLink
              allowNew={false}
              name={track.name}
            />
          )}
        </td>
        {showArtists ? (
          <td>
            <ArtistCreditLink artistCredit={track.artistCredit} />
          </td>
        ) : null}
        {showRatings && recording ? (
          <td className="rating c">
            <RatingStars entity={recording} />
          </td>
        ) : null}
        <td className="treleases">
          {formatTrackLength(track.length)}
        </td>
      </tr>,
    );
  });

  return tracklist;
};

export default MediumTracklist;
