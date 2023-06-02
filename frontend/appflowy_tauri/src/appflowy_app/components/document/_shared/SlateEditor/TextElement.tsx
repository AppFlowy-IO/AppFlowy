import { RenderElementProps } from 'slate-react';
import React, { useEffect, useRef } from 'react';

export function TextElement(props: RenderElementProps) {
  const ref = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    if (!ref.current) return;
    amendCodeLeafs(ref.current);
  });

  return (
    <div
      {...props.attributes}
      ref={(e) => {
        ref.current = e;
        props.attributes.ref(e);
      }}
    >
      {props.children}
    </div>
  );
}

function amendCodeLeafs(textElement: Element) {
  const leafNodes = textElement.querySelectorAll(`[data-slate-leaf="true"]`);
  let codeLeafNodes: Element[] = [];
  leafNodes?.forEach((leafNode, index) => {
    const isCodeLeaf = leafNode.classList.contains('inline-code');
    if (isCodeLeaf) {
      codeLeafNodes.push(leafNode);
    } else {
      if (codeLeafNodes.length > 0) {
        addStyleToCodeLeafs(codeLeafNodes);
        codeLeafNodes = [];
      }
    }
    if (codeLeafNodes.length > 0 && index === leafNodes.length - 1) {
      addStyleToCodeLeafs(codeLeafNodes);
      codeLeafNodes = [];
    }
  });
}

function addStyleToCodeLeafs(codeLeafs: Element[]) {
  if (codeLeafs.length === 0) return;
  if (codeLeafs.length === 1) {
    const codeNode = codeLeafs[0].firstChild as Element;
    codeNode.classList.add('rounded', 'px-1.5');
    return;
  }
  codeLeafs.forEach((codeLeaf, index) => {
    const codeNode = codeLeaf.firstChild as Element;
    codeNode.classList.remove('rounded', 'px-1.5');
    codeNode.classList.remove('rounded-l', 'pl-1.5');
    codeNode.classList.remove('rounded-r', 'pr-1.5');
    if (index === 0) {
      codeNode.classList.add('rounded-l', 'pl-1.5');
      return;
    }
    if (index === codeLeafs.length - 1) {
      codeNode.classList.add('rounded-r', 'pr-1.5');
      return;
    }
  });
}
