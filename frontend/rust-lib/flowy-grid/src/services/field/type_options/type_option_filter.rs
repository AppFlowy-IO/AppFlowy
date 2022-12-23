use crate::services::cell::{AtomicCellDataCache, CellDataDecoder};
use crate::services::field::TypeOption;

pub trait TypeOptionFilter: TypeOption + CellDataDecoder {
    fn filter(&self, cell_data: <Self as TypeOption>::CellData) -> bool;
}

// pub trait TypeOptionCellDataFilterable: TypeOption {
//     fn apply_filter(
//         &self,
//         cell_str: String,
//         filter: &<Self as TypeOptionConfiguration>::CellFilterConfiguration,
//     ) -> FlowyResult<bool>;
// }

pub trait TypeOptionCellDataFilterHandler {
    fn filter_cell_str(&self, cell_str: String, cell_data_cache: Option<AtomicCellDataCache>) -> bool;
}

impl<T> TypeOptionCellDataFilterHandler for T
where
    T: TypeOptionFilter,
{
    fn filter_cell_str(&self, cell_str: String, cell_data_cache: Option<AtomicCellDataCache>) -> bool {
        todo!()
    }
    //
}

// pub trait TypeOptionCellDataFilterable: TypeOption {
//     fn apply_filter(
//         &self,
//         cell_str: String,
//         filter: &<Self as TypeOptionConfiguration>::CellFilterConfiguration,
//     ) -> FlowyResult<bool>;
// }
