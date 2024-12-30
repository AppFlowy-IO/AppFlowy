import { PanelContext } from '@/components/editor/components/panels/PanelsContext';
import { useContext } from 'react';

export function usePanelContext () {
  const panel = useContext(PanelContext);

  return panel;
}