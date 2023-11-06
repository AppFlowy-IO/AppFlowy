import { styled, Tab, TabProps, Tabs } from '@mui/material';

export const ViewTabs = styled(Tabs)({
  minHeight: '28px',

  '& .MuiTabs-scroller': {
    paddingBottom: '2px',
  }
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
