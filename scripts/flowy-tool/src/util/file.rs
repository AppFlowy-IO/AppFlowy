use console::Style;
use dialoguer::Confirm;
use similar::{ChangeTag, TextDiff};
use std::{
    fs::{File, OpenOptions},
    io::{Read, Write},
    path::Path,
};
use tera::Tera;

pub fn read_file(path: &str) -> Option<String> {
    let mut file = File::open(path).expect("Unable to open file");
    let mut content = String::new();
    match file.read_to_string(&mut content) {
        Ok(_) => Some(content),
        Err(e) => {
            log::error!("{}, with error: {:?}", path, e);
            Some("".to_string())
        }
    }
}

pub fn save_content_to_file_with_diff_prompt(content: &str, output_file: &str, force_write: bool) {
    if Path::new(output_file).exists() {
        let old_content = read_file(output_file).unwrap();
        let new_content = content.to_owned();
        let write_to_file = || match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(output_file)
        {
            Ok(ref mut file) => {
                file.write_all(new_content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open log file: {}", err);
            }
        };
        if new_content != old_content {
            print_diff(old_content.clone(), new_content.clone());
            if force_write {
                write_to_file()
            } else {
                if Confirm::new().with_prompt("Override?").interact().unwrap() {
                    write_to_file()
                } else {
                    log::info!("never mind then :(");
                }
            }
        }
    } else {
        match OpenOptions::new()
            .create(true)
            .write(true)
            .open(output_file)
        {
            Ok(ref mut file) => file.write_all(content.as_bytes()).unwrap(),
            Err(err) => panic!("Open or create file fail: {}", err),
        }
    }
}

pub fn print_diff(old_content: String, new_content: String) {
    let diff = TextDiff::from_lines(&old_content, &new_content);
    for op in diff.ops() {
        for change in diff.iter_changes(op) {
            let (sign, style) = match change.tag() {
                ChangeTag::Delete => ("-", Style::new().red()),
                ChangeTag::Insert => ("+", Style::new().green()),
                ChangeTag::Equal => (" ", Style::new()),
            };

            match change.tag() {
                ChangeTag::Delete => {
                    print!("{}{}", style.apply_to(sign).bold(), style.apply_to(change));
                }
                ChangeTag::Insert => {
                    print!("{}{}", style.apply_to(sign).bold(), style.apply_to(change));
                }
                ChangeTag::Equal => {}
            };
        }
        println!("---------------------------------------------------");
    }
}

pub fn get_tera(directory: &str) -> Tera {
    let mut root = "./scripts/flowy-tool/src/proto/template/".to_owned();
    root.push_str(directory);

    let root_absolute_path = std::fs::canonicalize(root)
        .unwrap()
        .as_path()
        .display()
        .to_string();

    let template_path = format!("{}/**/*.tera", root_absolute_path);
    match Tera::new(template_path.as_ref()) {
        Ok(t) => t,
        Err(e) => {
            log::error!("Parsing error(s): {}", e);
            ::std::process::exit(1);
        }
    }
}
