import { useRef, useState } from 'react';
import { ArrowRightSvg } from './svg/ArrowRightSvg';
import useOutsideClick from './useOutsideClick';
import { PopupWindow } from './PopupWindow';

type SelectProps = {
  value: string;
  setValue: (v: string) => void;
  options: { name: any; value: string; icon?: any }[];
  label?: string;
  className?: string;
  dropdownClassName?: string;
  disabled?: boolean;
};

export const Select = ({ value, setValue, options, label, className, dropdownClassName, disabled }: SelectProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [popupLeft, setPopupLeft] = useState(0);
  const [popUpTop, setPopUpTop] = useState(0);

  const ref = useRef<HTMLDivElement>(null);

  useOutsideClick(ref, () => {
    setIsOpen(false);
  });

  return (
    <div className={`relative w-full  ${className}`} ref={ref}>
      {label && <label className='text-sm text-shade-3'>{label}</label>}

      <div
        className=' left-0 top-0 flex h-full w-full cursor-pointer items-center justify-between  '
        onClick={() => {
          if (!ref.current) return;
          const { top, left } = ref.current.getBoundingClientRect();

          setPopupLeft(left);
          setPopUpTop(top + 45);
          setIsOpen(!isOpen);
        }}
      >
        {value ? (
          <div className='flex flex-1 gap-2 px-3 py-1 text-shade-3'>
            {options.find((o) => o.value === value)?.icon ? (
              <div className='w-5'>{options.find((o) => o.value === value)?.icon}</div>
            ) : null}

            {options.find((o) => o.value === value)?.name}
          </div>
        ) : (
          <div className='flex-1 px-3 py-2 text-shade-3'>Select</div>
        )}

        <div className={`w-5 text-shade-3 ${isOpen ? 'rotate-90' : ''}`}>
          <ArrowRightSvg />
        </div>
      </div>

      {isOpen && (
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        <PopupWindow left={popupLeft} top={popUpTop} className='' onOutsideClick={() => {}}>
          <div className={`flex flex-col gap-1 ${dropdownClassName} `}>
            {options.map((option, i) => (
              <div
                className={`flex w-full cursor-pointer gap-2 rounded bg-white px-3 py-1  hover:bg-main-secondary ${
                  option.value === value ? '!bg-main-secondary' : ''
                } `}
                onClick={() => {
                  setValue(option.value);
                  setIsOpen(false);
                }}
                key={i}
              >
                {option.icon && <div className='w-5'>{option.icon}</div>}
                {option.name}
              </div>
            ))}
          </div>
        </PopupWindow>
      )}
    </div>
  );
};
