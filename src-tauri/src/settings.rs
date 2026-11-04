//! User settings: serde struct with defaults, clamping validation and JSON persistence.
//!
//! Shape and limits match `legacy-electron/src/background/db.ts`.

use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Manager};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(default, rename_all = "camelCase")]
pub struct Settings {
    pub breaks: Breaks,
    pub sounds: Sounds,
    pub lang: Lang,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct Breaks {
    /// Seconds between breaks.
    pub every: u32,
    pub short: ShortBreak,
    pub long: LongBreak,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct ShortBreak {
    /// Length in seconds.
    pub last: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct LongBreak {
    /// Length in seconds.
    pub last: u32,
    /// Every n-th break is long.
    pub every: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct Sounds {
    pub ui: bool,
    pub voice: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Lang {
    En,
    Pl,
}

impl Default for Breaks {
    fn default() -> Self {
        Self {
            every: 20 * 60,
            short: ShortBreak::default(),
            long: LongBreak::default(),
        }
    }
}

impl Default for ShortBreak {
    fn default() -> Self {
        Self { last: 20 }
    }
}

impl Default for LongBreak {
    fn default() -> Self {
        Self {
            last: 5 * 60,
            every: 3,
        }
    }
}

impl Default for Sounds {
    fn default() -> Self {
        Self {
            ui: true,
            voice: true,
        }
    }
}

impl Default for Lang {
    fn default() -> Self {
        let locale = sys_locale::get_locale()
            .or_else(|| std::env::var("LANG").ok())
            .unwrap_or_default();
        Lang::from_locale(&locale)
    }
}

impl Lang {
    pub fn from_locale(locale: &str) -> Self {
        if locale.to_ascii_lowercase().starts_with("pl") {
            Lang::Pl
        } else {
            Lang::En
        }
    }
}

/// One clamped value, reported back so the frontend can explain the change.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Fix {
    pub code: &'static str,
    pub from: u32,
    pub to: u32,
}

pub const EVERY_RANGE: (u32, u32) = (60, 60 * 60);
pub const SHORT_LAST_RANGE: (u32, u32) = (1, 60);
pub const LONG_LAST_RANGE: (u32, u32) = (60, 60 * 60);
pub const LONG_EVERY_RANGE: (u32, u32) = (1, 30);

fn clamp(value: &mut u32, (min, max): (u32, u32), code: &'static str, fixes: &mut Vec<Fix>) {
    let to = (*value).clamp(min, max);
    if to != *value {
        fixes.push(Fix {
            code,
            from: *value,
            to,
        });
        *value = to;
    }
}

impl Settings {
    /// Clamp every numeric field into its legal range; returns what changed.
    pub fn validate(&mut self) -> Vec<Fix> {
        let mut fixes = Vec::new();
        let b = &mut self.breaks;
        clamp(&mut b.every, EVERY_RANGE, "shortEvery", &mut fixes);
        clamp(&mut b.short.last, SHORT_LAST_RANGE, "shortLast", &mut fixes);
        clamp(&mut b.long.every, LONG_EVERY_RANGE, "longEvery", &mut fixes);
        clamp(&mut b.long.last, LONG_LAST_RANGE, "longLast", &mut fixes);
        fixes
    }

    /// Parse and validate; anything unreadable yields defaults.
    pub fn from_json(json: &str) -> Self {
        let mut s: Settings = serde_json::from_str(json).unwrap_or_else(|e| {
            eprintln!("[settings] corrupt settings file, using defaults: {e}");
            Settings::default()
        });
        s.validate();
        s
    }

    pub fn load_from(path: &Path) -> Self {
        match std::fs::read_to_string(path) {
            Ok(json) => Self::from_json(&json),
            Err(_) => Settings::default(),
        }
    }

    pub fn save_to(&self, path: &Path) -> std::io::Result<()> {
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)?;
        }
        let json = serde_json::to_string_pretty(self).map_err(std::io::Error::other)?;
        std::fs::write(path, json)
    }
}

const FILE_NAME: &str = if cfg!(debug_assertions) {
    "settings-dev.json"
} else {
    "settings.json"
};

pub fn settings_path(app: &AppHandle) -> tauri::Result<PathBuf> {
    Ok(app.path().app_config_dir()?.join(FILE_NAME))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base() -> Settings {
        Settings {
            lang: Lang::En,
            ..Settings::default()
        }
    }

    #[test]
    fn defaults_match_legacy() {
        let s = base();
        assert_eq!(s.breaks.every, 1200);
        assert_eq!(s.breaks.short.last, 20);
        assert_eq!(s.breaks.long.last, 300);
        assert_eq!(s.breaks.long.every, 3);
        assert!(s.sounds.ui && s.sounds.voice);
    }

    #[test]
    fn defaults_are_valid() {
        assert!(base().validate().is_empty());
    }

    #[test]
    fn clamps_low_values() {
        let mut s = base();
        s.breaks.every = 10;
        s.breaks.short.last = 0;
        s.breaks.long.every = 0;
        s.breaks.long.last = 5;
        let fixes = s.validate();
        assert_eq!(
            fixes,
            vec![
                Fix {
                    code: "shortEvery",
                    from: 10,
                    to: 60
                },
                Fix {
                    code: "shortLast",
                    from: 0,
                    to: 1
                },
                Fix {
                    code: "longEvery",
                    from: 0,
                    to: 1
                },
                Fix {
                    code: "longLast",
                    from: 5,
                    to: 60
                },
            ]
        );
        assert_eq!(s.breaks.every, 60);
        assert_eq!(s.breaks.short.last, 1);
        assert_eq!(s.breaks.long.every, 1);
        assert_eq!(s.breaks.long.last, 60);
    }

    #[test]
    fn clamps_high_values() {
        let mut s = base();
        s.breaks.every = 7200;
        s.breaks.short.last = 61;
        s.breaks.long.every = 31;
        s.breaks.long.last = 3601;
        let fixes = s.validate();
        let codes: Vec<_> = fixes.iter().map(|f| (f.code, f.to)).collect();
        assert_eq!(
            codes,
            vec![
                ("shortEvery", 3600),
                ("shortLast", 60),
                ("longEvery", 30),
                ("longLast", 3600)
            ]
        );
        assert!(s.validate().is_empty(), "validate is idempotent");
    }

    #[test]
    fn bounds_are_inclusive() {
        let mut s = base();
        s.breaks.every = 60;
        s.breaks.short.last = 60;
        s.breaks.long.every = 30;
        s.breaks.long.last = 3600;
        assert!(s.validate().is_empty());
    }

    #[test]
    fn camel_case_wire_shape() {
        let v = serde_json::to_value(base()).unwrap();
        assert_eq!(
            v,
            serde_json::json!({
                "breaks": { "every": 1200, "short": { "last": 20 }, "long": { "last": 300, "every": 3 } },
                "sounds": { "ui": true, "voice": true },
                "lang": "en"
            })
        );
        let fix = serde_json::to_value(Fix {
            code: "longLast",
            from: 1,
            to: 60,
        })
        .unwrap();
        assert_eq!(
            fix,
            serde_json::json!({ "code": "longLast", "from": 1, "to": 60 })
        );
    }

    #[test]
    fn partial_json_fills_defaults_and_clamps() {
        let s = Settings::from_json(r#"{ "breaks": { "long": { "every": 99 } }, "lang": "pl" }"#);
        assert_eq!(s.breaks.every, 1200);
        assert_eq!(s.breaks.long.last, 300);
        assert_eq!(s.breaks.long.every, 30);
        assert_eq!(s.lang, Lang::Pl);
        assert!(s.sounds.voice);
    }

    #[test]
    fn corrupt_json_gives_defaults() {
        let s = Settings::from_json("{ not json");
        assert_eq!(s.breaks, Breaks::default());
        let s = Settings::from_json(r#"{ "lang": "de" }"#);
        assert_eq!(s.breaks, Breaks::default());
    }

    #[test]
    fn lang_from_locale() {
        assert_eq!(Lang::from_locale("pl-PL"), Lang::Pl);
        assert_eq!(Lang::from_locale("PL_pl.UTF-8"), Lang::Pl);
        assert_eq!(Lang::from_locale("en-GB"), Lang::En);
        assert_eq!(Lang::from_locale(""), Lang::En);
    }

    #[test]
    fn save_and_load_roundtrip() {
        let dir = std::env::temp_dir().join(format!("sme-settings-test-{}", std::process::id()));
        let path = dir.join("nested").join("settings.json");
        let mut s = base();
        s.breaks.every = 900;
        s.sounds.ui = false;
        s.save_to(&path).unwrap();
        assert_eq!(Settings::load_from(&path), s);
        assert_eq!(
            Settings::load_from(&dir.join("missing.json")).breaks,
            Breaks::default()
        );
        std::fs::remove_dir_all(&dir).unwrap();
    }
}
