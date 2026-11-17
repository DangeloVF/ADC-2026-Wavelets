# Wavelets: Stop Letting Fourier Smear Your Transients

Code, slides, script and references from my talk at **ADC 2026** (Bristol, 9-11 November).

## What's in here

| Part                   | What it does                                                                                                                                                              | Main script                                 |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------|
| **Transient detector** | Finds transients using undecimated wavelet coefficients, with a cross-scale check so a loud hi-hat wash doesn't fire it                                                   | `transient_detector.m`                      |
| **Transient shaper**   | The same detector driving two gain stages: Method A (broadband gain, the baseline) and Method B (gain applied directly to the wavelet coefficients, tilted across levels) | `run_shaper_compare.m`                      |
| **Pitch shifter**      | The counterexample: an octave-band wavelet can't pitch-shift, and a high-Q (constant-Q) wavelet with PGHI phase reconstruction can                                        | `run_pitch_main.m`, `pitch_two_tone_test.m` |

Also in the repo:

- `DangeloVFWaveletsSlides.pptx`: the slides
- `Script.md`: roughly what I said
- `references.md`: papers and books I used and ones worth reading.

## Setup

Everything is a GNU Octave prototype. Octave doesn't have MATLAB's Wavelet Toolbox, so the transforms come from [LTFAT](https://ltfat.org) instead. That was the fiddly bit of the setup.

1. Install [GNU Octave](https://octave.org).
2. Install the signal package: `pkg install -forge signal`
3. Install LTFAT: download the Octave package from [ltfat.org](https://ltfat.org) and run `pkg install ltfat-<version>.tar.gz`.

The scripts load both packages themselves.

## Running it

From the repo folder:

```
octave-cli run_shaper_compare.m    # Method A vs B, level-matched, on the drums and the mix
octave-cli pitch_two_tone_test.m   # why the octave-band wavelet can't pitch-shift
octave-cli run_pitch_main.m        # high-Q wavelet pitch shift of the funk mix
```

Every output is RMS-matched to the dry signal, so neither method wins just by being louder. The processed WAVs are written next to the scripts.

Expect the shapers to run way faster than the pitch shifter, a method for doing the CQT in realtime is in the references.

### File guide

- **Wavelet transform:** `wavelet_decompose.m`, `wavelet_reconstruct.m`
- **Detector:** `transient_detector.m`, `combine_across_levels.m`, `pick_transients.m`
- **Gain law:** `gain_computer.m` (soft knee, attack/release, lookahead)
- **Method B:** `coefficient_gain.m`, `level_tilt_weights.m`
- **Shaper experiments:** `prototype_shaper_methodA.m`, `prototype_shaper_methodB.m`, `tilt_sweep.m`, `tune_threshold.m`
- **Pitch shifters:** `pitch_shift_wavelet.m` (octave-band), `pitch_shift_cqt.m` (high-Q + PGHI), `pitch_shift_pv.m` (textbook phase vocoder, for reference), `prototype_pitch_shift.m`

## Not done yet

There's no JUCE port yet: everything here runs offline. The real-time versions are on the list for when life calms down.

## Questions

Any issues, feel free to email me or send me a DM on social media.
