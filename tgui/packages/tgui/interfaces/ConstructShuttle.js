import { useBackend } from '../backend';
import { Section, Button, BlockQuote } from '../components';
import { Window } from '../layouts';

export const ConstructShuttle = (props, context) => {
  const { act, data } = useBackend(context);
  const coords = data.coords || [];


  const {
    shuttlename,
  } = data;

  let traveltext = `the ${shuttlename} is currently at ${coords.x} ,  ${coords.y},  ${coords.z}`;

  return (
    <Window height="520" width="300" title={shuttlename} >
      <BlockQuote style={{ "margin": "5px" }}>{traveltext}</BlockQuote>
      <Section fill scrollable height="100%">
        <Button
          content="Detect Parts"
          onClick={() => act("reload", {})}
        />
      </Section>
    </Window>
  );
};
