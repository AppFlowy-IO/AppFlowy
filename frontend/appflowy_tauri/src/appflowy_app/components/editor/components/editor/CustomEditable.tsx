import React, { ComponentProps } from 'react';
import { Editable } from 'slate-react';
import Element from './Element';
import { Leaf } from './Leaf';

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
  return (
    <Editable
      {...props}
      autoCorrect={'off'}
      autoComplete={'off'}
      autoFocus={!disableFocus}
      spellCheck={false}
      renderElement={renderElement}
      renderLeaf={renderLeaf}
    />
  );
}
