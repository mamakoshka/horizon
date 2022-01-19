/**
 * @file
 * @copyright 2022 Horizon Community <https://hrzn.fun>
 * @copyright 2022 Alexander 'Avunia' Takiya <https://takiya.eu>
 * @author Alexander 'Avunia' Takiya
 * @license MIT
 */

import { sortBy } from 'common/collections';
import { useBackend, useLocalState } from "../backend";
import { BlockQuote, Box, Button, Input, Knob, Section, Stack } from '../components';
import { Window } from "../layouts";

type JukeboxData = {
  volume: number;
  playing_track: JukeboxTrack;
  selected_track: JukeboxTrack;
  songs: JukeboxTrack[];
}

type JukeboxTrack = {
  artist: string;
  title: string;
  length: number;
  bpm: number;
  ref: string;
}

export const BoomboxTopControls = (props, context) => {
  const { act, data } = useBackend<JukeboxData>(context);
  const {
    volume,
    playing_track,
    selected_track,
  } = data;
  return (
    <Stack horizontal>
      <Stack.Item>
        <Button
          icon={playing_track ? 'stop' : 'play'}
          content={playing_track ? "Stop" : "Play"}
          fluid
          onClick={() => act('toggle_play')}
          lineHeight={3}
          disabled={selected_track === null}
          width={8}
          textAlign="center"
        />
      </Stack.Item>
      <Stack.Item grow>
        {playing_track
          ? (
            <BlockQuote>
              Now Playing:<br />
              <i>{playing_track.artist} - {playing_track.title}</i>
            </BlockQuote>
          ) : (
            <BlockQuote>
              Ready to play the hottest hits...
            </BlockQuote>
          )}
      </Stack.Item>
      <Stack.Item>
        <Knob
          size={1.5}
          value={volume}
          unit="%"
          minValue={0}
          maxValue={100}
          step={1}
          stepPixelSize={1}
          onDrag={(e, new_volume) => act('set_volume', {
            volume: new_volume,
          })}
        />
      </Stack.Item>
    </Stack>
  );
};

export const BoomboxListpicker = (props, context) => {
  const { act, data } = useBackend<JukeboxData>(context);
  const {
    selected_track,
    songs,
  } = data;
  const [displayedArray, setDisplayedArray] = useLocalState(
    context, 'displayed_array', songs);
  const [selectedButton, setSelectedButton] = useLocalState(
    context, 'selected_button', selected_track);

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Input
          fluid
          onInput={(e, value: string) => setDisplayedArray(
            songs.filter(val => (
              (`${val.artist} ${val.title}`).toLowerCase()
                .search(value.toLowerCase()) !== -1
            ))
          )}
        />
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          className="ListInput__Section"
          tabIndex={0}
        >
          {displayedArray.map(button => (
            <Button
              key={button.title}
              fluid
              color="transparent"
              id={button.title}
              selected={selectedButton === button}
              onClick={() => {
                setSelectedButton(button);
                act("select_track", { track: selectedButton.ref });
              }}>
              {button.artist} - {button.title}
            </Button>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const Boombox = (props, context) => {
  const { act, data } = useBackend<JukeboxData>(context);
  const {
    volume,
    playing_track,
    selected_track,
    songs,
  } = data;
  return (
    <Window
      title="Pawasonic Double Deck Blaster"
      width={580}
      height={400}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <BoomboxTopControls />
          </Stack.Item>
          <Stack.Item grow>
            <Stack horizontal fill>
              <Stack.Item grow>
                <BoomboxListpicker />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
