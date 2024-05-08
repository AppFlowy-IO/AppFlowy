import { YjsDatabaseKey } from '@/application/collab.type';
import { useDatabaseView } from '@/application/database-yjs';
import { CalculationType } from '@/application/database-yjs/database.type';
import { CalculationCell } from '@/components/database/components/calculation-cell';
import { CalulationCell } from '@/components/database/components/calculation-cell/cell.type';
import React, { useEffect, useState } from 'react';

export interface GridCalculateRowCellProps {
  fieldId: string;
}

export function GridCalculateRowCell({ fieldId }: GridCalculateRowCellProps) {
  const calculations = useDatabaseView()?.get(YjsDatabaseKey.calculations);
  const [calculation, setCalculation] = useState<CalulationCell>();

  useEffect(() => {
    if (!calculations) return;
    const observerHandle = () => {
      calculations.forEach((calculation) => {
        if (calculation.get(YjsDatabaseKey.field_id) === fieldId) {
          setCalculation({
            id: calculation.get(YjsDatabaseKey.id),
            fieldId: calculation.get(YjsDatabaseKey.field_id),
            value: calculation.get(YjsDatabaseKey.calculation_value),
            type: Number(calculation.get(YjsDatabaseKey.type)) as CalculationType,
          });
        }
      });
    };

    observerHandle();
    calculations.observeDeep(observerHandle);

    return () => {
      calculations.unobserveDeep(observerHandle);
    };
  }, [calculations, fieldId]);
  return <CalculationCell cell={calculation} />;
}

export default GridCalculateRowCell;
