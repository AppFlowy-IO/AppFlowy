use flowy_error::FlowyResult;
use flowy_sync::entities::revision::Revision;
use lib_ot::core::Transaction;

pub struct DeltaRevisionMigration(pub Vec<Revision>);

impl DeltaRevisionMigration {
    pub fn run(self) -> FlowyResult<Transaction> {
        //
        todo!()
    }
}
