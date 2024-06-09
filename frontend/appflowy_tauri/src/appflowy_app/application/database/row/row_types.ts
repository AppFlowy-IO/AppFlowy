import { RowMetaPB } from '@/services/backend';

export interface RowMeta {
  id: string;
  documentId?: string;
  icon?: string;
  cover?: string;
  isHidden?: boolean;
}

export function pbToRowMeta(pb: RowMetaPB): RowMeta {
  const rowMeta: RowMeta = {
    id: pb.id,
  };

  if (pb.document_id) {
    rowMeta.documentId = pb.document_id;
  }

  if (pb.icon) {
    rowMeta.icon = pb.icon;
  }

  if (pb.cover) {
    rowMeta.cover = pb.cover;
  }

  return rowMeta;
}
