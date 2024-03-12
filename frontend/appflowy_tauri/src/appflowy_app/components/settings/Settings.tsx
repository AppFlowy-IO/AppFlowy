import { useMemo, useState } from 'react';
import { Box, Tab, Tabs } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { MyAccount } from '$app/components/settings/my_account';
import { ReactComponent as AccountIcon } from '$app/assets/settings/account.svg';
import { ReactComponent as WorkplaceIcon } from '$app/assets/settings/workplace.svg';
import { Workplace } from '$app/components/settings/workplace';
import { SettingsRoutes } from '$app/components/settings/workplace/const';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role='tabpanel'
      className={'h-full overflow-y-auto overflow-x-hidden'}
      hidden={value !== index}
      id={`vertical-tabpanel-${index}`}
      aria-labelledby={`vertical-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

export const Settings = ({ onForward }: { onForward: (route: SettingsRoutes) => void }) => {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState(0);

  const tabOptions = useMemo(() => {
    return [
      {
        label: t('newSettings.myAccount.title'),
        Icon: AccountIcon,
        Component: MyAccount,
      },
      {
        label: t('newSettings.workplace.name'),
        Icon: WorkplaceIcon,
        Component: Workplace,
      },
    ];
  }, [t]);

  const handleChangeTab = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  return (
    <Box sx={{ flexGrow: 1, bgcolor: 'background.paper', display: 'flex', height: 224 }}>
      <Tabs
        orientation='vertical'
        variant='scrollable'
        value={activeTab}
        onChange={handleChangeTab}
        className={'w-[212px] min-w-[212px] bg-bg-base px-2 py-4'}
        sx={{
          '& .MuiTabs-indicator': {
            display: 'none',
          },
        }}
      >
        {tabOptions.map((tab, index) => (
          <Tab
            key={index}
            className={'my-1 min-h-[44px] items-start px-4 text-text-title'}
            label={
              <div className={'flex items-center gap-2'}>
                <tab.Icon className={'h-5 w-5'} />
                {tab.label}
              </div>
            }
            onClick={() => setActiveTab(index)}
            sx={{ '&.Mui-selected': { borderColor: 'transparent', backgroundColor: 'var(--fill-list-active)' } }}
          />
        ))}
      </Tabs>
      {tabOptions.map((tab, index) => (
        <TabPanel key={index} value={activeTab} index={index}>
          <tab.Component onForward={onForward} />
        </TabPanel>
      ))}
    </Box>
  );
};
