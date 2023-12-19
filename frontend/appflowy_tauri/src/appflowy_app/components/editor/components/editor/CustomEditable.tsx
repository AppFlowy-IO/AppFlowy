import React, { ComponentProps } from 'react';
import { Editable, ReactEditor, useSlate } from 'slate-react';
import Element from './Element';
import { Leaf } from './Leaf';
import { useTranslation } from 'react-i18next';

type CustomEditableProps = Omit<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'> &
  Partial<Pick<ComponentProps<typeof Editable>, 'renderElement' | 'renderLeaf'>>;

export function CustomEditable({ renderElement = Element, renderLeaf = Leaf, ...props }: CustomEditableProps) {
  const editor = useSlate();
  const { t } = useTranslation();

  return (
    <Editable
      {...props}
      placeholder={t('editor.slashPlaceHolder')}
      renderPlaceholder={({ attributes, children }) => {
        const focused = ReactEditor.isFocused(editor);

        if (focused) return <></>;
        return (
          <div {...attributes} className={`h-full whitespace-nowrap`}>
            <div className={'flex h-full items-center pl-1'}>{children}</div>
          </div>
        );
      }}
      renderElement={renderElement}
      renderLeaf={renderLeaf}
    />
  );
}
