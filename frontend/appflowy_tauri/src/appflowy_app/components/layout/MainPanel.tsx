import { ReactNode, useEffect, useState } from 'react';
import { HeaderPanel } from './HeaderPanel/HeaderPanel';
import { FooterPanel } from './FooterPanel';
import { ANIMATION_DURATION } from '../_shared/constants';

export const MainPanel = ({
  left,
  menuHidden,
  onShowMenuClick,
  children,
}: {
  left: number;
  menuHidden: boolean;
  onShowMenuClick: () => void;
  children: ReactNode;
}) => {
  const [animation, setAnimation] = useState(false);
  useEffect(() => {
    if (!menuHidden) {
      setTimeout(() => {
        setAnimation(false);
      }, ANIMATION_DURATION);
    } else {
      setAnimation(true);
    }
  }, [menuHidden]);

  return (
    <div
      className={`absolute inset-0 flex h-full flex-1 flex-col`}
      style={{
        transition: menuHidden || animation ? `left ${ANIMATION_DURATION}ms ease-out` : 'none',
        left: `${menuHidden ? 0 : left}px`,
      }}
    >
      <HeaderPanel menuHidden={menuHidden} onShowMenuClick={onShowMenuClick}></HeaderPanel>
      <div className={'min-h-0 flex-1 overflow-auto'}>{children}</div>
      <FooterPanel></FooterPanel>
    </div>
  );
};
