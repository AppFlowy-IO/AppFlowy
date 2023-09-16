import React, { useCallback, useEffect, useMemo } from 'react';
import { TemporaryType, TextAction } from '$app/interfaces/document';
import { getFormatActiveThunk, toggleFormatThunk } from '$app_reducers/document/async-actions/format';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
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
import { useTranslation } from 'react-i18next';
import Tooltip from '@mui/material/Tooltip';

export const iconSize = { width: 18, height: 18 };

const FormatButton = ({ format, icon }: { format: TextAction; icon: string }) => {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const { t } = useTranslation();
  const focusId = useAppSelector((state) => state[RANGE_NAME][docId]?.focus?.id || '');
  const { node: focusNode } = useSubscribeNode(focusId);

  const [isActive, setIsActive] = React.useState(false);
  const color = useMemo(() => (isActive ? 'text-fill-hover' : ''), [isActive]);

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
      const actived = await isFormatActive();

      setIsActive(actived);
    },
    [controller, dispatch, isActive, isFormatActive]
  );

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
      [TextAction.Bold]: t('toolbar.bold'),
      [TextAction.Italic]: t('toolbar.italic'),
      [TextAction.Underline]: t('toolbar.underline'),
      [TextAction.Strikethrough]: t('toolbar.strike'),
      [TextAction.Code]: t('toolbar.inlineCode'),
      [TextAction.Link]: t('toolbar.addLink'),
      [TextAction.Equation]: t('document.plugins.mathEquation.addMathEquation'),
    }),
    [t]
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
          return addTemporaryInput(TemporaryType.Link);
        case TextAction.Equation:
          return addTemporaryInput(TemporaryType.Equation);
      }
    },
    [addTemporaryInput, toggleFormat]
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
          <LinkIcon
            sx={{
              fontSize: '1.2rem',
            }}
          />
        );
      case TextAction.Equation:
        return <Functions sx={iconSize} />;
      default:
        return null;
    }
  }, [icon]);

  return (
    <Tooltip disableInteractive placement={'top'} title={formatTooltips[format]}>
      <div className={`${color} cursor-pointer px-1 hover:text-fill-default`} onClick={() => formatClick(format)}>
        {formatIcon}
      </div>
    </Tooltip>
  );
};

export default FormatButton;
