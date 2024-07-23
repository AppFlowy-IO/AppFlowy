import { styled, Tab, TabProps, Tabs, TabsProps } from '@mui/material';
import { HTMLAttributes } from 'react';

export const ViewTabs = styled((props: TabsProps) => <Tabs {...props} />)({
  minHeight: '28px',

  '& .MuiTabs-scroller': {
    paddingBottom: '2px',
  },
});

export const ViewTab = styled((props: TabProps) => <Tab disableRipple {...props} />)({
  padding: '0 12px',
  minHeight: '24px',
  fontSize: '16px',
  minWidth: 'unset',
  margin: '4px 0',
  borderRadius: 0,
  '&:hover': {
    backgroundColor: 'transparent !important',
    color: 'inherit',
  },
  '&.Mui-selected': {
    color: 'inherit',
    backgroundColor: 'transparent',
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
