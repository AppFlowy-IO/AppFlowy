import { FC, useCallback, useMemo, useRef, useState } from 'react';
import { Field as FieldType } from '$app/application/database';
import { useDatabase } from '../../Database.hooks';
import { Property } from './Property';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { ReactComponent as DropDownSvg } from '$app/assets/more.svg';
import Popover from '@mui/material/Popover';

export interface FieldSelectProps {
  onChange?: (field: FieldType | undefined) => void;
  value?: string;
}

export const PropertySelect: FC<FieldSelectProps> = ({ value, onChange }) => {
  const { fields } = useDatabase();

  const scrollRef = useRef<HTMLDivElement>(null);
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const handleClose = () => {
    setOpen(false);
  };

  const options: KeyboardNavigationOption[] = useMemo(
    () =>
      fields.map((field) => {
        return {
          key: field.id,
          content: <Property field={field} />,
        };
      }),
    [fields]
  );

  const onConfirm = useCallback(
    (optionKey: string) => {
      onChange?.(fields.find((field) => field.id === optionKey));
    },
    [onChange, fields]
  );

  const selectedField = useMemo(() => fields.find((field) => field.id === value), [fields, value]);

  return (
    <>
      <div
        ref={ref}
        style={{
          borderColor: open ? 'var(--fill-default)' : undefined,
        }}
        className={
          'flex w-[150px] cursor-pointer items-center justify-between gap-2 rounded border border-line-border p-2 hover:border-text-title'
        }
        onClick={() => {
          setOpen(true);
        }}
      >
        <div className={'flex-1'}>{selectedField ? <Property field={selectedField} /> : null}</div>
        <DropDownSvg className={'h-4 w-4 rotate-90 transform'} />
      </div>
      {open && (
        <Popover
          open={open}
          anchorEl={ref.current}
          onClose={handleClose}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
          transformOrigin={{ vertical: 'top', horizontal: 'left' }}
        >
          <div ref={scrollRef} className={'my-2 max-h-[300px] w-[150px] overflow-y-auto'}>
            <KeyboardNavigation
              defaultFocusedKey={value}
              scrollRef={scrollRef}
              options={options}
              onEscape={handleClose}
              onConfirm={onConfirm}
            />
          </div>
        </Popover>
      )}
    </>
  );
};
