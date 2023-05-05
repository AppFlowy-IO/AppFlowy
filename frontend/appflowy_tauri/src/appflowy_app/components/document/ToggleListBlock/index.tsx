import React from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import TextBlock from '$app/components/document/TextBlock';
import NodeChildren from '$app/components/document/Node/NodeChildren';
import { useToggleListBlock } from '$app/components/document/ToggleListBlock/ToggleListBlock.hooks';
import { IconButton } from '@mui/material';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import Button from '@mui/material/Button';

function ToggleListBlock({ node, childIds }: { node: NestedBlock<BlockType.ToggleListBlock>; childIds?: string[] }) {
  const { toggleCollapsed, handleShortcut } = useToggleListBlock(node.id, node.data);
  const collapsed = node.data.collapsed;
  return (
    <>
      <div className={'flex'} onKeyDownCapture={handleShortcut}>
        <div className={`relative h-[calc(1.5em_+_2px)] w-[1.5em] select-none overflow-hidden px-1`}>
          <Button
            variant={'text'}
            color={'inherit'}
            size={'small'}
            onClick={toggleCollapsed}
            style={{
              minWidth: '20px',
              padding: 0,
            }}
            className={`transition-transform duration-500 ${collapsed && 'rotate-[-90deg]'}`}
          >
            <DropDownShowSvg />
          </Button>
        </div>

        <div className={'flex-1'}>
          <TextBlock node={node} />
        </div>
      </div>
      {!collapsed && <NodeChildren className='pl-[1.5em]' childIds={childIds} />}
    </>
  );
}

export default ToggleListBlock;
