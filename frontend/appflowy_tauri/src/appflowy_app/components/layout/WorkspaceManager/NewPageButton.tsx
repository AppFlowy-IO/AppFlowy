import React, { useEffect, useMemo } from 'react';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { useTranslation } from 'react-i18next';
import { WorkspaceController } from '$app/stores/effects/workspace/workspace_controller';
import { ViewLayoutPB } from '@/services/backend';
import { useNavigate } from 'react-router-dom';

function NewPageButton({ workspaceId }: { workspaceId: string }) {
  const { t } = useTranslation();
  const controller = useMemo(() => new WorkspaceController(workspaceId), [workspaceId]);
  const navigate = useNavigate();

  useEffect(() => {
    return () => {
      void controller.dispose();
    };
  }, [controller]);

  return (
    <div className={'flex h-[60px] w-full items-center border-t border-line-divider px-6 py-5'}>
      <button
        onClick={async () => {
          const { id } = await controller.createView({
            name: '',
            layout: ViewLayoutPB.Document,
            parent_view_id: workspaceId,
          });

          navigate(`/page/document/${id}`);
        }}
        className={'flex items-center hover:text-fill-default'}
      >
        <div className={'mr-2 rounded-full bg-fill-default'}>
          <div className={'h-[24px] w-[24px] text-content-on-fill'}>
            <AddSvg />
          </div>
        </div>
        {t('newPageText')}
      </button>
    </div>
  );
}

export default NewPageButton;
