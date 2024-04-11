import React, { useRef, useState } from 'react';
import { ReactComponent as MoreIcon } from '$app/assets/more.svg';
import { SelectOption } from '$app/application/database';
// import { ReactComponent as DragIcon } from '$app/assets/drag.svg';

import { SelectOptionModifyMenu } from '$app/components/database/components/field_types/select/SelectOptionModifyMenu';
import Button from '@mui/material/Button';
import { SelectOptionColorMap } from '$app/components/database/components/field_types/select/constants';

function Option({ option, fieldId }: { option: SelectOption; fieldId: string }) {
  const [expanded, setExpanded] = useState(false);
  const ref = useRef<HTMLButtonElement>(null);

  return (
    <>
      <Button
        size={'small'}
        onClick={() => setExpanded(!expanded)}
        color={'inherit'}
        // startIcon={<DragIcon />}
        endIcon={<MoreIcon className={`transform ${expanded ? '' : 'rotate-90'}`} />}
        ref={ref}
        className={'flex w-full items-center justify-between'}
      >
        <div className={`flex flex-1 justify-start`}>
          <div className={`${SelectOptionColorMap[option.color]} rounded-lg px-1.5 py-1`}>{option.name}</div>
        </div>
      </Button>
      <SelectOptionModifyMenu
        fieldId={fieldId}
        MenuProps={{
          anchorEl: ref.current,
          onClose: () => setExpanded(false),
          open: expanded,
          transformOrigin: {
            vertical: 'center',
            horizontal: 'left',
          },
          anchorOrigin: { vertical: 'center', horizontal: 'right' },
        }}
        option={option}
      />
    </>
  );
}

export default Option;
