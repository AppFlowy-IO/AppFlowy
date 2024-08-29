import { TemplateSummary, TemplateCategory } from '@/application/template.type';
import CreatorAvatar from '@/components/as-template/creator/CreatorAvatar';
import React, { useMemo } from 'react';

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
      <div
        className={'relative rounded-[16px] pt-4 px-4 h-[230px] w-full overflow-hidden'}
        style={{
          backgroundColor: category?.bg_color,
        }}
      >
        <iframe loading={'lazy'} className={'w-full h-full'} src={iframeUrl} />
      </div>
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
