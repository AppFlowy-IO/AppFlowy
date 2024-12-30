import { Filter } from '@/application/database-yjs';

export interface RelationTypeOption {
  database_id: string;
}

export interface RelationFilter extends Filter {
  condition: number;
}
