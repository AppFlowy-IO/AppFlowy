import IconButton from '@mui/material/IconButton';
import FormatIcon from './FormatIcon';
import React, { useCallback, useEffect, useMemo, useContext } from 'react';
import { TextAction } from '$app/interfaces/document';
import MenuTooltip from '$app/components/document/TextActionMenu/menu/MenuTooltip';
import { getFormatActiveThunk, toggleFormatThunk } from '$app_reducers/document/async-actions/format';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { newLinkThunk } from '$app_reducers/document/async-actions/link';

const FormatButton = ({ format, icon }: { format: TextAction; icon: string }) => {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const docId = controller.documentId;

  const focusId = useAppSelector((state) => state.documentRange[docId]?.focus?.id || '');
  const { node: focusNode } = useSubscribeNode(focusId);

  const [isActive, setIsActive] = React.useState(false);
  const color = useMemo(() => (isActive ? '#00BCF0' : 'white'), [isActive]);

  const formatTooltips: Record<string, string> = useMemo(
    () => ({
      [TextAction.Bold]: 'Bold',
      [TextAction.Italic]: 'Italic',
      [TextAction.Underline]: 'Underline',
      [TextAction.Strikethrough]: 'Strike through',
      [TextAction.Code]: 'Mark as Code',
      [TextAction.Link]: 'Add Link',
    }),
    []
  );

  const isFormatActive = useCallback(async () => {
    if (!focusNode) return false;
    const { payload: isActive } = await dispatch(
      getFormatActiveThunk({
        format,
        docId,
      })
    );
    return !!isActive;
  }, [docId, dispatch, format, focusNode]);

  const toggleFormat = useCallback(
    async (format: TextAction) => {
      if (!controller) return;
      await dispatch(
        toggleFormatThunk({
          format,
          controller,
          isActive,
        })
      );
    },
    [controller, dispatch, isActive]
  );

  const addLink = useCallback(() => {
    dispatch(
      newLinkThunk({
        docId,
      })
    );
  }, [dispatch, docId]);

  const formatClick = useCallback(
    (format: TextAction) => {
      switch (format) {
        case TextAction.Bold:
        case TextAction.Italic:
        case TextAction.Underline:
        case TextAction.Strikethrough:
        case TextAction.Code:
          return toggleFormat(format);
        case TextAction.Link:
          return addLink();
      }
    },
    [addLink, toggleFormat]
  );

  useEffect(() => {
    void (async () => {
      const isActive = await isFormatActive();
      setIsActive(isActive);
    })();
  }, [isFormatActive]);

  return (
    <MenuTooltip title={formatTooltips[format]}>
      <IconButton size='small' sx={{ color }} onClick={() => formatClick(format)}>
        <FormatIcon icon={icon} />
      </IconButton>
    </MenuTooltip>
  );
};

export default FormatButton;
