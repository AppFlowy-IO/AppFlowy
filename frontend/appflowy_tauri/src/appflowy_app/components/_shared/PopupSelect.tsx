import { MouseEvent, ReactNode, useRef } from 'react';
import useOutsideClick from './useOutsideClick';

export interface IPopupItem {
  icon: ReactNode | (() => JSX.Element);
  title: string;
  onClick: () => void;
}

export const PopupSelect = ({
  items,
  className = '',
  onOutsideClick,
  columns = 1,
  style,
}: {
  items: IPopupItem[];
  className: string;
  onOutsideClick?: () => void;
  columns?: 1 | 2 | 3;
  style?: any;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  useOutsideClick(ref, () => onOutsideClick && onOutsideClick());

  const handleClick = (e: MouseEvent, item: IPopupItem) => {
    e.stopPropagation();
    item.onClick();
  };

  return (
    <div ref={ref} className={`${className} rounded-lg bg-white px-2 py-2 shadow-md`} style={style}>
      <div
        className={
          (columns === 2 ? 'grid grid-cols-2' : '') + (columns === 3 ? 'grid grid-cols-3' : '') + ' w-full gap-x-4'
        }
      >
        {items.map((item, index) => (
          <button
            key={index}
            className={'flex w-full cursor-pointer items-center gap-2 rounded-lg px-2 py-2 hover:bg-main-secondary'}
            onClick={(e) => handleClick(e, item)}
          >
            <>
              {typeof item.icon === 'function' ? item.icon() : item.icon}
              <span className={'flex-shrink-0'}>{item.title}</span>
            </>
          </button>
        ))}
      </div>
    </div>
  );
};
