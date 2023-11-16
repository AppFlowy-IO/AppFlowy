import { styled, Tab, TabProps, Tabs } from '@mui/material';

export const ViewTabs = styled(Tabs)({
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

  '&.Mui-selected': {
    color: 'inherit',
  },
});

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

export function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role='tabpanel'
      hidden={value !== index}
      id={`full-width-tabpanel-${index}`}
      aria-labelledby={`full-width-tab-${index}`}
      dir={'ltr'}
      {...other}
    >
      {value === index && children}
    </div>
  );
}
