import { Breadcrumbs } from './Breadcrumbs';
import { PageOptions } from './PageOptions';

export const HeaderPanel = ({ menuHidden, onShowMenuClick }: { menuHidden: boolean; onShowMenuClick: () => void }) => {
  return (
    <div className={'flex h-[60px] items-center justify-between border-b border-shade-6 px-8'}>
      <Breadcrumbs menuHidden={menuHidden} onShowMenuClick={onShowMenuClick}></Breadcrumbs>
      <PageOptions></PageOptions>
    </div>
  );
};
