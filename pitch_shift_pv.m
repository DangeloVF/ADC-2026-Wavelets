function y = pitch_shift_pv(x, semitones, opt)
  % PITCH_SHIFT_PV  STFT phase vocoder pitch shift: time-stretch, then resample.
  %
  %   y = pitch_shift_pv(x, semitones, opt)
  %
  % x         : mono input, column vector.
  % semitones : shift amount (positive = up).
  % opt.N     : FFT size. Default 2048 (21.5 Hz bins at 44.1 kHz).
  % opt.hop   : analysis hop. Default N/4.
  %
  % Classic phase vocoder (Dolson 1986; Zolzer (ed.), DAFX, ch. 7):
  %   1. Time-stretch by r = 2^(semitones/12): read frames every Ha samples,
  %      write them every Hs = round(r*Ha) samples, and advance each bin's
  %      phase by its measured true frequency times Hs, so partials stay
  %      continuous across the wider spacing.
  %   2. Resample by Ha/Hs to restore the original duration, which scales
  %      every frequency by Hs/Ha.
  % This is the textbook version with no phase locking (Laroche and Dolson
  % 1999), so it has the usual "phasiness". That's deliberate: it's the
  % baseline everyone knows, and it should still beat the wavelet attempt.
  % Written as a frame loop rather than a matrix so it maps directly onto a
  % JUCE processBlock.

  if (nargin < 3)
    opt = struct();
  endif
  N  = GetOpt(opt, "N",   2048);
  Ha = GetOpt(opt, "hop", N / 4);

  r  = 2 ^ (semitones / 12);
  Hs = round(r * Ha);

  x   = x(:);
  L   = numel(x);
  win = 0.5 - 0.5 * cos(2 * pi * (0:N - 1)' / N);   % periodic Hann
  xp  = [zeros(N, 1); x; zeros(N, 1)];              % pad so the edges get full frames

  nFrames = floor((numel(xp) - N) / Ha) + 1;
  omega   = 2 * pi * Ha * (0:N - 1)' / N;           % expected phase advance per bin per hop

  outLen = (nFrames - 1) * Hs + N;
  y      = zeros(outLen, 1);
  wSum   = zeros(outLen, 1);

  prevPhase  = zeros(N, 1);
  synthPhase = zeros(N, 1);

  for m = 1:nFrames
    a  = (m - 1) * Ha;
    X  = fft(win .* xp(a + 1:a + N));
    ph = angle(X);

    if (m == 1)
      synthPhase = ph;
    else
      dPhi       = PrincArg(ph - prevPhase - omega);   % deviation from the bin centre
      synthPhase = synthPhase + (omega + dPhi) * Hs / Ha;
    endif
    prevPhase = ph;

    frame = real(ifft(abs(X) .* exp(1i * synthPhase))) .* win;
    s = (m - 1) * Hs;
    y(s + 1:s + N)    = y(s + 1:s + N)    + frame;
    wSum(s + 1:s + N) = wSum(s + 1:s + N) + win .^ 2;
  endfor

  y = y ./ max(wSum, 1e-3 * max(wSum));

  g = gcd(Ha, Hs);
  y = resample(y, Ha / g, Hs / g);

  y = y(N + 1:min(N + L, numel(y)));                % drop the padding
  if (numel(y) < L)
    y(end + 1:L) = 0;
  endif
endfunction

function p = PrincArg(p)
  p = mod(p + pi, 2 * pi) - pi;
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction
