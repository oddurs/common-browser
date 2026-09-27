use std::process::ExitCode;

const USAGE: &str = "usage: common --version";

/// Maps arguments to what `common` prints and whether it succeeded, kept apart from `main` so it
/// can be tested without spawning a process.
fn run(args: &[String]) -> (String, bool) {
    match args {
        [flag] if flag == "--version" || flag == "-V" => {
            (format!("common {}", common_core::VERSION), true)
        }
        _ => (USAGE.to_string(), false),
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let (output, ok) = run(&args);
    if ok {
        println!("{output}");
        ExitCode::SUCCESS
    } else {
        eprintln!("{output}");
        ExitCode::from(2)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(list: &[&str]) -> Vec<String> {
        list.iter().map(|s| s.to_string()).collect()
    }

    #[test]
    fn version_flag_prints_the_core_version() {
        let (output, ok) = run(&args(&["--version"]));
        assert!(ok);
        assert_eq!(output, format!("common {}", common_core::VERSION));
    }

    #[test]
    fn anything_else_prints_usage_and_fails() {
        for input in [&[][..], &["open"][..], &["--version", "extra"][..]] {
            let (output, ok) = run(&args(input));
            assert!(!ok, "{input:?} should fail");
            assert_eq!(output, USAGE);
        }
    }
}
