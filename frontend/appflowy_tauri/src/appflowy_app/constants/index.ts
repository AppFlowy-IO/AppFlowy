import { ViewLayoutPB } from '@/services/backend';

export const pageTypeMap = {
  [ViewLayoutPB.Document]: 'document',
  [ViewLayoutPB.Board]: 'board',
  [ViewLayoutPB.Grid]: 'grid',
  [ViewLayoutPB.Calendar]: 'calendar',
};
