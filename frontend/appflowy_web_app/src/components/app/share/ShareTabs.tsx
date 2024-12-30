import { useAppView } from '@/components/app/app.hooks';
import PublishPanel from '@/components/app/share/PublishPanel';
import TemplatePanel from '@/components/app/share/TemplatePanel';
import SharePanel from '@/components/app/share/SharePanel';
import { useCurrentUser } from '@/components/main/app.hooks';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ViewTabs, ViewTab, TabPanel } from 'src/components/_shared/tabs/ViewTabs';
import { ReactComponent as Templates } from '@/assets/template.svg';
import { ReactComponent as PublishedWithChanges } from '@/assets/published_with_changes.svg';

enum TabKey {
  SHARE = 'share',
  PUBLISH = 'publish',
  TEMPLATE = 'template',
}

function ShareTabs({ viewId }: { viewId: string }) {
  const { t } = useTranslation();
  const view = useAppView(viewId);
  const [value, setValue] = React.useState<TabKey>(TabKey.SHARE);
  const currentUser = useCurrentUser();

  const options = useMemo(() => {
    return [{
      value: TabKey.SHARE,
      label: t('shareAction.shareTab'),
      Panel: SharePanel,
    }, {
      value: TabKey.PUBLISH,
      label: t('shareAction.publish'),
      icon: view?.is_published ? <PublishedWithChanges className={'w-4 h-4 text-function-success mb-0'}/> : undefined,
      Panel: PublishPanel,
    }, currentUser?.email?.endsWith('appflowy.io') && view?.is_published && {
      value: TabKey.TEMPLATE,
      label: t('template.asTemplate'),
      icon: <Templates className={'w-4 h-4 mb-0'}/>,
      Panel: TemplatePanel,
    }].filter(Boolean) as {
      value: TabKey;
      label: string;
      icon?: React.JSX.Element;
      Panel: React.FC<{ viewId: string }>
    }[];

  }, [currentUser?.email, t, view?.is_published]);

  const onChange = useCallback((_event: React.SyntheticEvent, newValue: TabKey) => {
    setValue(newValue);
  }, []);

  return (
    <>
      <ViewTabs
        className={'border-b border-line-divider'}
        onChange={onChange}
        value={value}
      >
        {options.map((option) => (
          <ViewTab
            className={'flex items-center flex-row justify-center gap-1.5'}
            key={option.value}
            value={option.value}
            label={option.label}
            icon={option.icon}
          />
        ))}
      </ViewTabs>
      <div className={'p-2'}>
        {options.map((option) => (
          <TabPanel
            className={'min-w-[460px] max-sm:min-w-[80vw]'}
            key={option.value}
            index={option.value}
            value={value}
          >
            <option.Panel viewId={viewId}/>
          </TabPanel>
        ))}
      </div>

    </>

  );
}

export default ShareTabs;