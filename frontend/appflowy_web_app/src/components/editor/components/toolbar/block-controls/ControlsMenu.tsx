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
import { useSlateStatic } from 'slate-react';

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
  disableEnforceFocus: false,
  disableAutoFocus: false,
};

function ControlsMenu ({ blockId, open, onClose, anchorEl }: {
  blockId: string;
  open: boolean;
  onClose: () => void;
  anchorEl: HTMLElement | null;
}) {

  const { setSelectedBlockId } = useEditorContext();
  const editor = useSlateStatic() as YjsEditor;
  const node = useMemo(() => {
    return findSlateEntryByBlockId(editor, blockId)[0];
  }, [blockId, editor]);

  const nodeType = node.type as BlockType;

  const { t } = useTranslation();
  const options = useMemo(() => {
    return [{
      key: 'delete',
      content: t('button.delete'),
      icon: <DeleteIcon />,
      onClick: () => {
        CustomEditor.deleteBlock(editor, blockId);
        setSelectedBlockId?.(undefined);
      },
    }, {
      key: 'duplicate',
      content: t('button.duplicate'),
      icon: <DuplicateIcon />,
      onClick: () => {
        const newBlockId = CustomEditor.duplicateBlock(editor, blockId);

        setSelectedBlockId?.(newBlockId || undefined);
      },
    }, {
      key: 'copyLinkToBlock',
      content: t('document.plugins.optionAction.copyLinkToBlock'),
      icon: <CopyLinkIcon />,
      onClick: async () => {
        const url = new URL(window.location.href);

        url.searchParams.set('blockId', blockId);

        await copyTextToClipboard(url.toString());
        notify.success(t('shareAction.copyLinkToBlockSuccess'));
      },
    }];
  }, [blockId, editor, t, setSelectedBlockId]);

  return (
    <Popover
      anchorEl={anchorEl}
      onClose={onClose}
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
              onClick={() => {
                option.onClick();
                onClose();
              }}
            >
              {option.content}
            </Button>
          );
        })}

        {nodeType === BlockType.OutlineBlock && (
          <Depth node={node as OutlineNode} />
        )}
      </div>
    </Popover>
  );
}

export default ControlsMenu;