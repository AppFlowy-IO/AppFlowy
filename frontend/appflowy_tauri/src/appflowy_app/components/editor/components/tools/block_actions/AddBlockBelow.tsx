import React, { useCallback, useMemo, useState } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { IconButton, Tooltip } from '@mui/material';
import Popover from '@mui/material/Popover';
import { PopoverPreventBlurProps } from '$app/components/editor/components/tools/popover';
import SlashCommandPanelContent from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanelContent';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { Editor, Element, Transforms } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

function AddBlockBelow({ node }: { node: Element }) {
  const { t } = useTranslation();
  const [nodeEl, setNodeEl] = useState<HTMLElement | null>(null);
  const editor = useSlate();
  const openSlashCommandPanel = useMemo(() => !!nodeEl, [nodeEl]);

  const handleSlashCommandPanelClose = useCallback(
    (deleteText?: boolean) => {
      if (!nodeEl) return;
      const node = ReactEditor.toSlateNode(editor, nodeEl);

      if (deleteText) {
        const path = ReactEditor.findPath(editor, node);

        Transforms.select(editor, path);
        Transforms.insertNodes(
          editor,
          [
            {
              text: '',
            },
          ],
          {
            select: true,
          }
        );
      }

      setNodeEl(null);
    },
    [editor, nodeEl]
  );

  const handleAddBelow = () => {
    if (!node) return;
    ReactEditor.focus(editor);

    const path = ReactEditor.findPath(editor, node);

    editor.select(path);
    editor.collapse({
      edge: 'end',
    });

    const isEmptyNode = editor.isEmpty(node);

    if (isEmptyNode) {
      const nodeDom = ReactEditor.toDOMNode(editor, node);

      setNodeEl(nodeDom);
    } else {
      CustomEditor.splitToParagraph(editor);

      requestAnimationFrame(() => {
        const nextNodeEntry = Editor.next(editor, {
          at: path,
          match: (n) => Element.isElement(n) && Editor.isBlock(editor, n) && n.type === EditorNodeType.Paragraph,
        });

        if (!nextNodeEntry) return;
        const nextNode = nextNodeEntry[0] as Element;

        const nodeDom = ReactEditor.toDOMNode(editor, nextNode);

        setNodeEl(nodeDom);
      });
    }
  };

  const searchText = useMemo(() => {
    if (!nodeEl) return '';
    const node = ReactEditor.toSlateNode(editor, nodeEl);
    const path = ReactEditor.findPath(editor, node);

    return Editor.string(editor, path);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor, nodeEl, editor.selection]);

  return (
    <>
      <Tooltip title={t('blockActions.addBelowTooltip')}>
        <IconButton onClick={handleAddBelow} size={'small'}>
          <AddSvg />
        </IconButton>
      </Tooltip>
      {openSlashCommandPanel && (
        <Popover
          {...PopoverPreventBlurProps}
          anchorOrigin={{
            vertical: 30,
            horizontal: 64,
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
          onMouseMove={(e) => e.stopPropagation()}
          open={openSlashCommandPanel}
          anchorEl={nodeEl}
          onClose={() => handleSlashCommandPanelClose(false)}
        >
          <SlashCommandPanelContent searchText={searchText} closePanel={handleSlashCommandPanelClose} />
        </Popover>
      )}
    </>
  );
}

export default AddBlockBelow;
