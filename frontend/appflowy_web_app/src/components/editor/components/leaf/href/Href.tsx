import { openUrl } from '@/utils/url';
import React, { memo, useEffect, useMemo, useRef } from 'react';
import { Text } from 'slate';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';
import { Popover } from '@/components/_shared/popover';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { IconButton } from '@mui/material';
import { copyTextToClipboard } from '@/utils/copy';
import { YjsEditor } from '@/application/slate-yjs';
import { notify } from '@/components/_shared/notify';
import { useTranslation } from 'react-i18next';
import { debounce } from 'lodash-es';
import { useLeafContext } from '@/components/editor/components/leaf/leaf.hooks';

export const Href = memo(({ text, children, leaf }: { leaf: Text; children: React.ReactNode; text: Text; }) => {
  const readOnly = useReadOnly();
  const {
    linkOpen,
    openLinkPopover,
  } = useLeafContext();
  const [hovered, setHovered] = React.useState(false);
  const ref = useRef<HTMLSpanElement | null>(null);
  const editor = useSlateStatic() as YjsEditor;
  const [selected, setSelected] = React.useState(false);
  const { t } = useTranslation();

  const debounceShow = useMemo(() => {
    return debounce(() => {
      setHovered(true);

    }, 200);
  }, []);

  const debounceHide = useMemo(() => {
    return debounce(() => {
      setHovered(false);
    }, 200);
  }, []);

  useEffect(() => {
    setSelected(linkOpen === text);
  }, [linkOpen, text]);

  return (
    <>
      <span
        ref={ref}
        onMouseEnter={(e) => {
          if (e.buttons > 0) return;
          if (!readOnly) {
            debounceHide.cancel();
            debounceShow();
          }
        }}
        onMouseLeave={() => {
          debounceShow.cancel();
          debounceHide();
        }}
        onClick={() => {
          if (leaf.href) {
            void openUrl(leaf.href, '_blank');
          }
        }}
        style={{
          backgroundColor: selected ? 'var(--content-blue-100)' : undefined,
        }}
        className={`cursor-pointer select-auto py-0.5 text-fill-default underline`}
      >
        {children}
        {hovered && <Popover
          onMouseDown={e => {
            e.stopPropagation();
          }}
          onClick={e => {
            e.stopPropagation();
          }}
          disableRestoreFocus={true}
          disableAutoFocus={true}
          open={hovered}
          anchorEl={ref.current}
          slotProps={{
            root: {
              style: {
                pointerEvents: 'none',
              },
            },
            paper: {
              style: {
                pointerEvents: 'auto',
              },
            },
          }}
          onClose={() => setHovered(false)}
        >
          <div className={'p-2 flex items-center gap-2'}>
            <div className={'text-xs text-text-caption'}>{leaf.href}</div>
            <IconButton onClick={() => {
              if (!leaf.href) return;
              void copyTextToClipboard(leaf.href);
              notify.success(t('document.plugins.urlPreview.copiedToPasteBoard'));
            }} size={'small'}>
              <CopyIcon/>
            </IconButton>
            <IconButton onClick={(e) => {
              if (!ref.current) return;
              e.preventDefault();
              const path = ReactEditor.findPath(editor, text);

              editor.select({
                anchor: editor.start(path),
                focus: editor.end(path),
              });
              ReactEditor.focus(editor);
              setSelected(true);

              setTimeout(() => {
                openLinkPopover?.(text);
              }, 50);
            }} size={'small'}>
              <EditIcon/>
            </IconButton>
          </div>
        </Popover>}
      </span>

    </>
  );
});
