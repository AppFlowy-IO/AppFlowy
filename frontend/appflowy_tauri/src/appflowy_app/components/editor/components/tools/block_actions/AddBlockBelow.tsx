import React from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { Element, Path } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType } from '$app/application/document/document.types';
import { YjsEditor } from '@slate-yjs/core';
import { useSlashState } from '$app/components/editor/stores';

function AddBlockBelow({ node }: { node?: Element }) {
  const { t } = useTranslation();
  const editor = useSlate();
  const { setOpen: setSlashOpen } = useSlashState();

  const handleAddBelow = () => {
    if (!node) return;
    ReactEditor.focus(editor);

    const nodePath = ReactEditor.findPath(editor, node);
    const nextPath = Path.next(nodePath);

    editor.select(nodePath);

    if (editor.isSelectable(node)) {
      editor.collapse({
        edge: 'start',
      });
    }

    const isEmptyNode = CustomEditor.isEmptyText(editor, node);

    // if the node is not a paragraph, or it is not empty, insert a new empty line
    if (node.type !== EditorNodeType.Paragraph || !isEmptyNode) {
      CustomEditor.insertEmptyLine(editor as ReactEditor & YjsEditor, nextPath);
      editor.select(nextPath);
    }

    requestAnimationFrame(() => {
      setSlashOpen(true);
    });
  };

  return (
    <>
      <Tooltip disableInteractive={true} title={t('blockActions.addBelowTooltip')}>
        <IconButton onClick={handleAddBelow} size={'small'}>
          <AddSvg />
        </IconButton>
      </Tooltip>
    </>
  );
}

export default AddBlockBelow;
