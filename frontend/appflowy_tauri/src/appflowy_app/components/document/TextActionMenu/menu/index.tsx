import { TextAction } from '$app/interfaces/document';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import React, { useCallback } from 'react';
import TurnIntoSelect from '$app/components/document/TextActionMenu/menu/TurnIntoSelect';
import { BaseEditor } from 'slate';
import FormatButton from '$app/components/document/TextActionMenu/menu/FormatButton';

function TextActionMenuList({ id, groupItems, editor }: { id: string; groupItems: TextAction[][]; editor: BaseEditor }) {
  const { node } = useSubscribeNode(id);
  const renderNode = useCallback(
    (action: TextAction) => {
      switch (action) {
        case TextAction.Turn:
          return <TurnIntoSelect id={id} selected={node?.type} />;
        case TextAction.Bold:
        case TextAction.Italic:
        case TextAction.Underline:
        case TextAction.Strikethrough:
        case TextAction.Code:
          return <FormatButton editor={editor} format={action} icon={action} />;
        default:
          return null;
      }
    },
    [id, node, editor]
  );

  return (
    <div className={'flex px-1'}>
      {groupItems.map((group, i: number) => (
        <div className={'flex border-r border-solid border-shade-2 px-1 last:border-r-0'} key={i}>
          {group.map((item) => (
            <div key={item} className={'flex items-center'}>
              {renderNode(item)}
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}

export default TextActionMenuList;
