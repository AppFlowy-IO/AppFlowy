import { NodeEntry, Element } from 'slate';
import type Y from 'yjs';

export type HistoryStackItem = {
  meta: Map<string, unknown>;
};

export type RelativeRange = {
  anchor: Y.RelativePosition;
  focus: Y.RelativePosition;
  anchorEntry: NodeEntry<Element>;
  focusEntry: NodeEntry<Element>;
};