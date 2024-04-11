import React, { useState } from 'react';

import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';
import { IconButton } from '@mui/material';
import { ReactComponent as SelectCheck } from '$app/assets/select-check.svg';
import { ReactComponent as Clear } from '$app/assets/delete.svg';
import Tooltip from '@mui/material/Tooltip';

function FormulaEditPopover({
  defaultText,
  open,
  anchorEl,
  onClose,
  onDone,
  onClear,
}: {
  defaultText: string;
  open: boolean;
  anchorEl: HTMLElement | null;
  onClose: () => void;
  onClear: () => void;
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
      <div className='flex items-center gap-1 p-3'>
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
        <Tooltip placement={'top'} title={t('button.done')}>
          <IconButton className={'h-[20px] w-[20px]'} size={'small'} onClick={() => onDone(text)}>
            <SelectCheck className={'text-content-blue-400'} />
          </IconButton>
        </Tooltip>
        <Tooltip placement={'top'} title={t('button.clear')}>
          <IconButton className={'h-[20px] w-[20px]'} size={'small'} color={'error'} onClick={onClear}>
            <Clear />
          </IconButton>
        </Tooltip>
      </div>
    </Popover>
  );
}

export default FormulaEditPopover;
