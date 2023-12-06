import React, { useState } from 'react';
import { SelectOption } from '$app/components/database/application';
import { Checkbox, IconButton } from '@mui/material';
import { updateChecklistCell } from '$app/components/database/application/cell/cell_service';
import { useViewId } from '$app/hooks';
import { ReactComponent as DeleteIcon } from '$app/assets/delete.svg';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';

function ChecklistItem({
  checked,
  option,
  rowId,
  fieldId,
}: {
  checked: boolean;
  option: SelectOption;
  rowId: string;
  fieldId: string;
}) {
  const [hover, setHover] = useState(false);
  const [value, setValue] = useState(option.name);
  const viewId = useViewId();
  const updateText = async () => {
    await updateChecklistCell(viewId, rowId, fieldId, {
      updateOptions: [
        {
          ...option,
          name: value,
        },
      ],
    });
  };

  const onCheckedChange = async () => {
    void updateChecklistCell(viewId, rowId, fieldId, {
      selectedOptionIds: [option.id],
    });
  };

  const deleteOption = async () => {
    await updateChecklistCell(viewId, rowId, fieldId, {
      deleteOptionIds: [option.id],
    });
  };

  return (
    <div
      onMouseEnter={() => {
        setHover(true);
      }}
      onMouseLeave={() => {
        setHover(false);
      }}
      className={`flex items-center justify-between gap-2 rounded p-1 text-sm ${hover ? 'bg-fill-list-hover' : ''}`}
    >
      <Checkbox
        onClick={onCheckedChange}
        checked={checked}
        disableRipple
        style={{ padding: 4 }}
        icon={<CheckboxUncheckSvg />}
        checkedIcon={<CheckboxCheckSvg />}
      />
      <input
        className={'flex-1'}
        onBlur={updateText}
        value={value}
        onChange={(e) => {
          setValue(e.target.value);
        }}
      />
      <IconButton size={'small'} className={`mx-2 ${hover ? 'visible' : 'invisible'}`} onClick={deleteOption}>
        <DeleteIcon />
      </IconButton>
    </div>
  );
}

export default ChecklistItem;
