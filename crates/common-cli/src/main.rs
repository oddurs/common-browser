use std::path::{Path, PathBuf};
use std::process::ExitCode;

use common_core::config::{self, LoadError};

const USAGE: &str = "\
usage: common <command>

commands:
  config check [--path FILE]  report each error in common.toml as FILE:LINE:COL: MESSAGE

options:
  -h, --help     print this help
  -V, --version  print the version
";

/// What a run prints and how it exits, kept apart from `main` so it can be tested without
/// spawning a process.
#[derive(Debug, Default, PartialEq, Eq)]
struct Outcome {
    stdout: String,
    stderr: String,
    /// 0 for success, 1 when the command ran and found a problem, 2 for a usage error.
    code: u8,
}

impl Outcome {
    fn success(stdout: String) -> Self {
        Outcome {
            stdout,
            ..Outcome::default()
        }
    }

    fn failure(err: &LoadError) -> Self {
        Outcome {
            stderr: format!("common: {err}\n"),
            code: 1,
            ..Outcome::default()
        }
    }

    fn usage() -> Self {
        Outcome {
            stderr: USAGE.to_string(),
            code: 2,
            ..Outcome::default()
        }
    }
}

/// `default_config` is where `common.toml` lives when no `--path` is given, or `None` when the
/// environment does not say.
fn run(args: &[String], default_config: Option<PathBuf>) -> Outcome {
    let args: Vec<&str> = args.iter().map(String::as_str).collect();
    match args.as_slice() {
        ["--version" | "-V"] => Outcome::success(format!("common {}\n", common_core::VERSION)),
        ["--help" | "-h"] => Outcome::success(USAGE.to_string()),
        ["config", "check"] => match default_config {
            Some(path) => check(&path, config::load_from(&path)),
            None => Outcome::failure(&LoadError::NoConfigDir),
        },
        ["config", "check", "--path", path] => {
            // Unlike the default location, a file named on the command line must exist: a typo
            // in the path would otherwise pass as a valid, empty config.
            let path = Path::new(path);
            let loaded = std::fs::read_to_string(path)
                .map(|text| config::parse(&text))
                .map_err(|source| LoadError::Read {
                    path: path.to_path_buf(),
                    source,
                });
            check(path, loaded)
        }
        _ => Outcome::usage(),
    }
}

