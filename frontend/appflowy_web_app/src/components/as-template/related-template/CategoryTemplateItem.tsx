import { TemplateSummary } from '@/application/template.type';
import { RichTooltip } from '@/components/_shared/popover';
import { Checkbox } from '@mui/material';
import { debounce } from 'lodash-es';
import React, { useMemo } from 'react';

function CategoryTemplateItem ({
  onChange,
  isSelected,
  template,

}: {
  template: TemplateSummary;
  isSelected: boolean;
  onChange: (checked: boolean) => void;
}) {
  const [open, setOpen] = React.useState(false);
  const debounceOpen = useMemo(() => {
    return debounce(() => {
      setOpen(true);
    }, 1000);
  }, []);
  const debounceClose = useMemo(() => {
    return debounce(() => {
      debounceOpen.cancel();
      setOpen(false);
    }, 100);
  }, [debounceOpen]);

  const iframePreview = useMemo(() => {
    const url = new URL(template.view_url);

    url.searchParams.set('theme', 'light');
    url.searchParams.set('template', 'true');
    url.searchParams.set('thumbnail', 'true');

    return <iframe
      onMouseLeave={debounceClose}
      onMouseEnter={() => {
        debounceClose.cancel();
        debounceOpen();
      }}
      loading={'lazy'}
      src={url.toString()}
      className={'aspect-video h-[230px]'}
    />;
  }, [template, debounceOpen, debounceClose]);

  return (
    <div
      key={template.view_id}
      className={`template-item ${isSelected ? 'selected' : ''}`}

    >
      <div className={'flex flex-col gap-1 overflow-hidden'}>
        <div className={'flex items-center overflow-hidden gap-2 w-full '}
        >
          <Checkbox checked={isSelected} onChange={(e) => onChange(e.target.checked)} />
          <RichTooltip placement={'bottom-start'} content={iframePreview} open={open} onClose={debounceClose}>
            <div
              onMouseEnter={() => {
                debounceClose.cancel();
                debounceOpen();
              }}
              onMouseLeave={debounceClose}
              className={'flex-1 hover:underline cursor-pointer whitespace-nowrap truncate font-medium '}
            >{template.name}</div>
          </RichTooltip>

        </div>
      </div>
    </div>
  );
}

export default React.memo(CategoryTemplateItem);