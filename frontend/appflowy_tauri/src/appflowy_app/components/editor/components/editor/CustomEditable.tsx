import React, { ComponentProps, useCallback } from 'react';
import { Editable, useSlate } from 'slate-react';
import Element from './Element';
import { Leaf } from './Leaf';
import { useShortcuts } from '$app/components/editor/plugins/shortcuts';
import { useInlineKeyDown } from '$app/components/editor/components/editor/Editor.hooks';

type CustomEditableProps = Omit<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'> &
  Partial<Pick<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'>> & {
    disableFocus?: boolean;
  };

export function CustomEditable({
  renderElement = Element,
  disableFocus = false,
  renderLeaf = Leaf,
  ...props
}: CustomEditableProps) {
  const editor = useSlate();
  const { onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);
  const withInlineKeyDown = useInlineKeyDown(editor);
  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      withInlineKeyDown(event);
      onShortcutsKeyDown(event);
    },
    [onShortcutsKeyDown, withInlineKeyDown]
  );

  return (
    <Editable
      {...props}
      onKeyDown={onKeyDown}
      autoCorrect={'off'}
      autoComplete={'off'}
      autoFocus={!disableFocus}
      spellCheck={false}
      renderElement={renderElement}
      renderLeaf={renderLeaf}
    />
  );
}
