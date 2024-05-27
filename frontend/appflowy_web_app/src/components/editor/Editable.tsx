import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback, useMemo } from 'react';
import { NodeEntry } from 'slate';
import { Editable, ReactEditor } from 'slate-react';
import { Element } from './components/element';

const EditorEditable = ({ editor }: { editor: ReactEditor }) => {
  const { readOnly, layoutStyle } = useEditorContext();
  const codeDecorate = useDecorate(editor);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      return [...codeDecorate(entry)];
    },
    [codeDecorate]
  );

  const layoutClassName = useMemo(() => {
    const classList = ['px-16 outline-none focus:outline-none max-md:px-4'];

    if (layoutStyle.fontLayout === 'large') {
      classList.push('font-large');
    } else if (layoutStyle.fontLayout === 'small') {
      classList.push('font-small');
    }

    if (layoutStyle.lineHeightLayout === 'large') {
      classList.push('line-height-large');
    } else if (layoutStyle.lineHeightLayout === 'small') {
      classList.push('line-height-small');
    }

    return classList.join(' ');
  }, [layoutStyle]);

  return (
    <Editable
      role={'textbox'}
      decorate={decorate}
      className={layoutClassName}
      renderLeaf={Leaf}
      renderElement={Element}
      readOnly={readOnly}
      spellCheck={false}
      autoCorrect={'off'}
      autoComplete={'off'}
    />
  );
};

export default EditorEditable;
