import React, { useEffect, useRef } from 'react';
import BlockPortal from '$app/components/document/BlockPortal';
import { getNode } from '$app/utils/document/node';
import LanguageIcon from '@mui/icons-material/Language';
import CopyIcon from '@mui/icons-material/CopyAll';
import { copyText } from '$app/utils/document/copy_paste';
import { useMessage } from '$app/components/document/_shared/Message';
import { useTranslation } from 'react-i18next';

const iconSize = {
  width: '1rem',
  height: '1rem',
};

function EditLinkToolbar({
  blockId,
  linkElement,
  onMouseEnter,
  onMouseLeave,
  href,
  editing,
  onEdit,
}: {
  blockId: string;
  linkElement: HTMLAnchorElement;
  href: string;
  onMouseEnter: () => void;
  onMouseLeave: () => void;
  editing: boolean;
  onEdit: () => void;
}) {
  const { t } = useTranslation();
  const { show, contentHolder } = useMessage();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const toolbarDom = ref.current;

    if (!toolbarDom) return;

    const linkRect = linkElement.getBoundingClientRect();
    const node = getNode(blockId);

    if (!node) return;
    const nodeRect = node.getBoundingClientRect();
    const top = linkRect.top - nodeRect.top + linkRect.height + 4;
    const left = linkRect.left - nodeRect.left;

    toolbarDom.style.top = `${top}px`;
    toolbarDom.style.left = `${left}px`;
    toolbarDom.style.opacity = '1';
  });
  return (
    <>
      {editing && (
        <BlockPortal blockId={blockId}>
          <div
            ref={ref}
            onMouseEnter={onMouseEnter}
            onMouseLeave={onMouseLeave}
            style={{
              opacity: 0,
            }}
            className='absolute z-10 inline-flex h-[32px] min-w-[200px] max-w-[400px] items-stretch overflow-hidden rounded-[8px] bg-bg-body leading-tight text-text-title shadow-md transition-opacity duration-100'
          >
            <div className={'flex w-[100%] items-center justify-between px-2 text-[75%]'}>
              <div className={'mr-2'}>
                <LanguageIcon sx={iconSize} />
              </div>
              <div className={'mr-2 flex-1 overflow-hidden text-ellipsis whitespace-nowrap'}>{href}</div>
              <div
                onClick={async () => {
                  try {
                    await copyText(href);
                    show({ message: t('message.copy.success'), duration: 6000 });
                  } catch {
                    show({ message: t('message.copy.fail'), duration: 6000 });
                  }
                }}
                className={'mr-2 cursor-pointer'}
              >
                <CopyIcon sx={iconSize} />
              </div>
              <div onClick={onEdit} className={'cursor-pointer'}>
                {t('button.edit')}
              </div>
            </div>
          </div>
        </BlockPortal>
      )}
      {contentHolder}
    </>
  );
}

export default EditLinkToolbar;
