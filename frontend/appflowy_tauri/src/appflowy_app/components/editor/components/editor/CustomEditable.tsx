import React, { ComponentProps } from 'react';
import { Editable } from 'slate-react';
import Element from './Element';
import { Leaf } from './Leaf';

type CustomEditableProps = Omit<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'> &
  Partial<Pick<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'>>;

export function CustomEditable({ renderElement = Element, renderLeaf = Leaf, ...props }: CustomEditableProps) {
  return (
    <Editable
      {...props}
      autoCorrect={'off'}
      autoComplete={'off'}
      autoFocus
      spellCheck={false}
      renderElement={renderElement}
      renderLeaf={renderLeaf}
    />
  );
}
