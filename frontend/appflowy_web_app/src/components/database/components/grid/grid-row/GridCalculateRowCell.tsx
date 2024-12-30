import { YjsDatabaseKey } from '@/application/types';
import { useDatabaseView } from '@/application/database-yjs';
import { CalculationType } from '@/application/database-yjs/database.type';
import { CalculationCell, ICalculationCell } from '../grid-calculation-cell';
import React, { useCallback, useEffect, useState } from 'react';

export interface GridCalculateRowCellProps {
  fieldId: string;
}

export function GridCalculateRowCell({ fieldId }: GridCalculateRowCellProps) {
  const databaseView = useDatabaseView();
  const [calculation, setCalculation] = useState<ICalculationCell>();

  const handleObserver = useCallback(() => {
    const calculations = databaseView?.get(YjsDatabaseKey.calculations);

    if (!calculations) return;
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
  }, [databaseView, fieldId]);

  useEffect(() => {
    const observerHandle = () => {
      handleObserver();
    };

    observerHandle();
    databaseView?.observeDeep(handleObserver);

    return () => {
      databaseView?.observeDeep(handleObserver);
    };
  }, [databaseView, fieldId, handleObserver]);
  return <CalculationCell cell={calculation} />;
}

export default GridCalculateRowCell;
