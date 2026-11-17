function [c, info] = wavelet_decompose(x, wavelet, J)
  % WAVELET_DECOMPOSE  Undecimated wavelet transform, re-ordered for detector use.
  %
  %   [c, info] = wavelet_decompose(x, wavelet, J)
  %
  % x       : mono input signal, column vector.
  % wavelet : LTFAT wavelet name, e.g. "db4".
  % J       : number of decomposition levels.
  %
  % c.detail : L x J matrix. Column 1 is level 1 (finest, highest frequency,
  %            fastest-changing detail). Column J is the coarsest detail.
  % c.approx : L x 1, the level-J approximation (lowest frequency residue).
  %
  % Uses LTFAT's 'sqrt' filter scaling (the default): each level's filter is
  % normalised by 1/sqrt(a), which makes the undecimated transform a tight
  % frame. That keeps per-level energy comparisons honest, since the
  % transform itself isn't inflating energy at coarser levels (CLAUDE.md:
  % check 'sqrt' vs 'noscale'). iufwt must use the same default to reconstruct.
  %
  % ufwt orders its L x (J+1) output by increasing centre frequency:
  %   col 1       = cA_J   (coarsest approximation)
  %   col 2..J+1  = cD_J, cD_{J-1}, ..., cD_1  (coarsest detail -> finest detail)
  % Verified empirically against pure tones; see project notes.

  raw = ufwt(x, wavelet, J);         % L x (J+1), 'sqrt' scaling by default

  info.wavelet = wavelet;
  info.J       = J;
  info.fs      = [];                 % filled in by the caller if known

  c.approx = raw(:, 1);
  c.detail = fliplr(raw(:, 2:end));  % reverse so column 1 = finest (cD_1)
endfunction
