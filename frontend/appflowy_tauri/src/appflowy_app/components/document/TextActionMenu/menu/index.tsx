import { TextAction } from '$app/interfaces/document';
import React, { useCallback } from 'react';
import TurnIntoSelect from '$app/components/document/TextActionMenu/menu/TurnIntoSelect';
import FormatButton from '$app/components/document/TextActionMenu/menu/FormatButton';
import { useTextActionMenu } from '$app/components/document/TextActionMenu/menu/index.hooks';
import TextColorPicker from '$app/components/document/TextActionMenu/menu/TextColorPicker';
import BgColorPicker from '$app/components/document/TextActionMenu/menu/BgColorPicker';

function TextActionMenuList() {
  const { groupItems, isSingleLine, focusId } = useTextActionMenu();
  const renderNode = useCallback(
    (action: TextAction) => {
      switch (action) {
        case TextAction.Turn:
          return isSingleLine && focusId ? <TurnIntoSelect id={focusId} /> : null;
        case TextAction.Link:
        case TextAction.Bold:
        case TextAction.Italic:
        case TextAction.Underline:
        case TextAction.Strikethrough:
        case TextAction.Code:
        case TextAction.Equation:
          return <FormatButton format={action} icon={action} />;
        case TextAction.TextColor:
          return <TextColorPicker />;
        case TextAction.Highlight:
          return <BgColorPicker />;
        default:
          return null;
      }
    },
    [isSingleLine, focusId]
  );

  return (
    <div className={'flex px-1'}>
      {groupItems.map(
        (group, i: number) =>
          group.length > 0 && (
            <div className={'flex border-r border-solid border-line-on-toolbar px-1 last:border-r-0'} key={i}>
              {group.map((item) => (
                <div key={item} className={'flex items-center'}>
                  {renderNode(item)}
                </div>
              ))}
            </div>
          )
      )}
    </div>
  );
}

export default TextActionMenuList;
