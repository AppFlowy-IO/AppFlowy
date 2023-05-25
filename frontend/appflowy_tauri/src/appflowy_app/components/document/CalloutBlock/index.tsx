import { BlockType, NestedBlock } from '$app/interfaces/document';
import TextBlock from '$app/components/document/TextBlock';
import NodeChildren from '$app/components/document/Node/NodeChildren';
import { IconButton } from '@mui/material';
import emojiData from '@emoji-mart/data';
import Picker from '@emoji-mart/react';
import { useCalloutBlock } from '$app/components/document/CalloutBlock/CalloutBlock.hooks';
import Popover from '@mui/material/Popover';

export default function CalloutBlock({
  node,
  childIds,
}: {
  node: NestedBlock<BlockType.CalloutBlock>;
  childIds?: string[];
}) {
  const { openEmojiSelect, open, closeEmojiSelect, id, anchorEl, onEmojiSelect } = useCalloutBlock(node.id);

  return (
    <div className={'my-1 flex rounded border border-solid border-main-accent bg-main-secondary p-4'}>
      <div className={'w-[1.5em]'} onMouseDown={(e) => e.stopPropagation()}>
        <div className={'flex h-[calc(1.5em_+_2px)] w-[24px] select-none items-center justify-start'}>
          <IconButton
            aria-describedby={id}
            onClick={openEmojiSelect}
            className={`m-0 h-[100%] w-[100%] rounded-full p-0 transition`}
          >
            {node.data.icon}
          </IconButton>
          <Popover
            className={'border-none bg-transparent shadow-none'}
            anchorEl={anchorEl}
            disableAutoFocus={true}
            open={open}
            onClose={closeEmojiSelect}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'left',
            }}
          >
            <Picker searchPosition={'static'} locale={'en'} autoFocus data={emojiData} onEmojiSelect={onEmojiSelect} />
          </Popover>
        </div>
      </div>
      <div className={'flex-1'}>
        <div>
          <TextBlock node={node} />
        </div>
        <NodeChildren childIds={childIds} />
      </div>
    </div>
  );
}
