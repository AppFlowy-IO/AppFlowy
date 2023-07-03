import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { ContentCopy, Delete } from '@mui/icons-material';
import MenuItem from '../_shared/MenuItem';
import { useBlockMenu } from '$app/components/document/BlockSideToolbar/BlockMenu.hooks';
import BlockMenuTurnInto from '$app/components/document/BlockSideToolbar/BlockMenuTurnInto';
import TextField from '@mui/material/TextField';
import { Keyboard } from '$app/constants/document/keyboard';
import { selectOptionByUpDown } from '$app/utils/document/menu';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { BlockType } from '$app/interfaces/document';

enum BlockMenuOption {
  Duplicate = 'Duplicate',
  Delete = 'Delete',
  TurnInto = 'TurnInto',
}

interface Option {
  operate?: () => Promise<void>;
  title?: string;
  icon?: React.ReactNode;
  key: BlockMenuOption;
}

function BlockMenu({ id, onClose }: { id: string; onClose: () => void }) {
  const { handleDelete, handleDuplicate } = useBlockMenu(id);
  const { node } = useSubscribeNode(id);
  const [subMenuOpened, setSubMenuOpened] = useState(false);
  const [hovered, setHovered] = useState<BlockMenuOption | null>(null);

  useEffect(() => {
    if (hovered !== BlockMenuOption.TurnInto) {
      setSubMenuOpened(false);
    }
  }, [hovered]);

  const handleClick = useCallback(
    async ({ operate }: { operate: () => Promise<void> }) => {
      await operate();
      onClose();
    },
    [onClose]
  );

  const excludeTurnIntoBlock = useMemo(() => {
    return [BlockType.DividerBlock].includes(node.type);
  }, [node.type]);

  const options: Option[] = useMemo(
    () =>
      [
        {
          operate: () => {
            return handleClick({ operate: handleDelete });
          },
          title: 'Delete',
          icon: <Delete />,
          key: BlockMenuOption.Delete,
        },
        {
          operate: () => {
            return handleClick({ operate: handleDuplicate });
          },
          title: 'Duplicate',
          icon: <ContentCopy />,
          key: BlockMenuOption.Duplicate,
        },
        excludeTurnIntoBlock
          ? null
          : {
              key: BlockMenuOption.TurnInto,
            },
      ].filter((item) => item !== null) as Option[],
    [excludeTurnIntoBlock, handleClick, handleDelete, handleDuplicate]
  );

  const onKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      const isUp = e.key === Keyboard.keys.UP;
      const isDown = e.key === Keyboard.keys.DOWN;
      const isLeft = e.key === Keyboard.keys.LEFT;
      const isRight = e.key === Keyboard.keys.RIGHT;
      const isEnter = e.key === Keyboard.keys.ENTER;

      const isArrow = isUp || isDown || isLeft || isRight;

      if (!isArrow && !isEnter) return;
      e.stopPropagation();
      if (isEnter) {
        if (hovered) {
          const option = options.find((option) => option.key === hovered);

          if (option) {
            option.operate?.();
          }
        } else {
          onClose();
        }

        return;
      }

      const optionsKeys = options.map((option) => option.key);

      if (isUp || isDown) {
        const nextKey = selectOptionByUpDown(isUp, hovered, optionsKeys);
        const nextOption = options.find((option) => option.key === nextKey);

        setHovered(nextOption?.key ?? null);
        return;
      }

      if (isLeft || isRight) {
        if (hovered === BlockMenuOption.TurnInto) {
          setSubMenuOpened(isRight);
        }
      }
    },
    [hovered, onClose, options]
  );

  return (
    <div
      tabIndex={1}
      onKeyDown={onKeyDown}
      onMouseDown={(e) => {
        e.stopPropagation();
      }}
    >
      <div className={'p-2'}>
        <TextField autoFocus label='Search' placeholder='Search actions...' variant='standard' />
      </div>
      {options.map((option) => {
        if (option.key === BlockMenuOption.TurnInto) {
          return (
            <BlockMenuTurnInto
              key={option.key}
              onHovered={() => {
                setHovered(BlockMenuOption.TurnInto);
                setSubMenuOpened(true);
              }}
              menuOpened={subMenuOpened}
              isHovered={hovered === BlockMenuOption.TurnInto}
              onClose={() => {
                setSubMenuOpened(false);
                onClose();
              }}
              id={id}
            />
          );
        }

        return (
          <MenuItem
            key={option.key}
            title={option.title}
            icon={option.icon}
            isHovered={hovered === option.key}
            onClick={option.operate}
            onHover={() => {
              setHovered(option.key);
              setSubMenuOpened(false);
            }}
          />
        );
      })}
    </div>
  );
}

export default BlockMenu;
