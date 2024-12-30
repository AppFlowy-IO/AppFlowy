import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId, getBlockEntry } from '@/application/slate-yjs/utils/editor';
import { AlignType, BlockData } from '@/application/types';
import { ReactComponent as AlignCenterSvg } from '@/assets/toolbar_align_center.svg';
import { ReactComponent as AlignLeftSvg } from '@/assets/toolbar_align_left.svg';
import { ReactComponent as AlignRightSvg } from '@/assets/toolbar_align_right.svg';
import { Popover } from '@/components/_shared/popover';
import {
  useSelectionToolbarContext,
} from '@/components/editor/components/toolbar/selection-toolbar/SelectionToolbar.hooks';
import { PopoverProps } from '@mui/material/Popover';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { Element } from 'slate';
import ActionButton from './ActionButton';

const popoverProps: Partial<PopoverProps> = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
  transformOrigin: {
    vertical: -8,
    horizontal: 'center',
  },
  slotProps: {
    paper: {
      className: 'bg-[var(--fill-toolbar)] rounded-[6px]',
    },
  },
};

export function Align({
  blockId,
  enabled = true,
}: {
  blockId?: string;
  enabled?: boolean;
}) {
  const [open, setOpen] = useState(false);

  const ref = useRef<HTMLButtonElement | null>(null);
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;

  const getNode = useCallback(() => {
    let node: Element;

    if (!blockId) {
      node = getBlockEntry(editor)[0];
    } else {
      node = findSlateEntryByBlockId(editor, blockId)[0];
    }

    return node;
  }, [editor, blockId]);

  const getAlign = useCallback(() => {
    try {
      const node = getNode();

      return (node.data as BlockData).align;

    } catch (e) {
      return;
    }

  }, [getNode]);

  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  const handleOpen = useCallback(() => {
    setOpen(true);
  }, []);

  const activeIcon = useCallback(() => {
    const align = getAlign();

    switch (align) {
      case AlignType.Left:
        return <AlignLeftSvg className={'text-fill-default'}/>;
      case 'center':
        return <AlignCenterSvg className={'text-fill-default'}/>;
      case 'right':
        return <AlignRightSvg className={'text-fill-default'}/>;
      default:
        return <AlignLeftSvg/>;
    }
  }, [getAlign]);

  const { rePosition } = useSelectionToolbarContext();

  const toggleAlign = useCallback(
    (align: AlignType) => {
      return () => {
        try {
          const node = getNode();

          CustomEditor.setBlockData(editor, node.blockId as string, {
            align,
          });
          handleClose();

          rePosition();
        } catch (e) {
          return;
        }

      };
    },
    [getNode, editor, handleClose, rePosition],
  );

  useEffect(() => {
    if (!enabled) {
      setOpen(false);
    }
  }, [enabled]);

  return (
    <>
      <ActionButton
        ref={ref}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleOpen();
        }}
        tooltip={t('document.plugins.optionAction.align')}
      >
        {activeIcon()}
      </ActionButton>

      <Popover
        keepMounted={false}
        disableAutoFocus={true}
        disableEnforceFocus={true}
        disableRestoreFocus={true}
        onClose={() => {
          setOpen(false);
        }}
        open={open && enabled}
        anchorEl={ref.current}
        {...popoverProps}
      >
        <div className={'flex items-center px-2 h-[32px] justify-center'}>
          <ActionButton
            active={getAlign() === AlignType.Left}
            tooltip={t('document.plugins.optionAction.left')}
            onClick={toggleAlign(AlignType.Left)}
          >
            <AlignLeftSvg/>
          </ActionButton>
          <ActionButton
            active={getAlign() === AlignType.Center}
            tooltip={t('document.plugins.optionAction.center')}
            onClick={toggleAlign(AlignType.Center)}
          >
            <AlignCenterSvg/>
          </ActionButton>
          <ActionButton
            active={getAlign() === AlignType.Right}
            tooltip={t('document.plugins.optionAction.right')}
            onClick={toggleAlign(AlignType.Right)}
          >
            <AlignRightSvg/>
          </ActionButton>
        </div>
      </Popover>
    </>

  );
}

export default Align;
