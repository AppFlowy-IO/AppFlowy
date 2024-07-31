import { PublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import ReplyComment from '@/components/global-comment/ReplyComment';
import { Button, TextareaAutosize } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { memo, useCallback, useContext, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import smoothScrollIntoViewIfNeeded from 'smooth-scroll-into-view-if-needed';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

function AddComment() {
  const { reload, replyCommentId, replyComment: setReplyCommentId } = useGlobalCommentContext();

  const { t } = useTranslation();
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
  const createCommentOnPublishView = useContext(AFConfigContext)?.service?.createCommentOnPublishView;
  const viewId = useContext(PublishContext)?.viewMeta?.view_id;
  const [content, setContent] = React.useState('');
  const [loading, setLoading] = React.useState(false);
  const [focus, setFocus] = React.useState(false);
  const url = window.location.href + '#addComment';

  const ref = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const handleOnFocus = () => {
    setFocus(true);
  };

  useEffect(() => {
    const element = ref.current;

    if (!element) {
      return;
    }

    const hashHasComment = window.location.hash.includes('#addComment');
    const duration = hashHasComment ? 1000 : 200;

    if (hashHasComment || replyCommentId) {
      setTimeout(() => {
        void (async () => {
          window.location.hash = '';

          await smoothScrollIntoViewIfNeeded(element, {
            behavior: 'smooth',
            block: 'nearest',
          });
          inputRef.current?.focus();
        })();
      }, duration);
    }
  }, [replyCommentId]);

  const handleSubmit = useCallback(async () => {
    if (!createCommentOnPublishView || !viewId || loading) {
      return;
    }

    if (!content || content.trim().length === 0) return;

    setLoading(true);
    try {
      await createCommentOnPublishView(viewId, content, replyCommentId || undefined);
      await reload();
      setContent('');

      setReplyCommentId(null);
    } catch (_e) {
      notify.error(t('globalComment.failedToAddComment'));
    } finally {
      setLoading(false);
    }
  }, [createCommentOnPublishView, viewId, loading, content, replyCommentId, reload, setReplyCommentId, t]);

  return (
    <div className={'my-2 flex flex-col gap-2'}>
      <div
        style={{
          backgroundColor: replyCommentId ? 'var(--fill-list-hover)' : undefined,
        }}
        className={'flex flex-col rounded-[8px]'}
      >
        {replyCommentId && (
          <div className={'relative flex items-center gap-2 py-2 pl-2 pr-6'}>
            <span className={'text-sm text-text-caption'}>{t('globalComment.replyingTo')}</span>
            <div className={'flex-1 overflow-hidden'}> {<ReplyComment commentId={replyCommentId} />}</div>

            <div className={'absolute right-2 top-2 cursor-pointer rounded-full p-1 hover:bg-fill-list-hover'}>
              <CloseIcon className={'h-3 w-3 '} onClick={() => setReplyCommentId(null)} />
            </div>
          </div>
        )}

        <div
          ref={ref}
          id={'addComment'}
          style={{
            borderColor: focus ? 'var(--content-blue-400)' : undefined,
            borderWidth: '1.5px',
            scrollMarginTop: '100px',
            borderTopLeftRadius: replyCommentId ? 0 : undefined,
            borderTopRightRadius: replyCommentId ? 0 : undefined,
          }}
          className={
            'flex  w-full w-full transform flex-col gap-4 rounded-[8px] border border-line-divider bg-bg-body px-3 py-1.5 '
          }
        >
          <TextareaAutosize
            minRows={1}
            ref={inputRef}
            autoComplete={'off'}
            spellCheck={false}
            onMouseDown={() => {
              if (!isAuthenticated && openLoginModal) {
                openLoginModal(url);
              }
            }}
            readOnly={!isAuthenticated}
            onFocus={handleOnFocus}
            onBlur={() => setFocus(false)}
            value={content}
            className={'w-full resize-none'}
            onChange={(e) => {
              setContent(e.target.value);
            }}
            placeholder={t('globalComment.addComment')}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey && !e.ctrlKey) {
                e.preventDefault();
                void handleSubmit();
              }

              if (e.key === 'Escape') {
                setContent('');
                setReplyCommentId(null);
              }
            }}
          />
        </div>
      </div>
      {!!content && (
        <div className={'flex items-center justify-end gap-2'}>
          <Button
            onClick={() => {
              inputRef.current?.blur();
              setContent('');
              setReplyCommentId(null);
            }}
            className={'h-7'}
            size={'small'}
            color={'inherit'}
            variant={'outlined'}
          >
            {t('button.cancel')}
          </Button>
          <Button
            className={'h-7'}
            size={'small'}
            disabled={!content || loading}
            onClick={handleSubmit}
            variant={'contained'}
          >
            {loading ? <CircularProgress color={'inherit'} size={20} /> : t('button.add')}
          </Button>
        </div>
      )}
    </div>
  );
}

export default memo(AddComment);
