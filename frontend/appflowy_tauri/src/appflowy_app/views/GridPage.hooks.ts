import {
  CellIdPB,
  DatabaseEventGetCell,
  DatabaseEventGetDatabase,
  DatabaseIdPB,
} from '../../services/backend/events/flowy-database';

export const useGrid = () => {
  const loadGrid = async (id: string) => {
    const getDatabaseResult = await DatabaseEventGetDatabase(
      DatabaseIdPB.fromObject({
        value: id,
      })
    );

    if (getDatabaseResult.ok) {
      const pb4 = getDatabaseResult.val;
      console.log(pb4.fields);
      console.log(pb4.rows);
      {
        const getCellResult = await DatabaseEventGetCell(
          CellIdPB.fromObject({
            database_id: id,
            field_id: pb4.fields[1].field_id,
            row_id: pb4.rows[0].id,
          })
        );
        if (getCellResult.ok) {
          const pb5 = getCellResult.val;
          console.log(pb5.toObject());
          // const des = RichTextTypeOptionPB.deserialize(pb5.data);
          // console.log(des);
        } else {
          throw new Error('get cell error');
        }
      }
      {
        const getCellResult = await DatabaseEventGetCell(
          CellIdPB.fromObject({
            database_id: id,
            field_id: pb4.fields[1].field_id,
            row_id: pb4.rows[2].id,
          })
        );
        if (getCellResult.ok) {
          const pb5 = getCellResult.val;
          console.log(pb5.toObject());
          // const des = RichTextTypeOptionPB.deserialize(pb5.data);
          // console.log(des);
        } else {
          throw new Error('get cell error');
        }
      }
    } else {
      throw new Error('get database error');
    }
  };

  return {
    loadGrid,
  };
};
