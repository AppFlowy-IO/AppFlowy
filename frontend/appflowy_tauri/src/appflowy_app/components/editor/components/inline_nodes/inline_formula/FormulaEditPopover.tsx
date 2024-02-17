import React, { useState } from 'react';

import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';

function FormulaEditPopover({
  defaultText,
  open,
  anchorEl,
  onClose,
  onDone,
}: {
  defaultText: string;
  open: boolean;
  anchorEl: HTMLElement | null;
  onClose: () => void;
  onDone: (formula: string) => void;
}) {
  const [text, setText] = useState<string>(defaultText);
  const { t } = useTranslation();

  return (
    <Popover
      {...PopoverCommonProps}
      open={open}
      anchorEl={anchorEl}
      onClose={onClose}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
    >
      <div className='flex gap-1 p-3'>
        <TextField
          variant={'standard'}
          size={'small'}
          autoFocus={true}
          value={text}
          spellCheck={false}
          placeholder={'E = mc^2'}
          onChange={(e) => setText(e.target.value)}
          fullWidth={true}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter') {
              e.preventDefault();
              onDone(text);
            }

            if (e.key === 'Escape') {
              e.preventDefault();
              onClose();
            }

            if (e.key === 'Tab') {
              e.preventDefault();
            }
          }}
        />
        <Button size={'small'} variant={'text'} onClick={() => onDone(text)}>
          {t('button.done')}
        </Button>
      </div>
    </Popover>
  );
}

export default FormulaEditPopover;
