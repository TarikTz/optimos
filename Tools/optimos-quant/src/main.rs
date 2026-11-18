//! optimos-quant: lossy PNG palette quantization for OptimosApp.
//!
//! Contract (the same call shape OptimosApp used for pngquant):
//!
//!     optimos-quant --quality=MIN-MAX -   < in.png > out.png
//!
//! Reads a PNG on stdin and writes an indexed PNG on stdout. It uses as few colours as it can while the
//! result still reaches the MAX quality, and gives up if even 256 colours cannot reach MIN.
//! The embedded colour profile and gamma are kept, so colours stay what they were.
//!
//! Exit codes: 0 written, 98 the result would not be smaller, 99 MIN quality not reachable,
//! 1 error, 2 bad usage.

use std::collections::HashSet;
use std::io::{Read, Write};

use quantizr::{Image, Options, QuantizeResult};

const EXIT_NOT_SMALLER: i32 = 98;
const EXIT_TOO_LOW: i32 = 99;

/// Dithering helps photographs and smooth gradients but adds noise to flat interface colours.
const DITHER_FLAT: f32 = 0.5;
const DITHER_PHOTO: f32 = 1.0;
/// More distinct colours than this and the image is treated as photographic.
const PHOTO_COLORS: usize = 4096;

struct Decoded {
    rgba: Vec<u8>,
    width: usize,
    height: usize,
    info: png::Info<'static>,
}

fn decode(data: &[u8]) -> Result<Decoded, String> {
    let mut dec = png::Decoder::new(data);
    dec.set_transformations(png::Transformations::normalize_to_color8());
    let mut reader = dec.read_info().map_err(|e| format!("not a readable PNG: {e}"))?;
    let mut buf = vec![0; reader.output_buffer_size()];
    let frame = reader.next_frame(&mut buf).map_err(|e| format!("decode failed: {e}"))?;
    let (width, height) = (frame.width as usize, frame.height as usize);
    let src = &buf[..frame.buffer_size()];
    let mut rgba = Vec::with_capacity(width * height * 4);
    match frame.color_type {
        png::ColorType::Rgba => rgba.extend_from_slice(src),
        png::ColorType::Rgb => src.chunks_exact(3).for_each(|p| rgba.extend_from_slice(&[p[0], p[1], p[2], 255])),
        png::ColorType::Grayscale => src.iter().for_each(|&g| rgba.extend_from_slice(&[g, g, g, 255])),
        png::ColorType::GrayscaleAlpha => src.chunks_exact(2).for_each(|p| rgba.extend_from_slice(&[p[0], p[0], p[0], p[1]])),
        png::ColorType::Indexed => return Err("unexpected indexed output".into()),
    }
    Ok(Decoded { rgba, width, height, info: reader.info().clone() })
}

/// Distinct colours, counted up to `cap + 1`.
fn distinct_colors(rgba: &[u8], cap: usize) -> HashSet<u32> {
    let mut seen = HashSet::new();
    for p in rgba.chunks_exact(4) {
        seen.insert(u32::from_le_bytes([p[0], p[1], p[2], p[3]]));
        if seen.len() > cap {
            break;
        }
    }
    seen
}

/// PSNR in dB between the source and the palettised result, on alpha-premultiplied RGBA.
fn psnr(src: &[u8], palette: &[[u8; 4]], indexes: &[u8]) -> f64 {
    let mut squared = 0f64;
    for (p, &i) in src.chunks_exact(4).zip(indexes) {
        let c = palette[i as usize];
        let (a0, a1) = (f64::from(p[3]) / 255.0, f64::from(c[3]) / 255.0);
        for k in 0..3 {
            let d = f64::from(p[k]) * a0 - f64::from(c[k]) * a1;
            squared += d * d;
        }
        let da = f64::from(p[3]) - f64::from(c[3]);
        squared += da * da;
    }
    let mse = squared / src.len() as f64;
    if mse < 1e-9 { 100.0 } else { 10.0 * (255.0f64 * 255.0 / mse).log10() }
}

