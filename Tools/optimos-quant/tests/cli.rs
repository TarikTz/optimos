//! Runs the real binary the way OptimosApp does: PNG on stdin, PNG on stdout, a status code.
use std::borrow::Cow;
use std::io::Write;
use std::process::{Command, Stdio};

fn run(args: &[&str], input: &[u8]) -> (i32, Vec<u8>) {
    let mut child = Command::new(env!("CARGO_BIN_EXE_optimos-quant"))
        .args(args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .unwrap();
    child.stdin.take().unwrap().write_all(input).unwrap();
    let out = child.wait_with_output().unwrap();
    (out.status.code().unwrap(), out.stdout)
}

fn encode_rgba(width: u32, height: u32, rgba: &[u8], icc: Option<&[u8]>) -> Vec<u8> {
    let mut info = png::Info::with_size(width, height);
    info.color_type = png::ColorType::Rgba;
    info.bit_depth = png::BitDepth::Eight;
    info.icc_profile = icc.map(|p| Cow::Owned(p.to_vec()));
    let mut out = Vec::new();
    let mut writer = png::Encoder::with_info(&mut out, info).unwrap().write_header().unwrap();
    writer.write_image_data(rgba).unwrap();
    writer.finish().unwrap();
    out
}

/// A smooth gradient with thousands of distinct colours.
fn gradient(width: u32, height: u32) -> Vec<u8> {
    let mut px = Vec::new();
    for y in 0..height {
        for x in 0..width {
            px.extend_from_slice(&[(x * 255 / width) as u8, (y * 255 / height) as u8, ((x + y) % 256) as u8, 255]);
        }
    }
    px
}

fn noise(width: u32, height: u32) -> Vec<u8> {
    let mut state = 0x2545F491u32;
    (0..width * height * 4)
        .map(|_| {
            state = state.wrapping_mul(1664525).wrapping_add(1013904223);
            (state >> 24) as u8
        })
        .collect()
}

#[test]
fn shrinks_a_gradient_into_an_indexed_png() {
    let input = encode_rgba(160, 160, &gradient(160, 160), None);
    let (code, output) = run(&["--quality=0-100", "-"], &input);
    assert_eq!(code, 0);
    assert!(output.len() < input.len());
    let reader = png::Decoder::new(&output[..]).read_info().unwrap();
    assert_eq!(reader.info().color_type, png::ColorType::Indexed);
}

#[test]
fn keeps_the_embedded_colour_profile() {
    let profile = b"pretend-display-p3-profile".as_slice();
    let input = encode_rgba(160, 160, &gradient(160, 160), Some(profile));
    let (code, output) = run(&["--quality=0-100", "-"], &input);
    assert_eq!(code, 0);
    let reader = png::Decoder::new(&output[..]).read_info().unwrap();
    assert_eq!(reader.info().icc_profile.as_deref(), Some(profile));
}

#[test]
fn declines_when_the_minimum_quality_is_out_of_reach() {
    let input = encode_rgba(96, 96, &noise(96, 96), None);
    let (code, output) = run(&["--quality=95-100", "-"], &input);
    assert_eq!(code, 99);
    assert!(output.is_empty());
}

#[test]
fn a_lower_target_never_uses_more_colours_than_a_higher_one() {
    let input = encode_rgba(160, 160, &gradient(160, 160), None);
    let palette_len = |q: &str| {
        let (code, out) = run(&[q, "-"], &input);
        assert_eq!(code, 0);
        let reader = png::Decoder::new(&out[..]).read_info().unwrap();
        reader.info().palette.as_ref().unwrap().len() / 3
    };
    assert!(palette_len("--quality=0-60") <= palette_len("--quality=0-90"));
}

#[test]
fn rejects_bad_usage_and_garbage_input() {
    assert_eq!(run(&["-"], b"").0, 2);
    assert_eq!(run(&["--quality=70-60", "-"], b"").0, 2);
    assert_eq!(run(&["--quality=0-100", "-"], b"not a png").0, 1);
}
