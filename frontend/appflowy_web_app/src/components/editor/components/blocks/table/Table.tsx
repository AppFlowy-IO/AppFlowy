import { EditorElementProps, TableCellNode, TableNode } from '@/components/editor/editor.type';
import { getScrollParent } from '@/components/global-comment/utils';
import React, { forwardRef, memo, useEffect, useMemo, useRef, useCallback } from 'react';
import { Grid } from '@atlaskit/primitives';
import './table.scss';
import isEqual from 'lodash-es/isEqual';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { useEditorContext } from '@/components/editor/EditorContext';

const Table = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TableNode>>(({ node, children, className, ...attributes }, ref) => {
    const context = useEditorContext();
    const readSummary = context.readSummary;
    const { rowsLen, colsLen, rowDefaultHeight, colsHeight } = node.data;
    const cells = node.children as TableCellNode[];
    const [width, setWidth] = React.useState<number | undefined>(undefined);
    const offsetLeftRef = useRef(0);

    const columnGroup = useMemo(() => {
      return Array.from({ length: colsLen }, (_, index) => {
        return cells.filter((cell) => cell.data.colPosition === index);
      });
    }, [cells, colsLen]);

    const rowGroup = useMemo(() => {
      return Array.from({ length: rowsLen }, (_, index) => {
        return cells.filter((cell) => cell.data.rowPosition === index);
      });
    }, [cells, rowsLen]);

    const templateColumns = useMemo(() => {
      return columnGroup
        .map((group) => {
          return `${group[0].data.width || colsHeight}px`;
        })
        .join(' ');
    }, [colsHeight, columnGroup]);

    const templateRows = useMemo(() => {
      return rowGroup
        .map((group) => {
          return `${group[0].data.height || rowDefaultHeight}px`;
        })
        .join(' ');
    }, [rowGroup, rowDefaultHeight]);

    const editor = useSlateStatic();

    const calcTableWidth = useCallback((editorDom: HTMLElement, scrollContainer: HTMLElement) => {
      const scrollRect = scrollContainer.getBoundingClientRect();

      setWidth(scrollRect.width);
      offsetLeftRef.current = editorDom.getBoundingClientRect().left - scrollRect.left;
    }, []);

    useEffect(() => {
      if (readSummary) return;
      const editorDom = ReactEditor.toDOMNode(editor, editor);
      const scrollContainer = getScrollParent(editorDom) as HTMLElement;

      if (!scrollContainer) return;
      calcTableWidth(editorDom, scrollContainer);
      const onResize = () => {
        calcTableWidth(editorDom, scrollContainer);
      };

      const resizeObserver = new ResizeObserver(onResize);

      resizeObserver.observe(scrollContainer);
      return () => {
        resizeObserver.disconnect();
      };
    }, [calcTableWidth, editor, readSummary]);

    return (
      <div
        ref={ref}
        {...attributes}
        className={`table-block relative my-2 w-full overflow-hidden px-1 ${className || ''}`}
        style={{
          ...attributes.style,
          width,
          maxWidth: width,
          flex: 'none',
          left: -offsetLeftRef.current,
        }}
      >
        <div
          className={'h-full w-full overflow-x-auto overflow-y-hidden'}
          style={{
            paddingLeft: offsetLeftRef.current + 'px',
          }}
        >
          <Grid
            id={`table-${node.blockId}`}
            rowGap='space.0'
            autoFlow='column'
            columnGap='space.0'
            templateRows={templateRows}
            templateColumns={templateColumns}
          >
            {children}
          </Grid>
        </div>
      </div>
    );
  }),
  (prevProps, nextProps) => isEqual(prevProps.node, nextProps.node)
);

export default Table;
