import { Breadcrumbs } from './Breadcrumbs';
import { PageOptions } from './PageOptions';

export const HeaderPanel = () => {
  return (
    <div className={'flex h-[60px] items-center justify-between border-b border-shade-6 px-8'}>
      <Breadcrumbs></Breadcrumbs>
      <PageOptions></PageOptions>
    </div>
  );
};
