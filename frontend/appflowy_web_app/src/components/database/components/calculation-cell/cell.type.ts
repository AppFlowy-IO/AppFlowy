import { CalculationType } from '@/application/database-yjs/database.type';

export interface CalulationCell {
  value: string;
  fieldId: string;
  id: string;
  type: CalculationType;
}
