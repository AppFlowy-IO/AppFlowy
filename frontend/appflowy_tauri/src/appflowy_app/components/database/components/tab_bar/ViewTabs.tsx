import { styled, Tab, TabProps, Tabs, TabsProps } from '@mui/material';
import { HTMLAttributes } from 'react';

export const ViewTabs = styled((props: TabsProps) => <Tabs {...props} />)({
  minHeight: '28px',

  '& .MuiTabs-scroller': {
    paddingBottom: '2px',
  },
});

export const ViewTab = styled((props: TabProps) => <Tab disableRipple {...props} />)({
  padding: '6px 12px',
  minHeight: '28px',
  fontSize: '12px',
  lineHeight: '16px',
  minWidth: 'unset',
  margin: '4px 0',

  '&.Mui-selected': {
    color: 'inherit',
  },
});

interface TabPanelProps extends HTMLAttributes<HTMLDivElement> {
  children?: React.ReactNode;
  index: number;
  value: number;
}

export function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  const isActivated = value === index;

  return (
    <div
      role='tabpanel'
      hidden={!isActivated}
      id={`full-width-tabpanel-${index}`}
      aria-labelledby={`full-width-tab-${index}`}
      dir={'ltr'}
      {...other}
    >
      {isActivated ? children : null}
    </div>
  );
}
