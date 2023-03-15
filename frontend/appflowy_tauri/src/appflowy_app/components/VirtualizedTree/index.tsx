import React, { useCallback, useEffect, useRef } from 'react';
import BlockComponent from '../block/BlockList/BlockComponent';
import { TreeNode } from '../../block_editor/tree_node';
import { VariableSizeList as List } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';

const Row = ({
  node,
  index,
  setSize,
  style,
}: {
  node: TreeNode;
  index: number;
  setSize: (id: string, _index: number, _height: number) => void;
  style?: any;
}) => {
  const rowRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = rowRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    if (!rect) return;
    setSize(node.id, index, rect.height);
  }, []);

  return (
    <div ref={rowRef} style={{ ...style, height: undefined }} key={node.id}>
      <BlockComponent node={node} />
    </div>
  );
};
const VirtualList = ({
  nodes,
  titleInfo,
}: {
  className?: string;
  titleInfo?: {
    height: number;
    component: ({ style }: { style: any }) => React.ReactNode;
  };
  nodes: TreeNode[];
}) => {
  const listRef = useRef<List<any>>(null);
  const virtualNodeRef = useRef<HTMLDivElement>(null);

  const sizeMap = useRef<Record<string, number>>({});
  const setSize = useCallback((id: string, index: number, height: number) => {
    if (!listRef.current) return;
    sizeMap.current = { ...sizeMap.current, [id]: height };
    listRef.current.resetAfterIndex(index);
  }, []);

  const getSize = (node: TreeNode) => {
    return sizeMap.current[node.id] || 50;
  };

  return (
    <div className='h-[100%] w-[100%]'>
      <AutoSizer>
        {({ height, width }) => {
          return (
            <List
              className='doc-scroller-container'
              overscanCount={5}
              ref={listRef}
              width={width}
              height={height}
              itemSize={(i) => getSize(nodes[i])}
              itemCount={nodes.length}
              itemData={nodes}
            >
              {({ data, style, index }: { data: TreeNode[]; style?: any; index: number }) => {
                const _width = width > 900 ? 900 : width;
                const _style = {
                  ...style,
                  top: style?.top + (titleInfo?.height || 0),
                  left: `calc((100% - ${_width}px) / 2)`,
                  width: _width,
                };
                return (
                  <>
                    {index === 0
                      ? titleInfo?.component({
                          style: _style,
                        })
                      : null}
                    <Row style={_style} node={data[index]} index={index} setSize={setSize} />
                  </>
                );
              }}
            </List>
          );
        }}
      </AutoSizer>
      <div ref={virtualNodeRef} className='absolute hidden' />
    </div>
  );
};

export default VirtualList;
