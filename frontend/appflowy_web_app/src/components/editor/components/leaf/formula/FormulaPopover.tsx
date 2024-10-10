import { Popover } from '@/components/_shared/popover';
import { IconButton, PopoverPosition, TextField, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SelectCheck } from '@/assets/selected.svg';
import { ReactComponent as Clear } from '@/assets/trash.svg';

function FormulaPopover ({
  open,
  onClose,
  defaultValue,
  anchorPosition,
  onDone,
  onClear,
}: {
  open: boolean,
  onClose: () => void;
  defaultValue: string
  anchorPosition?: PopoverPosition;
  onDone: (value: string) => void;
  onClear: () => void;
}) {
  const { t } = useTranslation();
  const [value, setValue] = React.useState(defaultValue);

  return (
    <Popover
      onClose={onClose}
      open={open}
      disableAutoFocus={true}
      disableEnforceFocus={true}
      disableRestoreFocus={false}
      anchorPosition={anchorPosition}
      anchorReference={'anchorPosition'}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
    >
      <div className={'p-4 flex items-center gap-2'}>
        <TextField
          variant={'standard'}
          size={'small'}
          autoFocus={true}
          value={value}
          spellCheck={false}
          placeholder={'E = mc^2'}
          onChange={(e) => setValue(e.target.value)}
          fullWidth={true}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              onDone(value);
            }

          }}
        />
        <div className={'flex gap-2 items-center justify-end'}>
          <Tooltip
            placement={'top'}
            title={t('button.done')}
          >
            <IconButton
              className={'h-[20px] w-[20px]'}
              size={'small'}
              onClick={() => {

                onDone(value);
              }}
            >
              <SelectCheck className={'text-content-blue-400'} />
            </IconButton>
          </Tooltip>
          <Tooltip
            placement={'top'}
            title={t('button.clear')}
          >
            <IconButton
              className={'h-[20px] w-[20px]'}
              size={'small'}
              color={'error'}
              onClick={onClear}
            >
              <Clear />
            </IconButton>
          </Tooltip>
        </div>
      </div>
    </Popover>
  );
}

export default FormulaPopover;