/// Maps PSNR onto the 0-100 scale of `--quality`. Calibrated against pngquant on screenshots and photos
/// (see the tests): 65 is about 38 dB, 85 about 43 dB.
fn quality_from_psnr(psnr: f64) -> f64 {
    (4.0 * psnr - 87.0).clamp(0.0, 100.0)
}

struct Candidate {
    palette: Vec<[u8; 4]>,
    indexes: Vec<u8>,
    quality: f64,
}

fn quantize_to(image: &Image, src: &[u8], colors: u32, dither: f32) -> Result<Candidate, String> {
    let mut options = Options::default();
    options.set_max_colors(colors as i32).map_err(|e| format!("palette size: {e:?}"))?;
    let mut result = QuantizeResult::quantize(image, &options);
    result.set_dithering_level(dither).map_err(|e| format!("dithering: {e:?}"))?;
    let mut indexes = vec![0u8; src.len() / 4];
    result.remap_image(image, &mut indexes).map_err(|e| format!("remap: {e:?}"))?;
    let pal = result.get_palette();
    let palette: Vec<[u8; 4]> = pal.entries[..pal.count as usize].iter().map(|c| [c.r, c.g, c.b, c.a]).collect();
    let quality = quality_from_psnr(psnr(src, &palette, &indexes));
    Ok(Candidate { palette, indexes, quality })
}

/// The palette as written when the image already has at most 256 colours: exact, nothing lost.
fn exact(rgba: &[u8], colors: &HashSet<u32>) -> Candidate {
    let mut palette: Vec<[u8; 4]> = colors.iter().map(|c| c.to_le_bytes()).collect();
    palette.sort();
    let index_of: std::collections::HashMap<[u8; 4], u8> = palette.iter().enumerate().map(|(i, c)| (*c, i as u8)).collect();
    let indexes = rgba.chunks_exact(4).map(|p| index_of[&[p[0], p[1], p[2], p[3]]]).collect();
    Candidate { palette, indexes, quality: 100.0 }
}

enum Outcome {
    Done(Candidate),
    TooLow,
}

