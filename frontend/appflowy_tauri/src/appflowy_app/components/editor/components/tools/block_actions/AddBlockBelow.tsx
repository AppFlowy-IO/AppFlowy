import React, { useCallback, useMemo, useState } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { IconButton, Tooltip } from '@mui/material';
import Popover from '@mui/material/Popover';
import { PopoverPreventBlurProps } from '$app/components/editor/components/tools/popover';
import SlashCommandPanelContent from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanelContent';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { Element } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType } from '$app/application/document/document.types';

function AddBlockBelow({ node }: { node?: Element }) {
  const { t } = useTranslation();
  const [nodeEl, setNodeEl] = useState<HTMLElement | null>(null);
  const editor = useSlate();
  const openSlashCommandPanel = useMemo(() => !!nodeEl, [nodeEl]);

  const handleSlashCommandPanelClose = useCallback(
    (deleteText?: boolean) => {
      if (!nodeEl) return;
      const node = ReactEditor.toSlateNode(editor, nodeEl) as Element;

      if (!node) return;

      if (deleteText) {
        CustomEditor.deleteAllText(editor, node);
      }

      setNodeEl(null);
    },
    [editor, nodeEl]
  );

  const handleAddBelow = () => {
    if (!node) return;
    ReactEditor.focus(editor);

    const [textNode] = node.children as Element[];
    const hasTextNode = textNode && textNode.type === EditorNodeType.Text;

    const nodePath = ReactEditor.findPath(editor, node);
    const textPath = ReactEditor.findPath(editor, textNode);

    const focusPath = hasTextNode ? textPath : nodePath;

    editor.select(focusPath);
    editor.collapse({
      edge: 'end',
    });

    const isEmptyNode = CustomEditor.isEmptyText(editor, node);

    if (isEmptyNode) {
      const nodeDom = ReactEditor.toDOMNode(editor, node);

      setNodeEl(nodeDom);
      return;
    }

    editor.insertBreak();
    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.Paragraph,
    });

    requestAnimationFrame(() => {
      const block = CustomEditor.getBlock(editor);

      if (block) {
        const [node] = block;

        const nodeDom = ReactEditor.toDOMNode(editor, node);

        setNodeEl(nodeDom);
      }
    });
  };

  const searchText = useMemo(() => {
    if (!nodeEl) return '';
    const node = ReactEditor.toSlateNode(editor, nodeEl) as Element;

    if (!node) return '';

    return CustomEditor.getNodeText(editor, node);
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
            horizontal: 'left',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
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
