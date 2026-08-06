// Provider-Neutral Native Android Boundary Harness
// Purpose: Test Rust-to-Android ABI loading, opaque handles, panic containment, and buffer ownership.
// NOTE: NON-CRYPTOGRAPHIC DEMONSTRATION HARNESS — NOT FOR PRODUCTION E2EE.

use std::collections::HashMap;
use std::panic::catch_unwind;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;

static NEXT_HANDLE: AtomicU64 = AtomicU64::new(1);

lazy_static::lazy_static! {
    static ref SESSIONS: Mutex<HashMap<u64, String>> = Mutex::new(HashMap::new());
}

#[repr(C)]
pub enum BoundaryStatus {
    Success = 0,
    InvalidHandle = -1,
    BufferTooSmall = -2,
    NullPointer = -3,
    PanicCaught = -4,
}

#[no_mangle]
pub extern "C" fn boundary_create_session(handle_out: *mut u64) -> i32 {
    if handle_out.is_null() {
        return BoundaryStatus::NullPointer as i32;
    }
    let res = catch_unwind(|| {
        let handle = NEXT_HANDLE.fetch_add(1, Ordering::SeqCst);
        let mut map = SESSIONS.lock().unwrap();
        map.insert(handle, format!("neutral_session_{}", handle));
        unsafe { *handle_out = handle; }
        BoundaryStatus::Success as i32
    });
    res.unwrap_or(BoundaryStatus::PanicCaught as i32)
}

#[no_mangle]
pub extern "C" fn boundary_process_bytes(
    handle: u64,
    in_ptr: *const u8,
    in_len: usize,
    out_ptr: *mut u8,
    out_len: usize,
    written_out: *mut usize,
) -> i32 {
    if in_ptr.is_null() || out_ptr.is_null() || written_out.is_null() {
        return BoundaryStatus::NullPointer as i32;
    }
    let res = catch_unwind(|| {
        let map = SESSIONS.lock().unwrap();
        if !map.contains_key(&handle) {
            return BoundaryStatus::InvalidHandle as i32;
        }
        if out_len < in_len {
            return BoundaryStatus::BufferTooSmall as i32;
        }
        unsafe {
            let in_slice = std::slice::from_raw_parts(in_ptr, in_len);
            let out_slice = std::slice::from_raw_parts_mut(out_ptr, out_len);
            for i in 0..in_len {
                out_slice[i] = in_slice[i] ^ 0xAA; // Non-crypto byte transformation demonstration
            }
            *written_out = in_len;
        }
        BoundaryStatus::Success as i32
    });
    res.unwrap_or(BoundaryStatus::PanicCaught as i32)
}

#[no_mangle]
pub extern "C" fn boundary_destroy_session(handle: u64) -> i32 {
    let res = catch_unwind(|| {
        let mut map = SESSIONS.lock().unwrap();
        if map.remove(&handle).is_some() {
            BoundaryStatus::Success as i32
        } else {
            BoundaryStatus::InvalidHandle as i32
        }
    });
    res.unwrap_or(BoundaryStatus::PanicCaught as i32)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_neutral_boundary_lifecycle() {
        let mut handle: u64 = 0;
        let st = boundary_create_session(&mut handle);
        assert_eq!(st, BoundaryStatus::Success as i32);
        assert!(handle > 0);

        let input = b"Hello Android Boundary";
        let mut output = vec![0u8; input.len()];
        let mut written = 0;

        let proc_st = boundary_process_bytes(
            handle,
            input.as_ptr(),
            input.len(),
            output.as_mut_ptr(),
            output.len(),
            &mut written,
        );
        assert_eq!(proc_st, BoundaryStatus::Success as i32);
        assert_eq!(written, input.len());

        let invalid_st = boundary_process_bytes(
            99999,
            input.as_ptr(),
            input.len(),
            output.as_mut_ptr(),
            output.len(),
            &mut written,
        );
        assert_eq!(invalid_st, BoundaryStatus::InvalidHandle as i32);

        let destroy_st = boundary_destroy_session(handle);
        assert_eq!(destroy_st, BoundaryStatus::Success as i32);
    }
}
