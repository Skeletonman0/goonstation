import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Tabs, Button, Section, Table } from 'tgui/components';
import { Collapsible, Divider, Flex, LabeledList, Stack } from '../components';

export const CameraConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const cameras = data.cameras || [];
  const favorites = data.favorites || [];

  const {
    windowName,
    current,
  } = data;

  const [keybindToggle, setKeybind] = useLocalState(context, 'keybindToggle', false);

  const getDirection = (key) => {
    switch (key) {
      case 'w':
        return "N";
      case 'a':
        return "W";
      case 's':
        return "S";
      case 'd':
        return "E";

    }
  };
  const toggleKeybind = () => {
    if (!keybindToggle) {
      act("keyboard_on");
    } else {
      act("keyboard_off");
    }
    setKeybind(!keybindToggle);
  };

  return (
    <Window
      title={windowName}
      width="570"
      fontFamily="Consolas"
      font-size="10pt"
      height="400">
      <Window.Content
        height="100%" mx="1%"
        onKeyUp={(ev) => {
          if (keybindToggle) {
            act("moveClosest", { camera: current, direction: getDirection(ev.key) });
          }
        }}
        onKeyDown={(ev) => {
          if (keybindToggle) {
            act("moveClosest", { camera: current, direction: getDirection(ev.key) });
          }

          if (ev.key === 'Control') {
            toggleKeybind();
          } }}>
        <Stack fill>
          <Stack.Item grow maxWidth="50%" maxHeight="99%">
            <Section fill scrollable fitted title="Cameras">
              {cameras.map(camera => {
                return (
                  <Flex key={camera.name}>
                    <Flex.Item grow>
                      <Button content={camera.name}
                        disabled={camera.deactivated}
                        color="#a4bad6"
                        onClick={() => act("switchCamera", { camera: camera.camera })} />
                    </Flex.Item>
                    <Flex.Item align="end">
                      <Button icon="save"
                        color="green"
                        onClick={() => act("addfavorite", { camera: camera.camera })} />
                    </Flex.Item>
                  </Flex>
                );
              })}
            </Section>
          </Stack.Item>
          <Stack.Item grow maxWidth="50%" >
            <Section scrollable title="Favorites" fill maxHeight="50%">
              {favorites && favorites.map(camera => {
                return (
                  <Flex key={camera.name}>
                    <Flex.Item grow bold>
                      <Button content={camera.name}
                        disabled={camera.deactivated}
                        onClick={() => act("switchCamera", { camera: camera.camera })} />
                    </Flex.Item>
                    <Flex.Item shrink align="end">
                      <Button icon="times"
                        onClick={() => act("removefavorite", { camera: camera.camera })} />
                    </Flex.Item>
                  </Flex>
                );
              })}
            </Section>
            <Section fill fitted maxHeight="50%">
              <Button icon="eye" content="Viewport"
                onClick={() => act("createViewport", { camera: current, direction: "NORTH" })} />
              <Flex align="center" direction="column" fontSize="25px" m="1%">
                <Flex.Item>
                  <Button icon="arrow-up"
                    onClick={() => act("moveClosest", { camera: current, direction: "NORTH" })} />
                </Flex.Item>
                <Flex.Item>
                  <Button icon="arrow-left"
                    onClick={() => act("moveClosest", { camera: current, direction: "WEST" })} />
                  <Button icon="arrows-alt"
                    color={keybindToggle ? "green" : "blue"}
                    onClick={() => toggleKeybind()} />
                  <Button icon="arrow-right"
                    onClick={() => act("moveClosest", { camera: current, direction: "EAST" })} />
                </Flex.Item>
                <Flex.Item>
                  <Button icon="arrow-down"
                    onClick={() => act("moveClosest", { camera: current, direction: "SOUTH" })} />
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
