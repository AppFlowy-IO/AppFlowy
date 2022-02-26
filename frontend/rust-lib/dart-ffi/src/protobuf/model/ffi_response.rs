// This file is generated by rust-protobuf 2.25.2. Do not edit
// @generated

// https://github.com/rust-lang/rust-clippy/issues/702
#![allow(unknown_lints)]
#![allow(clippy::all)]

#![allow(unused_attributes)]
#![cfg_attr(rustfmt, rustfmt::skip)]

#![allow(box_pointers)]
#![allow(dead_code)]
#![allow(missing_docs)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]
#![allow(trivial_casts)]
#![allow(unused_imports)]
#![allow(unused_results)]
//! Generated file from `ffi_response.proto`

/// Generated files are compatible only with the same version
/// of protobuf runtime.
// const _PROTOBUF_VERSION_CHECK: () = ::protobuf::VERSION_2_25_2;

#[derive(PartialEq,Clone,Default)]
pub struct FFIResponse {
    // message fields
    pub payload: ::std::vec::Vec<u8>,
    pub code: FFIStatusCode,
    // special fields
    pub unknown_fields: ::protobuf::UnknownFields,
    pub cached_size: ::protobuf::CachedSize,
}

impl<'a> ::std::default::Default for &'a FFIResponse {
    fn default() -> &'a FFIResponse {
        <FFIResponse as ::protobuf::Message>::default_instance()
    }
}

impl FFIResponse {
    pub fn new() -> FFIResponse {
        ::std::default::Default::default()
    }

    // bytes payload = 1;


    pub fn get_payload(&self) -> &[u8] {
        &self.payload
    }
    pub fn clear_payload(&mut self) {
        self.payload.clear();
    }

    // Param is passed by value, moved
    pub fn set_payload(&mut self, v: ::std::vec::Vec<u8>) {
        self.payload = v;
    }

    // Mutable pointer to the field.
    // If field is not initialized, it is initialized with default value first.
    pub fn mut_payload(&mut self) -> &mut ::std::vec::Vec<u8> {
        &mut self.payload
    }

    // Take field
    pub fn take_payload(&mut self) -> ::std::vec::Vec<u8> {
        ::std::mem::replace(&mut self.payload, ::std::vec::Vec::new())
    }

    // .FFIStatusCode code = 2;


    pub fn get_code(&self) -> FFIStatusCode {
        self.code
    }
    pub fn clear_code(&mut self) {
        self.code = FFIStatusCode::Ok;
    }

    // Param is passed by value, moved
    pub fn set_code(&mut self, v: FFIStatusCode) {
        self.code = v;
    }
}

impl ::protobuf::Message for FFIResponse {
    fn is_initialized(&self) -> bool {
        true
    }

    fn merge_from(&mut self, is: &mut ::protobuf::CodedInputStream<'_>) -> ::protobuf::ProtobufResult<()> {
        while !is.eof()? {
            let (field_number, wire_type) = is.read_tag_unpack()?;
            match field_number {
                1 => {
                    ::protobuf::rt::read_singular_proto3_bytes_into(wire_type, is, &mut self.payload)?;
                },
                2 => {
                    ::protobuf::rt::read_proto3_enum_with_unknown_fields_into(wire_type, is, &mut self.code, 2, &mut self.unknown_fields)?
                },
                _ => {
                    ::protobuf::rt::read_unknown_or_skip_group(field_number, wire_type, is, self.mut_unknown_fields())?;
                },
            };
        }
        ::std::result::Result::Ok(())
    }

    // Compute sizes of nested messages
    #[allow(unused_variables)]
    fn compute_size(&self) -> u32 {
        let mut my_size = 0;
        if !self.payload.is_empty() {
            my_size += ::protobuf::rt::bytes_size(1, &self.payload);
        }
        if self.code != FFIStatusCode::Ok {
            my_size += ::protobuf::rt::enum_size(2, self.code);
        }
        my_size += ::protobuf::rt::unknown_fields_size(self.get_unknown_fields());
        self.cached_size.set(my_size);
        my_size
    }

    fn write_to_with_cached_sizes(&self, os: &mut ::protobuf::CodedOutputStream<'_>) -> ::protobuf::ProtobufResult<()> {
        if !self.payload.is_empty() {
            os.write_bytes(1, &self.payload)?;
        }
        if self.code != FFIStatusCode::Ok {
            os.write_enum(2, ::protobuf::ProtobufEnum::value(&self.code))?;
        }
        os.write_unknown_fields(self.get_unknown_fields())?;
        ::std::result::Result::Ok(())
    }

    fn get_cached_size(&self) -> u32 {
        self.cached_size.get()
    }

    fn get_unknown_fields(&self) -> &::protobuf::UnknownFields {
        &self.unknown_fields
    }

    fn mut_unknown_fields(&mut self) -> &mut ::protobuf::UnknownFields {
        &mut self.unknown_fields
    }

    fn as_any(&self) -> &dyn (::std::any::Any) {
        self as &dyn (::std::any::Any)
    }
    fn as_any_mut(&mut self) -> &mut dyn (::std::any::Any) {
        self as &mut dyn (::std::any::Any)
    }
    fn into_any(self: ::std::boxed::Box<Self>) -> ::std::boxed::Box<dyn (::std::any::Any)> {
        self
    }

