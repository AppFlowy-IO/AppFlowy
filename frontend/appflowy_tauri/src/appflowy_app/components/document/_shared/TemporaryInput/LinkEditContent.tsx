import React, { useCallback, useMemo, useRef } from 'react';
import TextField from '@mui/material/TextField';
import { IconButton } from '@mui/material';
import { LinkOff, OpenInNew } from '@mui/icons-material';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';
import CopyIcon from '@mui/icons-material/CopyAll';
import { copyText } from '$app/utils/document/copy_paste';
import { open } from '@tauri-apps/api/shell';

function LinkEditContent({
  value,
  onChange,
  onConfirm,
}: {
  value: {
    href?: string;
    text?: string;
  };
  onChange: (val: { href: string; text: string }) => void;
  onConfirm: () => void;
}) {
  const valueRef = useRef<{
    href?: string;
    text?: string;
  }>(value);
  const { t } = useTranslation();
  const onKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        onConfirm();
      }
    },
    [onConfirm]
  );

  const operations = useMemo(
    () => [
      {
        icon: <OpenInNew />,
        tooltip: t('document.inlineLink.openInNewTab'),
        onClick: () => {
          void open(valueRef.current.href || '');
        },
      },
      {
        icon: <CopyIcon />,
        tooltip: t('document.inlineLink.copyLink'),
        onClick: () => {
          void copyText(valueRef.current.href || '');
        },
      },
      {
        icon: <LinkOff />,
        tooltip: t('document.inlineLink.removeLink'),
        onClick: () => {
          onChange({
            href: '',
            text: valueRef.current.text || '',
          });
          onConfirm();
        },
      },
    ],
    [onChange, t, onConfirm]
  );

  return (
    <div className={'flex w-[420px] flex-col items-end p-4'}>
      <div className={'flex w-full items-center justify-end'}>
        {operations.map((operation, index) => (
          <Tooltip placement={'top'} key={index} title={operation.tooltip}>
            <div className={'ml-2 cursor-pointer rounded border border-line-divider'}>
              <IconButton onClick={operation.onClick}>{operation.icon}</IconButton>
            </div>
          </Tooltip>
        ))}
      </div>
      <div className={'flex h-[150px] w-full flex-col justify-between'}>
        <TextField
          autoFocus
          placeholder={t('document.inlineLink.url.placeholder')}
          label={t('document.inlineLink.url.label')}
          onKeyDown={onKeyDown}
          variant='standard'
          value={value.href}
          onChange={(e) => {
            const newVal = e.target.value;

            if (newVal === value.href) return;
            onChange({
              text: value.text || '',
              href: newVal,
            });
          }}
        />
        <TextField
          placeholder={t('document.inlineLink.title.placeholder')}
          label={t('document.inlineLink.title.label')}
          onKeyDown={onKeyDown}
          variant='standard'
          value={value.text}
          onChange={(e) => {
            const newVal = e.target.value;

            if (newVal === value.text) return;
            onChange({
              text: newVal,
              href: value.href || '',
            });
          }}
        />
        <div className={'flex w-full items-center justify-end'}>
          <Button onClick={onConfirm} color='primary'>
            {t('button.save')}
          </Button>
        </div>
      </div>
    </div>
  );
}

export default LinkEditContent;
