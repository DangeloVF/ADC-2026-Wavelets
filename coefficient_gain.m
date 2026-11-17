function [c2, levelGainDb] = coefficient_gain(c, gainDb, opt)
  % COEFFICIENT_GAIN  Apply a tilted, per-level gain directly to wavelet coefficients.
  %
  %   [c2, levelGainDb] = coefficient_gain(c, gainDb, opt)
  %
  % c       : struct from wavelet_decompose (c.detail is L x J, c.approx is L x 1).
  % gainDb  : L x 1 gain trajectory from gain_computer - the SAME trajectory
  %           Method A would apply broadband, so the A/B comparison isolates
  %           the application point, not the detector or gain law.
  % opt     : forwarded to level_tilt_weights (tiltDbPerLevel).
  %
  % Returns c2 (gained coefficients, ready for wavelet_reconstruct) and
  % levelGainDb (L x J, each level's actual applied dB curve, for plotting).
  %
  % This is Donoho-Johnstone shrinkage run in reverse (CLAUDE.md): classical
  % wavelet denoising shrinks coefficients towards zero below a threshold.
  % Here, time rather than per-coefficient magnitude gates the effect (the
  % SAME cross-scale-coherent detector that drives Method A), but the result
  % lands in the same place - coefficients that are already large at a real
  % transient get scaled up (sharpen) or down (soften), while quiet
  % stretches are left alone. c.approx is never touched: boosting it would
  % be inflating the body, which is exactly what a crossover-free broadband
  % shaper can't avoid and this can.

  if (nargin < 3)
    opt = struct();
  endif

  J = columns(c.detail);
  w = level_tilt_weights(J, opt);

  levelGainDb = gainDb * w';            % L x J, outer product: curve x per-level share
  c2.detail   = c.detail .* 10 .^ (levelGainDb / 20);
  c2.approx   = c.approx;               % body left untouched
endfunction
