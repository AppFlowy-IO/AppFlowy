import React, { useCallback, useMemo, useState } from 'react';
import { SelectOption } from '$app/application/database';
import { IconButton } from '@mui/material';
import { updateChecklistCell } from '$app/application/database/cell/cell_service';
import { useViewId } from '$app/hooks';
import { ReactComponent as DeleteIcon } from '$app/assets/delete.svg';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import isHotkey from 'is-hotkey';
import debounce from 'lodash-es/debounce';
import { useTranslation } from 'react-i18next';

const DELAY_CHANGE = 200;

function ChecklistItem({
  checked,
  option,
  rowId,
  fieldId,
  onClose,
  isSelected,
  onFocus,
}: {
  checked: boolean;
  option: SelectOption;
  rowId: string;
  fieldId: string;
  onClose: () => void;
  isSelected: boolean;
  onFocus: () => void;
}) {
  const inputRef = React.useRef<HTMLInputElement>(null);
  const { t } = useTranslation();
  const [value, setValue] = useState(option.name);
  const viewId = useViewId();
  const updateText = useCallback(async () => {
    await updateChecklistCell(viewId, rowId, fieldId, {
      updateOptions: [
        {
          ...option,
          name: value,
        },
      ],
    });
  }, [fieldId, option, rowId, value, viewId]);

  const onCheckedChange = useMemo(() => {
    return debounce(
      () =>
        updateChecklistCell(viewId, rowId, fieldId, {
          selectedOptionIds: [option.id],
        }),
      DELAY_CHANGE
    );
  }, [fieldId, option.id, rowId, viewId]);

  const deleteOption = useCallback(async () => {
    await updateChecklistCell(viewId, rowId, fieldId, {
      deleteOptionIds: [option.id],
    });
  }, [fieldId, option.id, rowId, viewId]);

  return (
    <div
      style={{
        backgroundColor: isSelected ? 'var(--fill-list-active)' : undefined,
      }}
      className={`checklist-item ${
        isSelected ? 'selected' : ''
      } flex items-center justify-between gap-2 rounded p-1 text-sm hover:bg-fill-list-hover`}
    >
      <div className={'relative cursor-pointer select-none text-content-blue-400'} onClick={onCheckedChange}>
        {checked ? <CheckboxCheckSvg className={'h-5 w-5'} /> : <CheckboxUncheckSvg className={'h-5 w-5'} />}
      </div>

      <input
        className={'flex-1 truncate'}
        ref={inputRef}
        onBlur={updateText}
        value={value}
        onFocus={onFocus}
        placeholder={t('grid.checklist.taskHint')}
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            e.stopPropagation();
            e.preventDefault();
            void updateText();
            onClose();
            return;
          }

          if (e.key === 'Enter') {
            e.stopPropagation();
            e.preventDefault();
            void updateText();
            if (isHotkey('mod+enter', e)) {
              void onCheckedChange();
            }

            return;
          }
        }}
        spellCheck={false}
        onChange={(e) => {
          setValue(e.target.value);
        }}
      />
      <div className={'w-10'}>
        <IconButton size={'small'} className={`delete-option-button z-10 mx-2`} onClick={deleteOption}>
          <DeleteIcon />
        </IconButton>
      </div>
    </div>
  );
}

export default ChecklistItem;
