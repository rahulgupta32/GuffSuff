//! Provider-Neutral Mobile Cryptographic Boundary (Native Host C FFI)
//!
//! SECURITY NOTICE:
//! This library contains zero embedded production cryptographic backends.
//! Label: TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY

use std::collections::HashMap;
use std::panic::catch_unwind;
use std::sync::atomic::{AtomicI32, AtomicU64, Ordering};
use std::sync::{OnceLock, RwLock};

pub const BOUNDARY_API_VERSION: u32 = 1;
pub const MAX_BUFFER_SIZE: usize = 10 * 1024 * 1024; // 10 MB limit

pub const PROVIDER_LABEL: &str = "TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY";
pub const PROVIDER_VERSION: &str = "0.1.0-test";

// Error Codes
pub const ERR_SUCCESS: i32 = 0;
pub const ERR_NULL_POINTER: i32 = -1;
pub const ERR_INVALID_HANDLE: i32 = -2;
pub const ERR_STALE_OR_DOUBLE_FREE: i32 = -3;
pub const ERR_PANIC_CONTAINED: i32 = -4;
pub const ERR_BUFFER_TOO_SMALL: i32 = -5;
pub const ERR_OVERSIZED_BUFFER: i32 = -6;
pub const ERR_VERSION_MISMATCH: i32 = -7;
pub const ERR_INVALID_STATE: i32 = -8;

static LAST_ERROR_CODE: AtomicI32 = AtomicI32::new(ERR_SUCCESS);
static HANDLE_COUNTER: AtomicU64 = AtomicU64::new(1000);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HandleType {
    Identity = 1,
    Session = 2,
    Group = 3,
}

#[derive(Debug, Clone)]
pub struct HandleEntry {
    pub handle_type: HandleType,
    pub created_at_ms: u64,
    pub is_active: bool,
}

struct Registry {
    handles: HashMap<u64, HandleEntry>,
}

impl Registry {
    fn new() -> Self {
        Self {
            handles: HashMap::new(),
        }
    }
}

fn get_registry() -> &'static RwLock<Registry> {
    static REGISTRY: OnceLock<RwLock<Registry>> = OnceLock::new();
    REGISTRY.get_or_init(|| RwLock::new(Registry::new()))
}

fn set_last_error(code: i32) {
    LAST_ERROR_CODE.store(code, Ordering::SeqCst);
}

#[no_mangle]
pub extern "C" fn boundary_last_error_code() -> i32 {
    LAST_ERROR_CODE.load(Ordering::SeqCst)
}

#[no_mangle]
pub extern "C" fn boundary_api_version() -> u32 {
    let res = catch_unwind(|| {
        set_last_error(ERR_SUCCESS);
        BOUNDARY_API_VERSION
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        0
    })
}

#[repr(C)]
pub struct NativeCapabilityMap {
    pub supports_direct_messaging: u8,
    pub supports_group_messaging: u8,
    pub is_test_provider: u8,
    pub api_version: u32,
}

