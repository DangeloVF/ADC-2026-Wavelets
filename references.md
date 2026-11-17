# References

References for **"Wavelets: Stop Letting Fourier Smear Your Transients"** (ADC 2026, Bristol).

---

## 1. Time-frequency foundations (the "why Fourier smears" argument)

- **Gabor, D. (1946).** Theory of communication. Part 1: The analysis of information. *Journal of the Institution of Electrical Engineers, Part III: Radio and Communication Engineering*, 93(26), 429–441. doi:[10.1049/ji-3-2.1946.0074](https://doi.org/10.1049/ji-3-2.1946.0074)
  The original statement of the time-frequency uncertainty relation for signals (the Gabor limit). Source for the claim that it is the fixed STFT window, not Fourier analysis itself, that forces the trade-off.

- **Strang, G. (1993).** Wavelet transforms versus Fourier transforms. *Bulletin of the American Mathematical Society*, 28(2), 288–305. doi:[10.1090/S0273-0979-1993-00390-2](https://doi.org/10.1090/S0273-0979-1993-00390-2). Free: [arXiv:math/9304214](https://arxiv.org/abs/math/9304214)
  A short, readable comparison of the two transforms. The best single "start here" paper for the thesis of this talk.

## 2. Wavelet theory

- **Mallat, S. (2009).** *A Wavelet Tour of Signal Processing: The Sparse Way* (3rd ed.). Academic Press.
  The standard reference. Time-frequency tiling, multiresolution analysis, the fast wavelet transform, and singularity (transient) analysis.

- **Mallat, S. G. (1989).** A theory for multiresolution signal decomposition: The wavelet representation. *IEEE Transactions on Pattern Analysis and Machine Intelligence*, 11(7), 674–693. doi:[10.1109/34.192463](https://doi.org/10.1109/34.192463)
  The paper that introduced the DWT as an iterated filter bank (Mallat's algorithm). The Octave prototype runs the undecimated variant of this (the à trous algorithm; see Shensa below).

- **Daubechies, I. (1992).** *Ten Lectures on Wavelets*. CBMS-NSF Regional Conference Series in Applied Mathematics, vol. 61. SIAM. doi:[10.1137/1.9781611970104](https://doi.org/10.1137/1.9781611970104)
  Primary source for the compactly supported Daubechies wavelets used in place of Haar.

- **Strang, G., & Nguyen, T. (1996).** *Wavelets and Filter Banks*. Wellesley-Cambridge Press.
  Builds wavelets from the filter-bank side (perfect reconstruction, polyphase, maxflat filters). The closest theory text to the implementation.

## 3. Undecimated / stationary wavelet transform (why `ufwt` and not a critically sampled DWT)

- **Nason, G. P., & Silverman, B. W. (1995).** The stationary wavelet transform and some statistical applications. In A. Antoniadis & G. Oppenheim (Eds.), *Wavelets and Statistics*, Lecture Notes in Statistics, vol. 103, 281–299. Springer. doi:[10.1007/978-1-4612-2544-7_17](https://doi.org/10.1007/978-1-4612-2544-7_17)
  Names and describes the non-decimated transform. Removing decimation gives shift invariance and avoids breaking alias cancellation when gains change over time.

- **Coifman, R. R., & Donoho, D. L. (1995).** Translation-invariant de-noising. In *Wavelets and Statistics*, Lecture Notes in Statistics, vol. 103, 125–150. Springer.
  The same idea from the denoising side ("cycle spinning"). Shows why shift-variant processing creates artefacts that the undecimated transform avoids.

- **Shensa, M. J. (1992).** The discrete wavelet transform: Wedding the à trous and Mallat algorithms. *IEEE Transactions on Signal Processing*, 40(10), 2464–2482. doi:[10.1109/78.157290](https://doi.org/10.1109/78.157290)
  Shows that the à trous algorithm (dilated filters, no decimation) and Mallat's decimated filter bank are the same transform, sampled differently. This is the algorithm LTFAT's `ufwt` runs in the prototype.

## 4. Transients and singularities in the wavelet domain (the detector)

- **Mallat, S., & Hwang, W. L. (1992).** Singularity detection and processing with wavelets. *IEEE Transactions on Information Theory*, 38(2), 617–643. doi:[10.1109/18.119727](https://doi.org/10.1109/18.119727)
  Modulus maxima and how they propagate across scales. Basis for the cross-scale coherence check in the detector.

- **Daudet, L., Molla, S., & Torrésani, B. (2001).** Transient detection and encoding using wavelet coefficient trees. *Colloque GRETSI*, Toulouse. [hal-01306501](https://hal.science/hal-01306501)
  Transients appear as trees of significant wavelet coefficients, so they are compact in the wavelet domain. This is the core reason the transient shaper works.

- **Daudet, L. (2006).** A review on techniques for the extraction of transients in musical signals. In *Computer Music Modeling and Retrieval (CMMR 2005)*, LNCS 3902, 219–232. Springer.
  Survey of transient extraction methods. Good context for where this approach sits.

- **Bello, J. P., Daudet, L., Abdallah, S., Duxbury, C., Davies, M., & Sandler, M. B. (2005).** A tutorial on onset detection in music signals. *IEEE Transactions on Speech and Audio Processing*, 13(5), 1035–1047. doi:[10.1109/TSA.2005.851998](https://doi.org/10.1109/TSA.2005.851998)
  Standard reference for onset detection functions, including the half-wave-rectified difference used in the detector.

- **Marchi, E., Ferroni, G., Eyben, F., Squartini, S., & Schuller, B. (2014).** Audio onset detection: A wavelet packet based approach with recurrent neural networks. *Proc. International Joint Conference on Neural Networks (IJCNN 2014)*, Beijing, 3585–3591. doi:[10.1109/IJCNN.2014.6889669](https://doi.org/10.1109/IJCNN.2014.6889669)
  Evidence that wavelet multiresolution features help with onset and transient tasks.

## 5. Processing the coefficients (Method B and the gain law)

- **Donoho, D. L., & Johnstone, I. M. (1994).** Ideal spatial adaptation by wavelet shrinkage. *Biometrika*, 81(3), 425–455. doi:[10.1093/biomet/81.3.425](https://doi.org/10.1093/biomet/81.3.425)
  Wavelet shrinkage denoising. Method B is framed as this run in reverse: boost large coefficients rather than shrink small ones. Related rather than identical: shrinkage gates each coefficient by its own magnitude, whereas Method B gates whole levels in time using the detector.

- **Donoho, D. L. (1995).** De-noising by soft-thresholding. *IEEE Transactions on Information Theory*, 41(3), 613–627. doi:[10.1109/18.382009](https://doi.org/10.1109/18.382009)
  The soft-threshold rule itself, for comparison with the soft-knee gain computer.

- **Giannoulis, D., Massberg, M., & Reiss, J. D. (2012).** Digital dynamic range compressor design: A tutorial and analysis. *Journal of the Audio Engineering Society*, 60(6), 399–408.
  Source of the soft-knee gain computer and the attack/release smoothing design.

## 6. Prior art: real-time wavelet audio plugins

- **Rajmic, P., & Vlach, J. (2007).** Real-time audio processing via segmented wavelet transform. *Proc. 10th Int. Conference on Digital Audio Effects (DAFx-07)*, Bordeaux.

- **Rajmic, P., Průša, Z., & Konczi, R. (2012).** VST plug-in module performing wavelet transform in real-time. *Proc. 15th Int. Conference on Digital Audio Effects (DAFx-12)*, York, 11–18. [PDF](https://www.utko.fekt.vut.cz/~rajmic/papers/DAFx12-rajmic_prusa-segdwt_plugin.pdf)
  Block-wise (segmented) DWT for real-time use, with a VST implementation. The most relevant prior work for turning the offline prototype into a real-time plugin.

## 7. Pitch shifting: the octave-wavelet counterexample, then the high-Q fix

### Phase vocoder (the FFT reference)

- **Zölzer, U. (Ed.) (2011).** *DAFX: Digital Audio Effects* (2nd ed.). Wiley. doi:[10.1002/9781119991298](https://doi.org/10.1002/9781119991298)
  Ch. 7 covers the textbook phase vocoder that `pitch_shift_pv.m` follows (no phase locking).

- **Laroche, J., & Dolson, M. (1999).** Improved phase vocoder time-scale modification of audio. *IEEE Transactions on Speech and Audio Processing*, 7(3), 323–332. doi:[10.1109/89.759041](https://doi.org/10.1109/89.759041)
  Phase locking, which the reference phase vocoder here does not use. Why the CQT against PV comparison is not like for like.

- **Laroche, J., & Dolson, M. (1999).** New phase-vocoder techniques for real-time pitch shifting, chorusing, harmonizing, and other exotic audio modifications. *Journal of the Audio Engineering Society*, 47(11), 928–936.

### Constant-Q (high-Q wavelet) pitch shifting

- **Schörkhuber, C., Klapuri, A., & Sontacchi, A. (2013).** Audio pitch shifting using the constant-Q transform. *Journal of the Audio Engineering Society*, 61(7/8), 562–572.
  Prior art for the high-Q pitch shifter: a shift is a translation along the log-frequency axis.

- **Holighaus, N., Dörfler, M., Velasco, G. A., & Grill, T. (2013).** A framework for invertible, real-time constant-Q transforms. *IEEE Transactions on Audio, Speech, and Language Processing*, 21(4), 775–785. doi:[10.1109/TASL.2012.2234114](https://doi.org/10.1109/TASL.2012.2234114). Free: [arXiv:1210.0084](https://arxiv.org/abs/1210.0084)
  Builds an invertible CQT from nonstationary Gabor frames and introduces the sliCQ, a sliced version for real-time, block-wise processing. How a real-time version of the high-Q shifter could be built. The prototype here is offline only.

- **Průša, Z., & Holighaus, N. (2017).** Non-iterative filter bank phase (re)construction. *Proc. 25th European Signal Processing Conference (EUSIPCO 2017)*, Kos, 952–956. [IEEE Xplore](https://ieeexplore.ieee.org/document/8081342). Free: [arXiv:2202.07498](https://arxiv.org/abs/2202.07498)
  PGHI for general filter banks (LTFAT `filterbankconstphase`): rebuilds the phase from the shifted CQT magnitudes.

- **Průša, Z., Balazs, P., & Søndergaard, P. L. (2017).** A noniterative method for reconstruction of phase from STFT magnitude. *IEEE/ACM Transactions on Audio, Speech, and Language Processing*, 25(5), 1154–1164. doi:[10.1109/TASLP.2017.2678166](https://doi.org/10.1109/TASLP.2017.2678166)
  The original STFT version of PGHI (LTFAT `pghi`). The fair FFT-side opponent for the high-Q shifter.

## 8. Wavelets beyond raw audio

- **Baluja, S., & Covell, M. (2008).** Waveprint: Efficient wavelet-based audio fingerprinting. *Pattern Recognition*, 41(11), 3467–3480. doi:[10.1016/j.patcog.2008.05.006](https://doi.org/10.1016/j.patcog.2008.05.006)
  Applies wavelets to the spectrogram as an image rather than to the audio directly. An example of wavelets earning their place somewhere other than raw audio.

## 9. Software used

- **Průša, Z., Søndergaard, P. L., & Rajmic, P. (2016).** Discrete wavelet transforms in the Large Time-Frequency Analysis Toolbox for MATLAB/GNU Octave. *ACM Transactions on Mathematical Software*, 42(4), 1–23. doi:[10.1145/2839298](https://doi.org/10.1145/2839298)

- **LTFAT**, The Large Time-Frequency Analysis Toolbox. <https://ltfat.org> (GPLv3)
- **GNU Octave.** <https://octave.org>

## 10. Audio used in slides

- "I Got a Stick Arr Bryan Teoh" Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 License <http://creativecommons.org/licenses/by/4.0>
  Pitch shifter audio

  n.b. the drums audio for the transient shaper was from a free sample pack I got a while ago from a convention I was at. I forget who the distributor was.
  