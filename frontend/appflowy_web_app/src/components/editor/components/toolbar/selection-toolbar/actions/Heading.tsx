import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType, HeadingBlockData } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import { PopoverProps } from '@mui/material/Popover';
import React, { useCallback, useRef, useState } from 'react';
import ActionButton from './ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as Heading1Svg } from '@/assets/h1.svg';
import { ReactComponent as Heading2Svg } from '@/assets/h2.svg';
import { ReactComponent as Heading3Svg } from '@/assets/h3.svg';
import { ReactComponent as Heading4Svg } from '@/assets/h4.svg';
import { ReactComponent as Heading5Svg } from '@/assets/h5.svg';
import { ReactComponent as Heading6Svg } from '@/assets/h6.svg';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

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

export function Heading () {
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
  const toHeading = useCallback(
    (level: number) => {

      return () => {
        try {
          const [node] = getBlockEntry(editor);

          if (!node) return;

          if (node.type === BlockType.HeadingBlock && (node.data as HeadingBlockData).level === level) {
            CustomEditor.turnToBlock(editor, node.blockId as string, BlockType.Paragraph, {});
            return;
          }

          CustomEditor.turnToBlock<HeadingBlockData>(editor, node.blockId as string, BlockType.HeadingBlock, { level });

        } catch (e) {
          return;
        }

      };
    },
    [editor],
  );

  const isActivated = useCallback(
    (level: number) => {
      try {
        const [node] = getBlockEntry(editor);

        const isBlock = CustomEditor.isBlockActive(editor, BlockType.HeadingBlock);

        return isBlock && (node.data as HeadingBlockData).level === level;
      } catch (e) {
        return false;
      }

    },
    [editor],
  );

  const getActiveButton = useCallback(() => {
    if (isActivated(1)) {
      return <Heading1Svg className={'text-fill-default'} />;
    }

    if (isActivated(2)) {
      return <Heading2Svg className={'text-fill-default'} />;
    }

    if (isActivated(3)) {
      return <Heading3Svg className={'text-fill-default'} />;
    }

    if (isActivated(4)) {
      return <Heading4Svg className={'text-fill-default'} />;
    }

    if (isActivated(5)) {
      return <Heading5Svg className={'text-fill-default'} />;
    }

    if (isActivated(6)) {
      return <Heading6Svg className={'text-fill-default'} />;
    }

    return <Heading1Svg />;
  }, [isActivated]);

  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLButtonElement | null>(null);

  return (
    <div className={'flex items-center justify-center'}>
      <ActionButton
        ref={ref}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          setOpen(true);
        }}
        tooltip={'Heading'}
      >
        <div className={'flex items-center justify-center'}>
          {getActiveButton()}
          <RightIcon className={'transform h-3 w-3 rotate-90 text-icon-on-toolbar opacity-80'} />
        </div>

      </ActionButton>
      <Popover
        disableAutoFocus={true}
        disableEnforceFocus={true}
        disableRestoreFocus={true}
        onClose={() => {
          setOpen(false);
        }}
        open={open}
        anchorEl={ref.current}
        {...popoverProps}
      >
        <div className={'flex items-center px-2 h-[32px] justify-center'}>
          <ActionButton active={isActivated(1)} tooltip={t('editor.heading1')} onClick={toHeading(1)}>
            <Heading1Svg />
          </ActionButton>
          <ActionButton active={isActivated(2)} tooltip={t('editor.heading2')} onClick={toHeading(2)}>
            <Heading2Svg />
          </ActionButton>
          <ActionButton active={isActivated(3)} tooltip={t('editor.heading3')} onClick={toHeading(3)}>
            <Heading3Svg />
          </ActionButton>
        </div>
      </Popover>

    </div>
  );
}

export default Heading;
