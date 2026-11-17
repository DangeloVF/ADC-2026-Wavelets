function [y, info] = pitch_shift_cqt(x, fs, semitones, opt)
  % PITCH_SHIFT_CQT  Pitch shift in a high-Q wavelet (constant-Q) filterbank.
  %
  %   [y, info] = pitch_shift_cqt(x, fs, semitones, opt)
  %
  % x               : mono input, column vector.
  % fs              : sample rate (Hz). Needed because the filters are placed in Hz.
  % semitones       : shift amount. semitones * binsPerOct / 12 must be an integer.
  % opt.binsPerOct  : channels per octave. Default 48 (a quarter-semitone apart).
  % opt.fMin        : lowest centre frequency (Hz). Default 50.
  % opt.qVar        : bandwidth multiplier (LTFAT's Qvar). Default 2. Larger means
  %                   wider filters, shorter in time: better transients and better
  %                   phase reconstruction, worse harmonic separation.
  % opt.redMul      : redundancy multiplier (smaller hop). Default 2.
  %
  % This is still a wavelet transform: every channel is the same mother
  % filter dilated to a new centre frequency, so Q = fc / bandwidth is
  % constant. What changes from pitch_shift_wavelet.m is the density:
  % 48 channels per octave instead of 1, and a complex (analytic) filter
  % per channel instead of a real one. With Q around 35, a channel at 5 kHz
  % is about 145 Hz wide, narrower than a voice's harmonic spacing, so each
  % channel holds one partial: the condition the octave DWT broke.
  %
  % Method (Schoerkhuber, Klapuri and Sontacchi, JAES 2013, with the phase
  % step replaced by PGHI):
  %   1. Analyse with cqtfilters + ufilterbank (uniform hop, so every
  %      channel shares one time grid and channels can be moved freely).
  %   2. Shift magnitudes up k = semitones * binsPerOct / 12 channels. On a
  %      log-frequency axis, multiplying every frequency by 2^(semitones/12)
  %      is a translation, so pitch shifting is a move, not a resample.
  %   3. Rebuild a consistent phase from the shifted magnitude with phase
  %      gradient heuristic integration (Prusa and Holighaus, "Non-iterative
  %      filter bank phase (re)construction", EUSIPCO 2017). Moving
  %      coefficients leaves their phases wrong for the new frequency;
  %      PGHI integrates the phase from the magnitude's time and frequency
  %      derivatives, which locks partials horizontally and vertically.
  %   4. Synthesise with the canonical dual frame (exact inverse, about 1e-15).
  %
  % info returns the filterbank and the coefficients, for plotting.

  if (nargin < 4)
    opt = struct();
  endif
  binsPerOct = GetOpt(opt, "binsPerOct", 48);
  fMin       = GetOpt(opt, "fMin",       50);
  qVar       = GetOpt(opt, "qVar",       2);
  redMul     = GetOpt(opt, "redMul",     2);

  k = semitones * binsPerOct / 12;
  if (k != round(k))
    error("pitch_shift_cqt: %g semitones is not a whole number of channels at %d per octave", ...
          semitones, binsPerOct);
  endif

  x = x(:);
  L = numel(x);

  [g, a, fc, Ladm, fbInfo] = cqtfilters(fs, fMin, fs / 2, binsPerOct, L, ...
                                        "uniform", "Qvar", qVar, "redmul", redMul);
  xp = [x; zeros(Ladm - L, 1)];
  c  = ufilterbank(xp, g, a);                % frames x channels, complex

  % Channel 1 is a lowpass fill below fMin and the last is a highpass fill
  % at Nyquist; only the constant-Q channels between them are moved.
  % Content shifted past the top is dropped (it would alias), and the
  % bottom k channels are left empty.
  cqtIdx = 2:numel(g) - 1;
  mag    = zeros(size(c));
  if (k >= 0)
    mag(:, cqtIdx(1 + k:end))   = abs(c(:, cqtIdx(1:end - k)));
  else
    mag(:, cqtIdx(1:end + k))   = abs(c(:, cqtIdx(1 - k:end)));
  endif

  cShift = filterbankconstphase(mag, a, fbInfo.fc, fbInfo.tfr);

  gd = filterbankrealdual(g, a, Ladm);
  y  = 2 * real(ifilterbank(cShift, gd, a));
  y  = y(1:L);

  info = struct("g", {g}, "a", a, "fc", fc, "c", c, "cShift", cShift, "k", k);
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction
