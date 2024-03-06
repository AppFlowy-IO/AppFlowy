import React, { useCallback, useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { useTranslation } from 'react-i18next';
import { Divider } from '@mui/material';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { Element, Path } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { Color } from '$app/components/editor/components/tools/block_actions/color';
import { getModifier } from '$app/utils/hotkeys';

import isHotkey from 'is-hotkey';
import { EditorNodeType } from '$app/application/document/document.types';
import { EditorSelectedBlockContext } from '$app/components/editor/stores/selected';

export const canSetColorBlocks: EditorNodeType[] = [
  EditorNodeType.Paragraph,
  EditorNodeType.HeadingBlock,
  EditorNodeType.TodoListBlock,
  EditorNodeType.BulletedListBlock,
  EditorNodeType.NumberedListBlock,
  EditorNodeType.ToggleListBlock,
  EditorNodeType.QuoteBlock,
  EditorNodeType.CalloutBlock,
];

export function BlockOperationMenu({
  node,
  ...props
}: {
  node: Element;
} & PopoverProps) {
  const editor = useSlateStatic();
  const { t } = useTranslation();

  const canSetColor = useMemo(() => {
    return canSetColorBlocks.includes(node.type as EditorNodeType);
  }, [node]);
  const selectedBlockContext = React.useContext(EditorSelectedBlockContext);
  const [openColorMenu, setOpenColorMenu] = React.useState(false);
  const ref = React.useRef<HTMLDivElement>(null);
  const handleClose = useCallback(() => {
    props.onClose?.({}, 'backdropClick');
    ReactEditor.focus(editor);
    try {
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    } catch (e) {
      // do nothing
    }

    editor.collapse({
      edge: 'start',
    });
  }, [editor, node, props]);

  const onConfirm = useCallback(
    (optionKey: string) => {
      switch (optionKey) {
        case 'delete': {
          CustomEditor.deleteNode(editor, node);
          break;
        }

        case 'duplicate': {
          const path = ReactEditor.findPath(editor, node);
          const newNode = CustomEditor.duplicateNode(editor, node);

          handleClose();

          const newBlockId = newNode.blockId;

          if (!newBlockId) return;
          requestAnimationFrame(() => {
            selectedBlockContext.clear();
            selectedBlockContext.add(newBlockId);
            const nextPath = Path.next(path);

            editor.select(nextPath);
            editor.collapse({
              edge: 'start',
            });
          });
          return;
        }

        case 'color': {
          setOpenColorMenu(true);
          return;
        }
      }

      handleClose();
    },
    [editor, handleClose, node, selectedBlockContext]
  );

  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  const options: KeyboardNavigationOption[] = useMemo(
    () =>
      [
        {
          key: 'block-operation',
          children: [
            {
              key: 'delete',
              content: (
                <div className={'flex w-full items-center justify-between gap-2'}>
                  <DeleteSvg className={'h-5 w-5'} />
                  <div className={'flex-1'}>{t('button.delete')}</div>
                  <div className={'text-right text-text-caption'}>{'Del'}</div>
                </div>
              ),
            },
            {
              key: 'duplicate',
              content: (
                <div className={'flex w-full items-center justify-between gap-2'}>
                  <CopySvg className={'h-5 w-5'} />
                  <div className={'flex-1'}>{t('button.duplicate')}</div>
                  <div className={'text-right text-text-caption'}>{`${getModifier()} + D`}</div>
                </div>
              ),
            },
          ],
        },
        canSetColor && {
          key: 'color',
          content: <Divider />,
          children: [
            {
              key: 'color',
              content: (
                <Color
                  node={
                    node as {
                      data?: {
                        font_color?: string;
                        bg_color?: string;
                      };
                    } & Element
                  }
                  onClosePicker={() => {
                    setOpenColorMenu(false);
                  }}
                  openPicker={openColorMenu}
                  onOpenPicker={() => setOpenColorMenu(true)}
                />
              ),
            },
          ],
        },
      ].filter(Boolean),
    [node, canSetColor, openColorMenu, t]
  );

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      e.stopPropagation();
      if (isHotkey('mod+d', e)) {
        e.preventDefault();
        onConfirm('duplicate');
      }

      if (isHotkey('del', e) || isHotkey('backspace', e)) {
        e.preventDefault();
        onConfirm('delete');
      }
    },
    [onConfirm]
  );

  return (
    <Popover
      {...PopoverCommonProps}
      disableAutoFocus={false}
      onMouseDown={(e) => e.stopPropagation()}
      {...props}
      onClose={handleClose}
    >
      <div className={'max-h-[360px] w-full overflow-y-auto py-1'} ref={ref}>
        <KeyboardNavigation
          onKeyDown={handleKeyDown}
          onPressLeft={handleClose}
          onPressRight={(key) => {
            if (key === 'color') {
              onConfirm(key);
            } else {
              handleClose();
            }
          }}
          options={options}
          scrollRef={ref}
          onEscape={handleClose}
          onConfirm={onConfirm}
        />
      </div>
    </Popover>
  );
}

export default BlockOperationMenu;
