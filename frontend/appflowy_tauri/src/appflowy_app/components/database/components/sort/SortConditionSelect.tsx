import { FC, useMemo, useRef, useState } from 'react';
import { SortConditionPB } from '@/services/backend';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { Popover } from '@mui/material';
import { ReactComponent as DropDownSvg } from '$app/assets/more.svg';
import { useTranslation } from 'react-i18next';

export const SortConditionSelect: FC<{
  onChange?: (value: SortConditionPB) => void;
  value?: SortConditionPB;
}> = ({ onChange, value }) => {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const handleClose = () => {
    setOpen(false);
  };

  const options: KeyboardNavigationOption<SortConditionPB>[] = useMemo(() => {
    return [
      {
        key: SortConditionPB.Ascending,
        content: t('grid.sort.ascending'),
      },
      {
        key: SortConditionPB.Descending,
        content: t('grid.sort.descending'),
      },
    ];
  }, [t]);

  const onConfirm = (optionKey: SortConditionPB) => {
    onChange?.(optionKey);
    handleClose();
  };

  const selectedField = useMemo(() => options.find((option) => option.key === value), [options, value]);

  return (
    <>
      <div
        ref={ref}
        style={{
          borderColor: open ? 'var(--fill-default)' : undefined,
        }}
        className={
          'flex w-[150px] cursor-pointer items-center justify-between gap-2 rounded border border-line-border p-2 text-xs hover:border-text-title'
        }
        onClick={() => {
          setOpen(true);
        }}
      >
        <div className={'flex-1'}>{selectedField?.content}</div>
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
          <div className={'my-2 w-[150px]'}>
            <KeyboardNavigation
              defaultFocusedKey={value}
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
