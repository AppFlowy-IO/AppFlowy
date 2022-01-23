use crate::core::{Attributes, Delta};
use serde::{
    de::{SeqAccess, Visitor},
    ser::SerializeSeq,
    Deserialize, Deserializer, Serialize, Serializer,
};
use std::{fmt, marker::PhantomData};

impl<T> Serialize for Delta<T>
where
    T: Attributes + Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut seq = serializer.serialize_seq(Some(self.ops.len()))?;
        for op in self.ops.iter() {
            seq.serialize_element(op)?;
        }
        seq.end()
    }
}

impl<'de, T> Deserialize<'de> for Delta<T>
where
    T: Attributes + Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Delta<T>, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OperationSeqVisitor<T>(PhantomData<fn() -> T>);

        impl<'de, T> Visitor<'de> for OperationSeqVisitor<T>
        where
            T: Attributes + Deserialize<'de>,
        {
            type Value = Delta<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a sequence")
            }

            #[inline]
            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut o = Delta::default();
                while let Some(op) = seq.next_element()? {
                    o.add(op);
                }
                Ok(o)
            }
        }

        deserializer.deserialize_seq(OperationSeqVisitor(PhantomData))
    }
}
