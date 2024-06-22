import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Button, Section } from 'tgui/components';
import { Divider, Stack } from '../components';

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
          <Stack.Item grow>
            <Section fill scrollable title="Cameras">
              {cameras.map(camera => {
                return (
                  <Stack key={camera.camera}>
                    <Stack.Item grow>
                      <Button content={camera.name}
                        disabled={camera.deactivated}
                        color="transparent"
                        fluid
                        onClick={() => act("switchCamera", { camera: camera.camera })} />
                    </Stack.Item>
                    <Stack.Item align="end" color>
                      <Button icon="save"
                        color="transparent"
                        onClick={() => act("addfavorite", { camera: camera.camera })} />
                    </Stack.Item>
                  </Stack>
                );
              })}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill>
              <Stack vertical>
                <Stack.Item>
                  <Section scrollable title="Favorites">
                    {favorites && favorites.map(camera => {
                      return (
                        <Stack key={camera.camera}>
                          <Stack.Item grow>
                            <Button content={camera.name}
                              disabled={camera.deactivated}
                              color="transparent"
                              fluid
                              onClick={() => act("switchCamera", { camera: camera.camera })} />
                          </Stack.Item>
                          <Stack.Item align="end">
                            <Button icon="times"
                              color="red"
                              onClick={() => act("removefavorite", { camera: camera.camera })} />
                          </Stack.Item>
                        </Stack>
                      );
                    })}
                  </Section>
                </Stack.Item>

                <Stack.Item grow>
                  <Button icon="eye" content="Viewport" fluid
                    onClick={() => act("createViewport", { camera: current, direction: "NORTH" })} />
                  <Divider />
                  <Stack align="center" vertical fontSize="2em">
                    <Stack.Item>
                      <Button icon="arrow-up" fluid
                        color="transparent"
                        onClick={() => act("moveClosest", { camera: current, direction: "NORTH" })} />
                    </Stack.Item>
                    <Stack.Item>
                      <Button icon="arrow-left"
                        color="transparent"
                        onClick={() => act("moveClosest", { camera: current, direction: "WEST" })} />
                      <Button icon="arrows-alt"
                        color={keybindToggle ? "green" : ""}
                        onClick={() => toggleKeybind()} />
                      <Button icon="arrow-right"
                        color="transparent"
                        onClick={() => act("moveClosest", { camera: current, direction: "EAST" })} />
                    </Stack.Item>
                    <Stack.Item>
                      <Button icon="arrow-down"
                        color="transparent"
                        onClick={() => act("moveClosest", { camera: current, direction: "SOUTH" })} />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
