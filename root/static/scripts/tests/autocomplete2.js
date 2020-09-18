const $ = require('jquery');
const React = require('react');
const ReactDOM = require('react-dom');
const {
  default: Autocomplete2,
  createInitialState: createInitialAutocompleteState,
} = require('../common/components/Autocomplete2');
const {
  default: autocompleteReducer,
} = require('../common/components/Autocomplete2/reducer');

const vocals = [
  {id: 3, name: 'vocal', level: 1},
  {id: 4, name: 'lead vocals', level: 2},
  {id: 5, name: 'alto vocals', level: 3},
  {id: 6, name: 'baritone vocals', level: 3},
  {id: 7, name: 'bass vocals', level: 3},
  {id: 8, name: 'countertenor vocals', level: 3},
  {id: 9, name: 'mezzo-soprano vocals', level: 3},
  {id: 10, name: 'soprano vocals', level: 3},
  {id: 11, name: 'tenor vocals', level: 3},
  {id: 230, name: 'contralto vocals', level: 3},
  {id: 231, name: 'bass-baritone vocals', level: 3},
  {id: 834, name: 'treble vocals', level: 3},
  {id: 1060, name: 'meane vocals', level: 3},
  {id: 12, name: 'background vocals', level: 2},
  {id: 13, name: 'choir vocals', level: 2},
  {id: 461, name: 'other vocals', level: 2},
  {id: 561, name: 'spoken vocals', level: 3},
];

$(function () {
  const container = document.createElement('div');
  document.body.insertBefore(container, document.getElementById('page'));

  function reducer(state, action) {
    switch (action.type) {
      case 'update-autocomplete':
        state = {...state};
        state[action.prop] = autocompleteReducer(
          state[action.prop],
          action.action,
        );
        break;
    }
    return state;
  }

  function createInitialState() {
    return {
      entityAutocomplete: createInitialAutocompleteState({
        canChangeType: () => true,
        entityType: 'artist',
        id: 'entity-test',
        width: '200px',
      }),
      vocalAutocomplete: createInitialAutocompleteState({
        entityType: 'link_attribute_type',
        id: 'vocal-test',
        placeholder: 'Choose a vocal',
        staticItems: vocals,
        width: '200px',
      }),
    };
  }

  const AutocompleteTest = () => {
    const [state, dispatch] = React.useReducer(
      reducer,
      null,
      createInitialState,
    );

    const entityAutocompleteDispatch = React.useCallback((action) => {
      dispatch({
        action,
        prop: 'entityAutocomplete',
        type: 'update-autocomplete',
      });
    }, []);

    const vocalAutocompleteDispatch = React.useCallback((action) => {
      dispatch({
        action,
        prop: 'vocalAutocomplete',
        type: 'update-autocomplete',
      });
    }, []);

    return (
      <>
        <div>
          <h2>Entity autocomplete</h2>
          <p>
            Current entity type:
            {' '}
            <select
              value={state.entityAutocomplete.entityType}
              onChange={(event) => entityAutocompleteDispatch({
                type: 'change-entity-type',
                entityType: event.target.value,
              })}
            >
              <option value="area">Area</option>
              <option value="artist">Artist</option>
              <option value="event">Event</option>
              <option value="instrument">Instrument</option>
              <option value="label">Label</option>
              <option value="place">Place</option>
              <option value="recording">Recording</option>
              <option value="release">Release</option>
              <option value="release_group">Release Group</option>
              <option value="series">Series</option>
              <option value="work">Work</option>
            </select>
          </p>
          <Autocomplete2
            dispatch={entityAutocompleteDispatch}
            {...state.entityAutocomplete}
          />
        </div>
        <div>
          <h2>Vocal autocomplete</h2>
          <Autocomplete2
            dispatch={vocalAutocompleteDispatch}
            {...state.vocalAutocomplete}
          />
        </div>
      </>
    );
  };

  ReactDOM.render(<AutocompleteTest />, container);
});
