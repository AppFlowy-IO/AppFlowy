import { TemplateSummary, TemplateCategory } from '@/application/template.type';
import CreatorAvatar from '@/components/as-template/creator/CreatorAvatar';
import React, { useMemo } from 'react';

const url = import.meta.env.AF_BASE_URL?.includes('test') ? 'https://test.appflowy.io' : 'https://appflowy.io';

function TemplateItem ({ template, category }: { template: TemplateSummary; category: TemplateCategory }) {
  const iframeUrl = useMemo(() => {
    const url = new URL(template.view_url);

    url.searchParams.delete('v');
    url.searchParams.set('theme', 'light');
    url.searchParams.set('template', 'true');
    url.searchParams.set('thumbnail', 'true');
    return url.toString();
  }, [template.view_url]);

  return (
    <>
      <a
        href={`${url}/template-center/${category.id}/${template.view_id}`}
        className={'relative rounded-[16px] pt-4 px-4 h-[230px] w-full overflow-hidden'}
        target={'_blank'}
        style={{
          backgroundColor: category?.bg_color,
        }}
      >
        <iframe loading={'lazy'} className={'w-full h-full'} src={iframeUrl} />
      </a>
      <div className={'template-info'}>
        <div className={'template-creator'}>
          <div className={'avatar'}>
            <CreatorAvatar size={40} src={template.creator.avatar_url} name={template.creator.name} />
          </div>
          <div className={'right-info'}>
            <div className={'template-name'}>{template.name}</div>
            <div className={'creator-name'}>by {template.creator.name}</div>
          </div>
        </div>
        <div className={'template-desc'}>{template.description}</div>
      </div>
    </>
  );
}

export default React.memo(TemplateItem);
