import { YDoc } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { AFConfigContext } from '@/components/app/AppConfig';
import { DocumentHeader } from '@/components/document/document_header';
import { Editor } from '@/components/editor';
import { EditorLayoutStyle } from '@/components/editor/EditorContext';
import { Log } from '@/utils/log';
import CircularProgress from '@mui/material/CircularProgress';
import React, { Suspense, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import RecordNotFound from 'src/components/_shared/not-found/RecordNotFound';

export const Document = () => {
  const { objectId: documentId } = useId() || {};
  const [doc, setDoc] = useState<YDoc | null>(null);
  const [notFound, setNotFound] = useState<boolean>(false);
  const extra = usePageInfo(documentId).extra;

  const layoutStyle: EditorLayoutStyle = useMemo(() => {
    return {
      font: extra?.font || '',
      fontLayout: extra?.fontLayout,
      lineHeightLayout: extra?.lineHeightLayout,
    };
  }, [extra]);
  const documentService = useContext(AFConfigContext)?.service?.documentService;

  const handleOpenDocument = useCallback(async () => {
    if (!documentService || !documentId) return;
    try {
      setDoc(null);
      const doc = await documentService.openDocument(documentId);

      setDoc(doc);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [documentService, documentId]);

  useEffect(() => {
    setNotFound(false);
    void handleOpenDocument();
  }, [handleOpenDocument]);

  const style = useMemo(() => {
    const fontSizeMap = {
      small: '14px',
      normal: '16px',
      large: '20px',
    };

    return {
      fontFamily: layoutStyle.font,
      fontSize: fontSizeMap[layoutStyle.fontLayout],
    };
  }, [layoutStyle]);

  const layoutClassName = useMemo(() => {
    const classList = [];

    if (layoutStyle.fontLayout === 'large') {
      classList.push('font-large');
    } else if (layoutStyle.fontLayout === 'small') {
      classList.push('font-small');
    }

    if (layoutStyle.lineHeightLayout === 'large') {
      classList.push('line-height-large');
    } else if (layoutStyle.lineHeightLayout === 'small') {
      classList.push('line-height-small');
    }

    return classList.join(' ');
  }, [layoutStyle]);

  useEffect(() => {
    if (!layoutStyle.font) return;
    void window.WebFont?.load({
      google: {
        families: [layoutStyle.font],
      },
    });
  }, [layoutStyle.font]);

  if (!documentId) return null;

  return (
    <>
      {doc ? (
        <div style={style} className={`relative w-full ${layoutClassName}`}>
          <DocumentHeader doc={doc} viewId={documentId} />
          <div className={'flex w-full justify-center'}>
            <Suspense fallback={<ComponentLoading />}>
              <div className={'max-w-screen w-[964px] min-w-0'}>
                <Editor doc={doc} readOnly={true} layoutStyle={layoutStyle} />
              </div>
            </Suspense>
          </div>
        </div>
      ) : (
        <div className={'flex h-full w-full items-center justify-center'}>
          <CircularProgress />
        </div>
      )}

      <RecordNotFound open={notFound} />
    </>
  );
};

export default Document;