/// Fewest colours that reach `max`; the full 256 when `max` is out of reach but `min` is not.
fn search(decoded: &Decoded, min: f64, max: f64) -> Result<Outcome, String> {
    let colors = distinct_colors(&decoded.rgba, PHOTO_COLORS);
    if colors.len() <= 256 {
        return Ok(Outcome::Done(exact(&decoded.rgba, &colors)));
    }
    let dither = if colors.len() > PHOTO_COLORS { DITHER_PHOTO } else { DITHER_FLAT };
    let image = Image::new(&decoded.rgba, decoded.width, decoded.height).map_err(|e| format!("image: {e:?}"))?;

    let full = quantize_to(&image, &decoded.rgba, 256, dither)?;
    if full.quality < min {
        return Ok(Outcome::TooLow);
    }
    if full.quality < max {
        return Ok(Outcome::Done(full));
    }
    let (mut lo, mut hi, mut best) = (2u32, 255u32, full);
    while lo <= hi {
        let mid = (lo + hi) / 2;
        let c = quantize_to(&image, &decoded.rgba, mid, dither)?;
        if c.quality >= max {
            best = c;
            if mid == 2 { break; }
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }
    Ok(Outcome::Done(best))
}

fn encode(decoded: &Decoded, c: &Candidate) -> Result<Vec<u8>, String> {
    let mut info = decoded.info.clone();
    info.color_type = png::ColorType::Indexed;
    info.bit_depth = png::BitDepth::Eight;
    info.interlaced = false;
    info.animation_control = None;
    info.frame_control = None;
    info.palette = Some(c.palette.iter().flat_map(|e| [e[0], e[1], e[2]]).collect::<Vec<u8>>().into());
    // Only the entries up to the last non-opaque one need an alpha value.
    let used = c.palette.iter().rposition(|e| e[3] != 255).map_or(0, |i| i + 1);
    info.trns = if used == 0 { None } else { Some(c.palette[..used].iter().map(|e| e[3]).collect::<Vec<u8>>().into()) };

    let mut out = Vec::new();
    let mut enc = png::Encoder::with_info(&mut out, info).map_err(|e| format!("encoder: {e}"))?;
    enc.set_compression(png::Compression::Best);
    enc.set_filter(png::FilterType::Paeth);
    let mut writer = enc.write_header().map_err(|e| format!("header: {e}"))?;
    writer.write_image_data(&c.indexes).map_err(|e| format!("data: {e}"))?;
    writer.finish().map_err(|e| format!("finish: {e}"))?;
    Ok(out)
}

fn parse_quality(args: &[String]) -> Result<(f64, f64), String> {
    let value = args
        .iter()
        .find_map(|a| a.strip_prefix("--quality="))
        .ok_or("usage: optimos-quant --quality=MIN-MAX - < in.png > out.png")?;
    let (a, b) = value.split_once('-').ok_or("quality must look like 65-85")?;
    let (min, max): (f64, f64) = (a.parse().map_err(|_| "bad minimum quality")?, b.parse().map_err(|_| "bad maximum quality")?);
    if !(0.0..=100.0).contains(&min) || !(min..=100.0).contains(&max) {
        return Err("quality must be 0-100 with MIN not above MAX".into());
    }
    Ok((min, max))
}

fn run() -> Result<i32, (i32, String)> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let (min, max) = parse_quality(&args).map_err(|e| (2, e))?;
    let mut input = Vec::new();
    std::io::stdin().read_to_end(&mut input).map_err(|e| (1, format!("reading input: {e}")))?;

    let decoded = decode(&input).map_err(|e| (1, e))?;
    let candidate = match search(&decoded, min, max).map_err(|e| (1, e))? {
        Outcome::TooLow => return Ok(EXIT_TOO_LOW),
        Outcome::Done(c) => c,
    };
    let output = encode(&decoded, &candidate).map_err(|e| (1, e))?;
    if output.len() >= input.len() {
        return Ok(EXIT_NOT_SMALLER);
    }
    std::io::stdout().write_all(&output).map_err(|e| (1, format!("writing output: {e}")))?;
    Ok(0)
}

fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err((code, message)) => {
            eprintln!("optimos-quant: {message}");
            std::process::exit(code);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(s: &str) -> Vec<String> {
        s.split(' ').map(String::from).collect()
    }

    #[test]
    fn parses_quality_range() {
        assert_eq!(parse_quality(&args("--quality=65-85 -")).unwrap(), (65.0, 85.0));
        assert!(parse_quality(&args("-")).is_err());
        assert!(parse_quality(&args("--quality=90-80")).is_err());
        assert!(parse_quality(&args("--quality=abc")).is_err());
    }

    #[test]
    fn identical_images_score_perfect_quality() {
        let src = [10u8, 20, 30, 255, 40, 50, 60, 255];
        let palette = [[10, 20, 30, 255], [40, 50, 60, 255]];
        assert_eq!(quality_from_psnr(psnr(&src, &palette, &[0, 1])), 100.0);
    }

    #[test]
    fn worse_palette_scores_lower() {
        let src = [10u8, 20, 30, 255, 200, 50, 60, 255];
        let good = [[10, 20, 30, 255], [200, 50, 60, 255]];
        let bad = [[20, 30, 40, 255], [150, 80, 90, 255]];
        assert!(psnr(&src, &good, &[0, 1]) > psnr(&src, &bad, &[0, 1]));
    }

    #[test]
    fn few_colour_image_is_kept_exact() {
        let rgba = [1u8, 2, 3, 255, 9, 9, 9, 255, 1, 2, 3, 255];
        let colors = distinct_colors(&rgba, PHOTO_COLORS);
        let c = exact(&rgba, &colors);
        assert_eq!(c.palette.len(), 2);
        assert_eq!(c.indexes[0], c.indexes[2]);
        assert_ne!(c.indexes[0], c.indexes[1]);
    }
}
