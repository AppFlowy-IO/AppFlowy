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
      <div className='flex p-2 '>
        <TextField
          variant={'standard'}
          size={'small'}
          autoFocus={true}
          value={text}
          placeholder={'E = mc^2'}
          onChange={(e) => setText(e.target.value)}
          fullWidth={true}
        />
        <div className={'ml-2'}>
          <Button size={'small'} variant={'text'} onClick={() => onDone(text)}>
            {t('button.done')}
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default FormulaEditPopover;
