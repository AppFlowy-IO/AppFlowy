import { ScreenUI } from '../presentation/ScreenUI';
import { ReactNode } from 'react';

export const Screen = ({ children }: { children: ReactNode }) => {
  return <ScreenUI>{children}</ScreenUI>;
};
