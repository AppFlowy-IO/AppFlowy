import { BlockType, NestedBlock } from '$app/interfaces/document';
import TextBlock from '$app/components/document/TextBlock';
import { useTodoListBlock } from '$app/components/document/TodoListBlock/TodoListBlock.hooks';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import React from 'react';
import NodeChildren from '$app/components/document/Node/NodeChildren';

export default function TodoListBlock({
  node,
  childIds,
}: {
  node: NestedBlock<BlockType.TodoListBlock>;
  childIds?: string[];
}) {
  const { id, data } = node;
  const { toggleCheckbox, handleShortcut } = useTodoListBlock(id, node.data);

  const checked = !!data.checked;

  return (
    <>
      <div className={'flex'} onKeyDownCapture={handleShortcut}>
        <div className={'flex h-[calc(1.5em_+_2px)] w-[1.5em] select-none items-center justify-start px-1'}>
          <div className={'relative flex h-4 w-4 items-center justify-start transition'}>
            <div>{checked ? <EditorCheckSvg /> : <EditorUncheckSvg />}</div>
            <input
              type={'checkbox'}
              checked={checked}
              onChange={toggleCheckbox}
              className={'absolute h-[100%] w-[100%] cursor-pointer opacity-0'}
            />
          </div>
        </div>
        <div className={`flex-1 ${checked ? 'text-text-caption line-through' : ''}`}>
          <TextBlock node={node} />
        </div>
      </div>
      <NodeChildren className='pl-[1.5em]' childIds={childIds} />
    </>
  );
}
