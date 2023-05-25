import { TextAction } from '$app/interfaces/document';
import React, { useCallback } from 'react';
import TurnIntoSelect from '$app/components/document/TextActionMenu/menu/TurnIntoSelect';
import FormatButton from '$app/components/document/TextActionMenu/menu/FormatButton';
import { useTextActionMenu } from '$app/components/document/TextActionMenu/menu/index.hooks';

function TextActionMenuList() {
  const { groupItems, id } = useTextActionMenu();
  const renderNode = useCallback((action: TextAction, id?: string) => {
    switch (action) {
      case TextAction.Turn:
        return id ? <TurnIntoSelect id={id} /> : null;
      case TextAction.Bold:
      case TextAction.Italic:
      case TextAction.Underline:
      case TextAction.Strikethrough:
      case TextAction.Code:
        return <FormatButton format={action} icon={action} />;
      default:
        return null;
    }
  }, []);

  return (
    <div className={'flex px-1'}>
      {groupItems.map((group, i: number) => (
        <div className={'flex border-r border-solid border-shade-2 px-1 last:border-r-0'} key={i}>
          {group.map((item) => (
            <div key={item} className={'flex items-center'}>
              {renderNode(item, id)}
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}

export default TextActionMenuList;