/// Lists the errors on stdout, where linters put their findings, so that `common config check |
/// grep` and editors reading the output see them. Stderr is for failing to run at all.
fn check(
    path: &Path,
    loaded: Result<(config::Config, Vec<config::ConfigError>), LoadError>,
) -> Outcome {
    let errors = match loaded {
        Ok((_, errors)) => errors,
        Err(err) => return Outcome::failure(&err),
    };
    let stdout: String = errors
        .iter()
        .map(|error| format!("{}:{error}\n", path.display()))
        .collect();
    let code = u8::from(!errors.is_empty());
    Outcome {
        stdout,
        code,
        ..Outcome::default()
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let xdg = std::env::var_os("XDG_CONFIG_HOME");
    let home = std::env::var_os("HOME");
    let outcome = run(&args, config::default_path(xdg.as_deref(), home.as_deref()));
    print!("{}", outcome.stdout);
    eprint!("{}", outcome.stderr);
    ExitCode::from(outcome.code)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(list: &[&str]) -> Vec<String> {
        list.iter().map(|s| s.to_string()).collect()
    }

    /// A directory of its own under the system temporary directory, removed when dropped.
    struct TempDir(PathBuf);

    impl TempDir {
        fn new(name: &str) -> Self {
            let dir =
                std::env::temp_dir().join(format!("common-cli-{}-{name}", std::process::id()));
            std::fs::create_dir_all(&dir).expect("create a temporary directory");
            TempDir(dir)
        }

        fn file(&self, name: &str, contents: &str) -> PathBuf {
            let path = self.0.join(name);
            std::fs::write(&path, contents).expect("write a temporary file");
            path
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let removed = std::fs::remove_dir_all(&self.0);
            // A second panic while a failing test unwinds would abort and hide the first message.
            if let Err(err) = removed
                && !std::thread::panicking()
            {
                panic!("remove {}: {err}", self.0.display());
            }
        }
    }

    fn check_path(path: &Path) -> Outcome {
        let path = path.to_str().expect("temporary paths are UTF-8");
        run(&args(&["config", "check", "--path", path]), None)
    }

    #[test]
    fn version_flag_prints_the_core_version() {
        for flag in ["--version", "-V"] {
            let outcome = run(&args(&[flag]), None);
            assert_eq!(
                outcome,
                Outcome::success(format!("common {}\n", common_core::VERSION))
            );
        }
    }

    #[test]
    fn help_lists_the_commands() {
        for flag in ["--help", "-h"] {
            let outcome = run(&args(&[flag]), None);
            assert_eq!(outcome.code, 0);
            assert!(
                outcome.stdout.contains("config check [--path FILE]"),
                "{}",
                outcome.stdout
            );
            assert_eq!(outcome.stderr, "");
        }
    }

    #[test]
    fn anything_else_prints_usage_and_exits_2() {
        let inputs: [&[&str]; 5] = [
            &[],
            &["open"],
            &["--version", "extra"],
            &["config"],
            &["config", "check", "--path"],
        ];
        for input in inputs {
            let outcome = run(&args(input), None);
            assert_eq!(outcome, Outcome::usage(), "{input:?}");
        }
    }

    #[test]
    fn a_valid_file_prints_nothing_and_exits_0() {
        let dir = TempDir::new("valid");
        let path = dir.file(
            "common.toml",
            "theme = \"paper\"\n[window]\nstart = \"fullscreen\"\n",
        );
        assert_eq!(check_path(&path), Outcome::default());
    }

    #[test]
    fn an_invalid_file_prints_one_line_per_error_and_exits_1() {
        let dir = TempDir::new("invalid");
        let path = dir.file(
            "common.toml",
            "thme = \"paper\"\n[search]\nengine = \"https://a.example/\"\n",
        );
        let outcome = check_path(&path);
        let file = path.display();
        assert_eq!(outcome.code, 1);
        assert_eq!(outcome.stderr, "");
        assert_eq!(
            outcome.stdout,
            format!(
                "{file}:1:1: unknown key `thme` (did you mean `theme`?)\n\
                 {file}:3:10: `search.engine` must contain %s where the search terms go, like \
                 \"https://duckduckgo.com/?q=%s\"\n"
            )
        );
    }

    #[test]
    fn a_missing_path_exits_1_and_names_it() {
        let dir = TempDir::new("missing");
        let path = dir.0.join("nothing.toml");
        let outcome = check_path(&path);
        assert_eq!(outcome.code, 1);
        assert_eq!(outcome.stdout, "");
        assert!(
            outcome.stderr.contains(&path.display().to_string()),
            "{}",
            outcome.stderr
        );
    }

    #[test]
    fn a_missing_default_file_is_the_defaults() {
        let dir = TempDir::new("default");
        let outcome = run(&args(&["config", "check"]), Some(dir.0.join("common.toml")));
        assert_eq!(outcome, Outcome::default());
    }

    #[test]
    fn the_default_file_is_checked() {
        let dir = TempDir::new("default-invalid");
        let path = dir.file("common.toml", "theme = 3\n");
        let outcome = run(&args(&["config", "check"]), Some(path.clone()));
        assert_eq!(outcome.code, 1);
        assert_eq!(
            outcome.stdout,
            format!(
                "{}:1:9: `theme` must be a string, not an integer\n",
                path.display()
            )
        );
    }

    #[test]
    fn without_a_config_directory_check_says_why() {
        let outcome = run(&args(&["config", "check"]), None);
        assert_eq!(outcome.code, 1);
        assert!(
            outcome.stderr.contains("neither XDG_CONFIG_HOME nor HOME"),
            "{}",
            outcome.stderr
        );
    }
}
