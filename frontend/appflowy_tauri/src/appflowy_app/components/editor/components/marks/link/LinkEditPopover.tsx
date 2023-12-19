import React, { useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import Button from '@mui/material/Button';
import { getNodePath } from '$app/components/editor/components/editor/utils';
import { addMark, BasePoint, Editor, Transforms, removeMark } from 'slate';
import { EditorStyleFormat } from '$app/application/document/document.types';
import { useSlate } from 'slate-react';
import { ReactComponent as RemoveSvg } from '$app/assets/delete.svg';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { open as openWindow } from '@tauri-apps/api/shell';
import { OutlinedInput } from '@mui/material';
import { notify } from '$app/components/editor/components/tools/notify';

const pattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w.-]*)*\/?$/;

export function LinkEditPopover({
  defaultHref,
  open,
  anchorEl,
  onClose,
}: {
  defaultHref: string;
  open: boolean;
  anchorEl: HTMLElement | null;
  onClose: (at?: BasePoint) => void;
}) {
  const { t } = useTranslation();
  const editor = useSlate();
  const [link, setLink] = useState<string>(defaultHref);

  const setNodeMark = useCallback(() => {
    if (!anchorEl) return;
    const path = getNodePath(editor, anchorEl);

    // select the node before updating the formula
    Transforms.select(editor, path);
    if (link === '') {
      removeMark(editor, EditorStyleFormat.Href);
    } else {
      addMark(editor, EditorStyleFormat.Href, link);
    }

    onClose();
  }, [editor, anchorEl, link, onClose]);

  const removeNodeMark = useCallback(() => {
    if (!anchorEl) return;
    const path = getNodePath(editor, anchorEl);
    const beforePath = Editor.before(editor, path);
    const beforePathEnd = beforePath ? Editor.end(editor, beforePath) : undefined;

    // select the node before updating the formula
    Transforms.select(editor, path);
    editor.removeMark(EditorStyleFormat.Href);

    onClose(beforePathEnd);
  }, [editor, anchorEl, onClose]);

  const linkActions = useMemo(
    () => [
      {
        icon: <LinkSvg />,
        tooltip: t('editor.openLink'),
        onClick: () => {
          void openWindow(link);
        },
        disabled: !pattern.test(link),
      },
      {
        icon: <CopySvg />,
        tooltip: t('editor.copyLink'),
        onClick: async () => {
          await navigator.clipboard.writeText(link);
          notify.success(t('message.copy.success'));
        },
      },
      {
        icon: <RemoveSvg />,
        tooltip: t('editor.removeLink'),
        onClick: removeNodeMark,
      },
    ],
    [link, t, removeNodeMark]
  );

  return (
    <Popover
      {...PopoverCommonProps}
      open={open}
      anchorEl={anchorEl}
      onClose={() => {
        onClose();
      }}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
    >
      <div className='flex flex-col p-2'>
        <OutlinedInput
          size={'small'}
          autoFocus={true}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && link) {
              setNodeMark();
            }
          }}
          className={'my-1 p-0'}
          value={link}
          placeholder={'https://example.com'}
          onChange={(e) => setLink(e.target.value)}
          fullWidth={true}
        />
        <div className={'mt-1 flex w-full flex-col items-start'}>
          {linkActions.map((action, index) => (
            <Button
              key={index}
              disabled={action.disabled}
              className={'w-full justify-start'}
              size={'small'}
              color={'inherit'}
              startIcon={action.icon}
              onClick={action.onClick}
            >
              {action.tooltip}
            </Button>
          ))}
        </div>
      </div>
    </Popover>
  );
}