    fn descriptor(&self) -> &'static ::protobuf::reflect::MessageDescriptor {
        Self::descriptor_static()
    }

    fn new() -> FFIResponse {
        FFIResponse::new()
    }

    fn descriptor_static() -> &'static ::protobuf::reflect::MessageDescriptor {
        static descriptor: ::protobuf::rt::LazyV2<::protobuf::reflect::MessageDescriptor> = ::protobuf::rt::LazyV2::INIT;
        descriptor.get(|| {
            let mut fields = ::std::vec::Vec::new();
            fields.push(::protobuf::reflect::accessor::make_simple_field_accessor::<_, ::protobuf::types::ProtobufTypeBytes>(
                "payload",
                |m: &FFIResponse| { &m.payload },
                |m: &mut FFIResponse| { &mut m.payload },
            ));
            fields.push(::protobuf::reflect::accessor::make_simple_field_accessor::<_, ::protobuf::types::ProtobufTypeEnum<FFIStatusCode>>(
                "code",
                |m: &FFIResponse| { &m.code },
                |m: &mut FFIResponse| { &mut m.code },
            ));
            ::protobuf::reflect::MessageDescriptor::new_pb_name::<FFIResponse>(
                "FFIResponse",
                fields,
                file_descriptor_proto()
            )
        })
    }

    fn default_instance() -> &'static FFIResponse {
        static instance: ::protobuf::rt::LazyV2<FFIResponse> = ::protobuf::rt::LazyV2::INIT;
        instance.get(FFIResponse::new)
    }
}

impl ::protobuf::Clear for FFIResponse {
    fn clear(&mut self) {
        self.payload.clear();
        self.code = FFIStatusCode::Ok;
        self.unknown_fields.clear();
    }
}

impl ::std::fmt::Debug for FFIResponse {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        ::protobuf::text_format::fmt(self, f)
    }
}

impl ::protobuf::reflect::ProtobufValue for FFIResponse {
    fn as_ref(&self) -> ::protobuf::reflect::ReflectValueRef {
        ::protobuf::reflect::ReflectValueRef::Message(self)
    }
}

#[derive(Clone,PartialEq,Eq,Debug,Hash)]
pub enum FFIStatusCode {
    Ok = 0,
    Err = 1,
    Internal = 2,
}

impl ::protobuf::ProtobufEnum for FFIStatusCode {
    fn value(&self) -> i32 {
        *self as i32
    }

    fn from_i32(value: i32) -> ::std::option::Option<FFIStatusCode> {
        match value {
            0 => ::std::option::Option::Some(FFIStatusCode::Ok),
            1 => ::std::option::Option::Some(FFIStatusCode::Err),
            2 => ::std::option::Option::Some(FFIStatusCode::Internal),
            _ => ::std::option::Option::None
        }
    }

    fn values() -> &'static [Self] {
        static values: &'static [FFIStatusCode] = &[
            FFIStatusCode::Ok,
            FFIStatusCode::Err,
            FFIStatusCode::Internal,
        ];
        values
    }

    fn enum_descriptor_static() -> &'static ::protobuf::reflect::EnumDescriptor {
        static descriptor: ::protobuf::rt::LazyV2<::protobuf::reflect::EnumDescriptor> = ::protobuf::rt::LazyV2::INIT;
        descriptor.get(|| {
            ::protobuf::reflect::EnumDescriptor::new_pb_name::<FFIStatusCode>("FFIStatusCode", file_descriptor_proto())
        })
    }
}

impl ::std::marker::Copy for FFIStatusCode {
}

impl ::std::default::Default for FFIStatusCode {
    fn default() -> Self {
        FFIStatusCode::Ok
    }
}

impl ::protobuf::reflect::ProtobufValue for FFIStatusCode {
    fn as_ref(&self) -> ::protobuf::reflect::ReflectValueRef {
        ::protobuf::reflect::ReflectValueRef::Enum(::protobuf::ProtobufEnum::descriptor(self))
    }
}

static file_descriptor_proto_data: &'static [u8] = b"\
    \n\x12ffi_response.proto\"K\n\x0bFFIResponse\x12\x18\n\x07payload\x18\
    \x01\x20\x01(\x0cR\x07payload\x12\"\n\x04code\x18\x02\x20\x01(\x0e2\x0e.\
    FFIStatusCodeR\x04code*.\n\rFFIStatusCode\x12\x06\n\x02Ok\x10\0\x12\x07\
    \n\x03Err\x10\x01\x12\x0c\n\x08Internal\x10\x02b\x06proto3\
";

static file_descriptor_proto_lazy: ::protobuf::rt::LazyV2<::protobuf::descriptor::FileDescriptorProto> = ::protobuf::rt::LazyV2::INIT;

fn parse_descriptor_proto() -> ::protobuf::descriptor::FileDescriptorProto {
    ::protobuf::Message::parse_from_bytes(file_descriptor_proto_data).unwrap()
}

pub fn file_descriptor_proto() -> &'static ::protobuf::descriptor::FileDescriptorProto {
    file_descriptor_proto_lazy.get(|| {
        parse_descriptor_proto()
    })
}
