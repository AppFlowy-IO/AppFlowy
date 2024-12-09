import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import { ReactComponent as DuplicateIcon } from '@/assets/duplicate.svg';
import { ReactComponent as CopyLinkIcon } from '@/assets/link.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { notify } from '@/components/_shared/notify';
import { Popover } from '@/components/_shared/popover';
import Depth from '@/components/editor/components/toolbar/block-controls/Depth';
import { OutlineNode } from '@/components/editor/editor.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import { copyTextToClipboard } from '@/utils/copy';
import { Button } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'center',
    horizontal: 'right',

  },
  anchorOrigin: {
    vertical: 'center',
    horizontal: 'left',
  },
  keepMounted: false,
  disableRestoreFocus: true,
  disableEnforceFocus: true,
};

function ControlsMenu({ open, onClose, anchorEl }: {
  open: boolean;
  onClose: () => void;
  anchorEl: HTMLElement | null;
}) {
  const { selectedBlockIds } = useEditorContext();
  const editor = useSlateStatic() as YjsEditor;
  const onlySingleBlockSelected = selectedBlockIds?.length === 1;
  const node = useMemo(() => {
    const blockId = selectedBlockIds?.[0];

    if (!blockId) return null;

    return findSlateEntryByBlockId(editor, blockId);
  }, [selectedBlockIds, editor]);

  const { t } = useTranslation();
  const options = useMemo(() => {
    return [{
      key: 'delete',
      content: t('button.delete'),
      icon: <DeleteIcon/>,
      onClick: () => {
        selectedBlockIds?.forEach((blockId) => {
          CustomEditor.deleteBlock(editor, blockId);
        });
      },
    }, {
      key: 'duplicate',
      content: t('button.duplicate'),
      icon: <DuplicateIcon/>,
      onClick: () => {
        const newBlockIds: string[] = [];
        const prevId = selectedBlockIds?.[selectedBlockIds.length - 1];

        selectedBlockIds?.forEach((blockId, index) => {
          const newBlockId = CustomEditor.duplicateBlock(editor, blockId, index === 0 ? prevId : newBlockIds[index - 1]);

          newBlockId && newBlockIds.push(newBlockId);
        });

        ReactEditor.focus(editor);
        const [, path] = findSlateEntryByBlockId(editor, newBlockIds[0]);

        editor.select(editor.start(path));

      },
    }, onlySingleBlockSelected && {
      key: 'copyLinkToBlock',
      content: t('document.plugins.optionAction.copyLinkToBlock'),
      icon: <CopyLinkIcon/>,
      onClick: async () => {
        const blockId = selectedBlockIds?.[0];

        const url = new URL(window.location.href);

        url.searchParams.set('blockId', blockId);

        await copyTextToClipboard(url.toString());
        notify.success(t('shareAction.copyLinkToBlockSuccess'));
      },
    }].filter(Boolean) as {
      key: string;
      content: string;
      icon: JSX.Element;
      onClick: () => void;
    }[];
  }, [t, selectedBlockIds, editor, onlySingleBlockSelected]);

  return (
    <Popover
      anchorEl={anchorEl}
      onClose={() => {
        const path = node?.[1];

        if (path) {
          window.getSelection()?.removeAllRanges();
          ReactEditor.focus(editor);
          editor.select(editor.start(path));
        }

        onClose();
      }}
      open={open}

      {...popoverProps}
    >
      <div
        data-testid={'controls-menu'}
        className={'flex flex-col gap-2 p-2'}
      >
        {options.map((option) => {
          return (
            <Button
              data-testid={option.key}
              key={option.key}
              startIcon={option.icon}
              size={'small'}
              color={'inherit'}
              className={'justify-start'}
              onClick={(e) => {
                e.stopPropagation();
                e.preventDefault();
                option.onClick();
                onClose();
              }}
            >
              {option.content}
            </Button>
          );
        })}

        {node?.[0]?.type === BlockType.OutlineBlock && onlySingleBlockSelected && (
          <Depth node={node[0] as OutlineNode}/>
        )}
      </div>
    </Popover>
  );
}

export default ControlsMenu;