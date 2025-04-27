use std::path::PathBuf;
use std::process::Command;
use std::{env, fs};

fn main() {
  #[cfg(feature = "dart")]
  {
    flowy_codegen::protobuf_file::dart_gen(env!("CARGO_PKG_NAME"));
    flowy_codegen::dart_event::gen(env!("CARGO_PKG_NAME"));
  }

  let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
  let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();

  // Check if we should skip building (if FAISS_SKIP_BUILD env var is set)
  if env::var("FAISS_SKIP_BUILD").is_ok() {
    return;
  }

  let tmp_dir = out_dir.join("faiss_build");
  fs::create_dir_all(&tmp_dir).unwrap();

  // Clone faiss repository
  if !tmp_dir.join("faiss").exists() {
    let status = Command::new("git")
      .args(&[
        "clone",
        "--recursive",
        "https://github.com/facebookresearch/faiss.git",
      ])
      .current_dir(&tmp_dir)
      .status();

    if status.is_err() || !status.unwrap().success() {
      println!("cargo:warning=Failed to clone faiss repository");
      return;
    }
  }

  let faiss_dir = tmp_dir.join("faiss");
  let build_dir = faiss_dir.join("build");

  // Create build directory
  fs::create_dir_all(&build_dir).unwrap();

  // Build faiss
  let status = Command::new("cmake")
    .args(&[
      "-DFAISS_ENABLE_C_API=ON",
      "-DBUILD_SHARED_LIBS=ON",
      "-DCMAKE_BUILD_TYPE=Release",
      "-DFAISS_ENABLE_PYTHON=OFF",
      "..",
    ])
    .current_dir(&build_dir)
    .status();

  if status.is_err() || !status.unwrap().success() {
    println!("cargo:warning=Failed to configure faiss build");
    return;
  }

  let status = Command::new("cmake")
    .args(&["--build", ".", "--config", "Release"])
    .current_dir(&build_dir)
    .status();

  if status.is_err() || !status.unwrap().success() {
    println!("cargo:warning=Failed to build faiss");
    return;
  }

  // Determine library path and name based on platform
  let (lib_path, lib_name) = match target_os.as_str() {
    "macos" => {
      let path = build_dir.join("c_api/libfaiss_c.dylib");
      (path, "faiss_c")
    },
    "linux" => {
      let path = build_dir.join("c_api/libfaiss_c.so");
      (path, "faiss_c")
    },
    "windows" => {
      let path = build_dir.join("c_api/Release/faiss_c.dll");
      (path, "faiss_c")
    },
    _ => panic!("Unsupported operating system"),
  };

  // Copy library to output directory
  let out_lib = out_dir.join(lib_path.file_name().unwrap());
  fs::copy(&lib_path, &out_lib).unwrap();

  // Tell cargo where to find the library
  println!("cargo:rustc-link-search=native={}", out_dir.display());
  println!("cargo:rustc-link-lib={}", lib_name);
  println!("cargo:rustc-env=LD_LIBRARY_PATH={}", out_dir.display());
  println!("cargo:rustc-env=DYLD_LIBRARY_PATH={}", out_dir.display());
}
