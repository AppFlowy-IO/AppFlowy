import IconButton from '@mui/material/IconButton';
import React, { useCallback, useEffect, useMemo } from 'react';
import { TemporaryType, TextAction } from '$app/interfaces/document';
import MenuTooltip from '$app/components/document/TextActionMenu/menu/MenuTooltip';
import { getFormatActiveThunk, toggleFormatThunk } from '$app_reducers/document/async-actions/format';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { newLinkThunk } from '$app_reducers/document/async-actions/link';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { RANGE_NAME } from '$app/constants/document/name';
import { createTemporary } from '$app_reducers/document/async-actions/temporary';
import {
  CodeOutlined,
  FormatBold,
  FormatItalic,
  FormatUnderlined,
  Functions,
  StrikethroughSOutlined,
} from '@mui/icons-material';
import LinkIcon from '@mui/icons-material/AddLink';

export const iconSize = { width: 18, height: 18 };

const FormatButton = ({ format, icon }: { format: TextAction; icon: string }) => {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();

  const focusId = useAppSelector((state) => state[RANGE_NAME][docId]?.focus?.id || '');
  const { node: focusNode } = useSubscribeNode(focusId);

  const [isActive, setIsActive] = React.useState(false);
  const color = useMemo(() => (isActive ? '#00BCF0' : 'white'), [isActive]);

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

  const addTemporaryInput = useCallback(
    (type: TemporaryType) => {
      dispatch(createTemporary({ type, docId }));
    },
    [dispatch, docId]
  );

  useEffect(() => {
    void (async () => {
      const isActive = await isFormatActive();

      setIsActive(isActive);
    })();
  }, [isFormatActive]);

  const formatTooltips: Record<string, string> = useMemo(
    () => ({
      [TextAction.Bold]: 'Bold',
      [TextAction.Italic]: 'Italic',
      [TextAction.Underline]: 'Underline',
      [TextAction.Strikethrough]: 'Strike through',
      [TextAction.Code]: 'Mark as Code',
      [TextAction.Link]: 'Add Link',
      [TextAction.Equation]: 'Create equation',
    }),
    []
  );

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
        case TextAction.Equation:
          return addTemporaryInput(TemporaryType.Equation);
      }
    },
    [addLink, addTemporaryInput, toggleFormat]
  );

  const formatIcon = useMemo(() => {
    switch (icon) {
      case TextAction.Bold:
        return <FormatBold sx={iconSize} />;
      case TextAction.Underline:
        return <FormatUnderlined sx={iconSize} />;
      case TextAction.Italic:
        return <FormatItalic sx={iconSize} />;
      case TextAction.Code:
        return <CodeOutlined sx={iconSize} />;
      case TextAction.Strikethrough:
        return <StrikethroughSOutlined sx={iconSize} />;
      case TextAction.Link:
        return (
          <div className={'flex items-center justify-center px-1 text-[0.8rem]'}>
            <LinkIcon
              sx={{
                fontSize: '1.2rem',
                marginRight: '0.25rem',
              }}
            />
            <div className={'underline'}>Link</div>
          </div>
        );
      case TextAction.Equation:
        return <Functions sx={iconSize} />;
      default:
        return null;
    }
  }, [icon]);

  return (
    <MenuTooltip title={formatTooltips[format]}>
      <IconButton size='small' sx={{ color }} onClick={() => formatClick(format)}>
        {formatIcon}
      </IconButton>
    </MenuTooltip>
  );
};

export default FormatButton;
