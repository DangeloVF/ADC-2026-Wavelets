function [detectFn, debug] = transient_detector(c, fs, opt)
  % TRANSIENT_DETECTOR  Cross-scale wavelet onset detector.
  %
  %   [detectFn, debug] = transient_detector(c, fs, opt)
  %
  % c  : struct from wavelet_decompose (c.detail is L x J, column 1 = finest).
  % fs : sample rate in Hz.
  % opt.baselineTau : time constant (s) of the "recent history" energy
  %                   baseline each level is compared against. Default 0.05.
  % opt.holdTime    : minimum spacing (s) between retriggers, so ring-down
  %                   doesn't fire a second detection. Default 0.03.
  % opt.levels      : which detail levels to use. Default: all of them.
  % opt.combineOpt  : struct forwarded to combine_across_levels (taperLevels,
  %                   taperSlope, epsFloor) for the cross-scale weighting.
  % opt.noiseFloorFrac : baseline floor per level, as a fraction of that
  %                   level's mean energy over the whole input. Default 1e-3.
  %                   Without this, a baseline that has decayed towards true
  %                   digital silence (e.g. the lead-in before a track
  %                   starts) makes (e - baseline)/baseline blow up on the
  %                   very next non-zero sample, firing a false detection
  %                   that has nothing to do with a real transient.
  %
  % This follows Bello et al. (2005): detect change in energy, not level, by
  % half-wave-rectifying the difference between instantaneous and smoothed
  % energy. Each level is normalised against its OWN running baseline before
  % anything is combined, so a loud level doesn't dominate a quiet one.

  if (nargin < 3)
    opt = struct();
  endif
  baselineTau   = GetOpt(opt, "baselineTau",   0.05);
  holdTime      = GetOpt(opt, "holdTime",      0.03);
  levels        = GetOpt(opt, "levels",        1:columns(c.detail));
  combineOpt    = GetOpt(opt, "combineOpt",    struct());
  noiseFloorFrac = GetOpt(opt, "noiseFloorFrac", 1e-3);

  epsFloor = 1e-12;
  aBase    = exp(-1 / (baselineTau * fs));   % one-pole coefficient, recent-history baseline

  J       = numel(levels);
  L       = rows(c.detail);
  relDiff = zeros(L, J);

  for i = 1:J
    lev      = levels(i);
    e        = c.detail(:, lev) .^ 2;          % instantaneous per-sample energy
    baseline = OnePoleSmooth(e, aBase);         % per-level running RMS / recent history
    noiseFloor = noiseFloorFrac * mean(e);      % absolute floor, scaled to this level's own energy
    baseline = max(baseline, noiseFloor);
    relDiff(:, i) = max((e - baseline) ./ (baseline + epsFloor), 0);
  endfor

  % Cross-scale coherence: combine the J per-level onset signals into one.
  % See combine_across_levels.m - this is the part worth deciding yourself.
  combined = combine_across_levels(relDiff, combineOpt);

  detectFn = HoldPeak(combined, round(holdTime * fs));

  debug.relDiff   = relDiff;
  debug.combined  = combined;
  debug.levels    = levels;
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction

function y = OnePoleSmooth(x, a)
  % One-pole lowpass, y[n] = (1-a)*x[n] + a*y[n-1]. Used as a running
  % energy baseline: slower than any single transient, fast enough to
  % track programme-level changes (CLAUDE.md: detector has its own short
  % time constants, separate from the shaper's gain smoothing).
  y    = zeros(size(x));
  y(1) = x(1);
  for n = 2:numel(x)
    y(n) = (1 - a) * x(n) + a * y(n - 1);
  endfor
endfunction

function y = HoldPeak(x, holdSamples)
  % Peak-hold: once x rises to a new peak, hold that value for holdSamples
  % before allowing it to fall, so a snare's ring-down can't retrigger the
  % detector while the previous hit is still decaying.
  y          = zeros(size(x));
  peakVal    = 0;
  holdLeft   = 0;
  for n = 1:numel(x)
    if (x(n) >= peakVal)
      peakVal  = x(n);
      holdLeft = holdSamples;
    elseif (holdLeft > 0)
      holdLeft = holdLeft - 1;
    else
      peakVal = x(n);
    endif
    y(n) = peakVal;
  endfor
endfunction
