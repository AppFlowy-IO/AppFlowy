import { MouseEvent, ReactNode, useRef } from 'react';
import useOutsideClick from './useOutsideClick';

export interface IPopupItem {
  icon: ReactNode;
  title: string;
  onClick: () => void;
}

export const Popup = ({
  items,
  className = '',
  onOutsideClick,
}: {
  items: IPopupItem[];
  className: string;
  onOutsideClick?: () => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  useOutsideClick(ref, () => onOutsideClick && onOutsideClick());

  const handleClick = (e: MouseEvent, item: IPopupItem) => {
    e.stopPropagation();
    item.onClick();
  };

  return (
    <div ref={ref} className={`${className} px-2 py-2 shadow-md bg-white rounded-lg`}>
      {items.map((item, index) => (
        <button
          key={index}
          className={'flex items-center px-2 py-2 w-full cursor-pointer rounded-lg hover:bg-main-secondary'}
          onClick={(e) => handleClick(e, item)}
        >
          {item.icon}
          <span className={'ml-2'}>{item.title}</span>
        </button>
      ))}
    </div>
  );
};
