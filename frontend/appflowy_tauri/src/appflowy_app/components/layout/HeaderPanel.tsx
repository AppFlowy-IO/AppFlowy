import { Breadcrumbs } from './Breadcrumbs';
import { PageOptions } from './PageOptions';

export const HeaderPanel = () => {
  return (
    <div className={'flex items-center justify-between px-8 h-[60px] border-b border-shade-6'}>
      <Breadcrumbs></Breadcrumbs>
      <PageOptions></PageOptions>
    </div>
  );
};
