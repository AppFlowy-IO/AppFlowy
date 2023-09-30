import { MouseEventHandler, MouseEvent, ReactNode, useEffect, useState } from 'react';

export const Button = ({
  size = 'primary',
  children,
  onClick,
}: {
  size?: 'primary' | 'medium' | 'small' | 'box-small-transparent' | 'medium-transparent';
  children: ReactNode;
  onClick?: MouseEventHandler<HTMLButtonElement>;
}) => {
  const [cls, setCls] = useState('');

  useEffect(() => {
    switch (size) {
      case 'primary':
        setCls('w-[340px] h-[48px] flex items-center justify-center rounded-lg bg-fill-default text-content-on-fill');
        break;
      case 'medium':
        setCls('w-[170px] h-[48px] flex items-center justify-center rounded-lg bg-fill-default text-content-on-fill');
        break;
      case 'small':
        setCls(
          'w-[68px] h-[32px] flex items-center justify-center rounded-lg bg-fill-default text-content-on-fill text-xs hover:bg-fill-list-hover'
        );
        break;
      case 'medium-transparent':
        setCls(
          'w-[170px] h-[48px] flex items-center justify-center rounded-lg border border-fill-default text-fill-default transition-colors duration-300 hover:bg-content-blue-50 '
        );
        break;
      case 'box-small-transparent':
        setCls('text-icon-default w-[24px] h-[24px] rounded hover:bg-fill-list-hover');
        break;
    }
  }, [size]);

  const handleClick = (e: MouseEvent<HTMLButtonElement>) => {
    e.stopPropagation();
    onClick && onClick(e);
  };

  return (
    <button className={cls} onClick={(e) => handleClick(e)}>
      {children}
    </button>
  );
};
