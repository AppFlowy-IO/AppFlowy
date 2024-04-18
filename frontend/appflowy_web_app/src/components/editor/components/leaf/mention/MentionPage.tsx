import React, { useCallback, useEffect, useState } from 'react';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { useTranslation } from 'react-i18next';
import { useSelected } from 'slate-react';
import { ReactComponent as EyeClose } from '@/assets/eye_close.svg';

function MentionPage({ pageId }: { pageId: string }) {
  const { t } = useTranslation();

  const selected = useSelected();
  const [page, setPage] = useState<{
    icon?: {
      value: string | null;
    };
    name: string;
  } | null>(null);
  const [error, setError] = useState<boolean>(false);
  const loadPage = useCallback(async () => {
    setError(false);
    setPage(null);
    console.log(pageId);
  }, [pageId]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);
  return (
    <span
      className={`mention-inline mx-1 inline-flex select-none items-center gap-1`}
      contentEditable={false}
      style={{
        backgroundColor: selected ? 'var(--content-blue-100)' : undefined,
      }}
    >
      {error ? (
        <>
          <EyeClose />
          <span className={'mr-0.5 text-text-caption underline'}>{t('document.mention.deleted')}</span>
        </>
      ) : (
        page && (
          <>
            {page.icon?.value || <DocumentSvg />}
            <span className={'mr-1 underline'}>{page.name.trim() || t('menuAppHeader.defaultNewPageName')}</span>
          </>
        )
      )}
    </span>
  );
}

export default MentionPage;
