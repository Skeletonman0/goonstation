import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, Flex, Input, Section, Stack } from '../components';

export const Terminal = (props, context) => {
  const { act, data } = useBackend(context);
  const peripherals = data.peripherals || [];
  const { textInput } = "";
  // TODO: get the scrolling to only happen sometimes
  const {
    displayHTML,
    TermActive,
    windowName,
    fontColor,
    bgColor,
    fontSize,
  } = data;

  const handleColor = (color, contents) => {
    // if a color has been specified, use that, otherwise tell if something's inserted
    if (color) {
      return color;
    } else {
      return contents ? "green" : "grey";
    }
  };

  return (
    <Window
      theme="retro-dark"
      title={windowName}
      fontFamily="Consolas"
      width="380"
      height="350"
      fontSize={fontSize}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item grow>
            <Section backgroundColor={bgColor} scrollable fill>
              <Box
                fontFamily="Consolas"
                color={fontColor}
                dangerouslySetInnerHTML={{ __html: displayHTML }}
                fill
              />
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <Flex>
                <Flex.Item grow>
                  <Input
                    placeholder="Type Here"
                    selfClear
                    value={textInput}
                    fluid
                    onEnter={(e, value) => act('text', { value: value })}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button icon="power-off"
                    color={TermActive ? "green" : "red"}
                    onClick={() => act('restart')} />
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              {peripherals.map(peripheral => {
                return (
                  <Button
                    key={peripheral.card}
                    icon={peripheral.icon}
                    content={peripheral.label}
                    fontFamily={peripheral.Clown ? "Comic Sans MS" : "Consolas"}
                    color={handleColor(peripheral.color, peripheral.contents)}
                    onClick={() => act('buttonPressed', {
                      card: peripheral.card })}
                  />
                );
              })}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );

};
