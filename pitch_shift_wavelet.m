function [y, bands] = pitch_shift_wavelet(x, semitones, wavelet, J)
  % PITCH_SHIFT_WAVELET  The fairest wavelet-domain pitch shift we could build.
  %
  %   [y, bands] = pitch_shift_wavelet(x, semitones, wavelet, J)
  %
  % The real DWT has no phase, so there is nothing to rotate directly. The
  % most generous attempt is:
  %   1. Split x into J+1 band signals, one per wavelet level plus the
  %      approximation, by reconstructing each level on its own. Because
  %      the transform is linear, these sum exactly back to x.
  %   2. Take each band's analytic signal (Hilbert transform) and multiply
  %      its unwrapped phase by r = 2^(semitones/12). That scales the
  %      instantaneous frequency by r and keeps the envelope.
  %   3. Sum the shifted bands. Duration is unchanged, so no resampling.
  %
  % Step 2 is exact when a band holds ONE sinusoid. It fails when a band
  % holds several, because the analytic phase of a sum of partials is a
  % beat pattern, not any one partial's phase. Bands here are an octave
  % wide (constant-Q, Mallat ch. 4): a 1.4-2.8 kHz band of a voice at 200 Hz
  % holds about 7 harmonics. The phase vocoder's 21 Hz bins hold about one
  % each. That resolution trade is the reason this is the counterexample.
  %
  % bands is L x (J+1), column 1 = approximation, then levels coarse to fine,
  % returned for inspection.

  r = 2 ^ (semitones / 12);
  x = x(:);
  L = numel(x);

  c    = wavelet_decompose(x, wavelet, J);   
  info = struct("wavelet", wavelet, "J", J);

  bands = zeros(L, J + 1);  
  y     = zeros(L, 1);

  for b = 0:J                            % 0 = approximation, then level J down to 1
    ci.detail = zeros(size(c.detail));
    ci.approx = zeros(L, 1);
    if (b == 0)
      ci.approx = c.approx;
    else
      lev = J + 1 - b;                   % coarse to fine
      ci.detail(:, lev) = c.detail(:, lev);
    endif

    band = wavelet_reconstruct(ci, info);
    band = band(1:L);
    bands(:, b + 1) = band;
    y = y + ShiftBand(band, r);
  endfor
endfunction

function y = ShiftBand(band, r)
  a = hilbert(band);
  y = abs(a) .* cos(r * unwrap(angle(a)));
endfunction