#[no_mangle]
pub extern "C" fn query_capabilities(out_caps: *mut NativeCapabilityMap) -> i32 {
    let res = catch_unwind(|| {
        if out_caps.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        unsafe {
            (*out_caps).supports_direct_messaging = 1;
            (*out_caps).supports_group_messaging = 0;
            (*out_caps).is_test_provider = 1;
            (*out_caps).api_version = BOUNDARY_API_VERSION;
        }
        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

fn register_handle(handle_type: HandleType) -> u64 {
    let handle_id = HANDLE_COUNTER.fetch_add(1, Ordering::SeqCst);
    let entry = HandleEntry {
        handle_type,
        created_at_ms: 1722900000000,
        is_active: true,
    };
    let mut reg = get_registry().write().unwrap();
    reg.handles.insert(handle_id, entry);
    handle_id
}

#[no_mangle]
pub extern "C" fn create_test_identity_handle(out_handle: *mut u64) -> i32 {
    let res = catch_unwind(|| {
        if out_handle.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        let handle_id = register_handle(HandleType::Identity);
        unsafe {
            *out_handle = handle_id;
        }
        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn create_test_session_handle(out_handle: *mut u64) -> i32 {
    let res = catch_unwind(|| {
        if out_handle.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        let handle_id = register_handle(HandleType::Session);
        unsafe {
            *out_handle = handle_id;
        }
        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn create_test_group_handle(out_handle: *mut u64) -> i32 {
    let res = catch_unwind(|| {
        if out_handle.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        let handle_id = register_handle(HandleType::Group);
        unsafe {
            *out_handle = handle_id;
        }
        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

/// Explicit non-cryptographic test payload transformation.
#[no_mangle]
pub extern "C" fn transform_test_payload(
    handle: u64,
    in_buf: *const u8,
    in_len: usize,
    out_buf: *mut u8,
    out_max_len: usize,
    out_len: *mut usize,
) -> i32 {
    let res = catch_unwind(|| {
        if in_buf.is_null() || out_buf.is_null() || out_len.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        if in_len > MAX_BUFFER_SIZE {
            set_last_error(ERR_OVERSIZED_BUFFER);
            return ERR_OVERSIZED_BUFFER;
        }

        // Validate handle
        let reg = get_registry().read().unwrap();
        match reg.handles.get(&handle) {
            Some(entry) if entry.is_active => {}
            Some(_) => {
                set_last_error(ERR_STALE_OR_DOUBLE_FREE);
                return ERR_STALE_OR_DOUBLE_FREE;
            }
            None => {
                set_last_error(ERR_INVALID_HANDLE);
                return ERR_INVALID_HANDLE;
            }
        }

        if out_max_len < in_len {
            set_last_error(ERR_BUFFER_TOO_SMALL);
            return ERR_BUFFER_TOO_SMALL;
        }

        let input_slice = unsafe { std::slice::from_raw_parts(in_buf, in_len) };
        let output_slice = unsafe { std::slice::from_raw_parts_mut(out_buf, out_max_len) };

        // Non-cryptographic identity copy for test boundary
        output_slice[..in_len].copy_from_slice(input_slice);
        unsafe {
            *out_len = in_len;
        }

        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn dispose_handle(handle: u64) -> i32 {
    let res = catch_unwind(|| {
        let mut reg = get_registry().write().unwrap();
        match reg.handles.get_mut(&handle) {
            Some(entry) => {
                if !entry.is_active {
                    set_last_error(ERR_STALE_OR_DOUBLE_FREE);
                    return ERR_STALE_OR_DOUBLE_FREE;
                }
                entry.is_active = false;
                set_last_error(ERR_SUCCESS);
                ERR_SUCCESS
            }
            None => {
                set_last_error(ERR_INVALID_HANDLE);
                ERR_INVALID_HANDLE
            }
        }
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn export_opaque_test_state(
    out_buf: *mut u8,
    out_max_len: usize,
    out_len: *mut usize,
) -> i32 {
    let res = catch_unwind(|| {
        if out_buf.is_null() || out_len.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        let reg = get_registry().read().unwrap();
        let mut state_bytes = Vec::new();

        // Opaque header version 1
        state_bytes.extend_from_slice(&BOUNDARY_API_VERSION.to_le_bytes());
        state_bytes.extend_from_slice(&(reg.handles.len() as u32).to_le_bytes());

        for (&id, entry) in &reg.handles {
            state_bytes.extend_from_slice(&id.to_le_bytes());
            state_bytes.push(entry.handle_type as u8);
            state_bytes.push(if entry.is_active { 1 } else { 0 });
        }

        if out_max_len < state_bytes.len() {
            unsafe { *out_len = state_bytes.len() };
            set_last_error(ERR_BUFFER_TOO_SMALL);
            return ERR_BUFFER_TOO_SMALL;
        }

        let output_slice = unsafe { std::slice::from_raw_parts_mut(out_buf, out_max_len) };
        output_slice[..state_bytes.len()].copy_from_slice(&state_bytes);
        unsafe {
            *out_len = state_bytes.len();
        }

        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn import_opaque_test_state(in_buf: *const u8, in_len: usize) -> i32 {
    let res = catch_unwind(|| {
        if in_buf.is_null() {
            set_last_error(ERR_NULL_POINTER);
            return ERR_NULL_POINTER;
        }
        if in_len < 8 {
            set_last_error(ERR_INVALID_STATE);
            return ERR_INVALID_STATE;
        }

        let slice = unsafe { std::slice::from_raw_parts(in_buf, in_len) };
        let version = u32::from_le_bytes([slice[0], slice[1], slice[2], slice[3]]);
        if version != BOUNDARY_API_VERSION {
            set_last_error(ERR_VERSION_MISMATCH);
            return ERR_VERSION_MISMATCH;
        }

        let count = u32::from_le_bytes([slice[4], slice[5], slice[6], slice[7]]) as usize;
        let mut offset = 8;

        let mut reg = get_registry().write().unwrap();
        reg.handles.clear();

        for _ in 0..count {
            if offset + 10 > in_len {
                set_last_error(ERR_INVALID_STATE);
                return ERR_INVALID_STATE;
            }
            let id = u64::from_le_bytes(slice[offset..offset + 8].try_into().unwrap());
            let handle_type = match slice[offset + 8] {
                1 => HandleType::Identity,
                2 => HandleType::Session,
                3 => HandleType::Group,
                _ => {
                    set_last_error(ERR_INVALID_STATE);
                    return ERR_INVALID_STATE;
                }
            };
            let is_active = slice[offset + 9] != 0;
            offset += 10;

            reg.handles.insert(
                id,
                HandleEntry {
                    handle_type,
                    created_at_ms: 1722900000000,
                    is_active,
                },
            );
        }

        set_last_error(ERR_SUCCESS);
        ERR_SUCCESS
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[no_mangle]
pub extern "C" fn trigger_controlled_test_panic() -> i32 {
    let res = catch_unwind(|| {
        panic!("CONTROLLED TEST PANIC IN NATIVE BOUNDARY");
    });
    res.unwrap_or_else(|_| {
        set_last_error(ERR_PANIC_CONTAINED);
        ERR_PANIC_CONTAINED
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_api_version() {
        assert_eq!(boundary_api_version(), 1);
    }

    #[test]
    fn test_capability_query() {
        let mut caps = NativeCapabilityMap {
            supports_direct_messaging: 0,
            supports_group_messaging: 0,
            is_test_provider: 0,
            api_version: 0,
        };
        let res = query_capabilities(&mut caps);
        assert_eq!(res, ERR_SUCCESS);
        assert_eq!(caps.is_test_provider, 1);
        assert_eq!(caps.supports_direct_messaging, 1);
    }

    #[test]
    fn test_handle_lifecycle_and_disposal() {
        let mut handle = 0u64;
        assert_eq!(create_test_session_handle(&mut handle), ERR_SUCCESS);
        assert!(handle > 0);

        let input = b"Hello GuffSuff";
        let mut output = [0u8; 32];
        let mut out_len = 0usize;

        let res = transform_test_payload(
            handle,
            input.as_ptr(),
            input.len(),
            output.as_mut_ptr(),
            output.len(),
            &mut out_len,
        );
        assert_eq!(res, ERR_SUCCESS);
        assert_eq!(&output[..out_len], input);

        // Dispose
        assert_eq!(dispose_handle(handle), ERR_SUCCESS);
        // Double dispose returns stale/double free error
        assert_eq!(dispose_handle(handle), ERR_STALE_OR_DOUBLE_FREE);
    }

    #[test]
    fn test_panic_containment() {
        assert_eq!(trigger_controlled_test_panic(), ERR_PANIC_CONTAINED);
        assert_eq!(boundary_last_error_code(), ERR_PANIC_CONTAINED);
    }
}
