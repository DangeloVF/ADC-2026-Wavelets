function [gainDb, debug] = gain_computer(detectFn, fs, opt)
  % GAIN_COMPUTER  Soft-knee gain law + attack/release smoothing + lookahead.
  %
  %   [gainDb, debug] = gain_computer(detectFn, fs, opt)
  %
  % detectFn : L x 1 detection function from transient_detector (energy-like,
  %            >= 0, not yet in dB).
  % opt.thresholdDb : knee centre, in dB, on the log-compressed detectFn.
  % opt.kneeDb      : knee width in dB either side of the threshold.
  % opt.depthDb     : gain reached once fully past the knee. Positive
  %                   sharpens (CLAUDE.md: depth above 0 dB = sharpen),
  %                   negative softens.
  % opt.attack      : attack time constant (s).
  % opt.release     : release time constant (s).
  % opt.lookaheadS  : shift the smoothed gain curve earlier by this many
  %                   seconds. Only possible offline; in JUCE this becomes
  %                   reported plugin latency.
  %
  % Energy (detectFn) is squared-coefficient-like; the knee below works in
  % dB because a soft knee is naturally a log-domain shape (Giannoulis,
  % Massberg and Reiss, JAES 2012). detectFn is log-compressed first to
  % keep that distinction explicit rather than building the knee on a
  % quantity with sum-of-squares units.

  if (nargin < 3)
    opt = struct();
  endif
  thresholdDb = GetOpt(opt, "thresholdDb", -18);
  kneeDb      = GetOpt(opt, "kneeDb",        9);
  depthDb     = GetOpt(opt, "depthDb",       6);
  attackS     = GetOpt(opt, "attack",     0.001);
  releaseS    = GetOpt(opt, "release",    0.05);
  lookaheadS  = GetOpt(opt, "lookaheadS", 0.003);

  epsFloor = 1e-12;
  xDb      = 10 * log10(detectFn + epsFloor);   % log-compressed detection function

  target = SoftKneeTarget(xDb, thresholdDb, kneeDb, depthDb);
  smoothed = AttackReleaseSmooth(target, fs, attackS, releaseS);

  lookaheadSamples = round(lookaheadS * fs);
  gainDb = ShiftEarlier(smoothed, lookaheadSamples);

  debug.xDb      = xDb;
  debug.target   = target;
  debug.smoothed = smoothed;
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction

function g = SoftKneeTarget(xDb, t, w, depth)
  % Quadratic soft knee (Giannoulis et al., eq. 4, adapted): ramps smoothly
  % from 0 dB up to `depth` dB over a knee of width w centred on threshold t,
  % instead of switching on with a hard step (CLAUDE.md: hard thresholds click).
  g = zeros(size(xDb));
  for n = 1:numel(xDb)
    d = xDb(n) - t;
    if (2 * d < -w)
      g(n) = 0;
    elseif (2 * abs(d) <= w)
      g(n) = depth * (d + w / 2) ^ 2 / (2 * w ^ 2);
    else
      g(n) = depth;
    endif
  endfor
endfunction

function y = AttackReleaseSmooth(x, fs, attackS, releaseS)
  % One-pole smoothing with separate attack/release coefficients, applied
  % to the gain curve itself (kept separate from the detector's own
  % baseline time constants per CLAUDE.md).
  aAtk = exp(-1 / (attackS  * fs));
  aRel = exp(-1 / (releaseS * fs));
  y    = zeros(size(x));
  y(1) = x(1);
  for n = 2:numel(x)
    if (x(n) > y(n - 1))
      a = aAtk;
    else
      a = aRel;
    endif
    y(n) = (1 - a) * x(n) + a * y(n - 1);
  endfor
endfunction

function y = ShiftEarlier(x, nSamples)
  % Shift x earlier by nSamples (offline lookahead). Pads the tail by
  % holding the last value, since there's nothing further to look ahead to.
  if (nSamples <= 0)
    y = x;
    return;
  endif
  y = [x(nSamples + 1:end); repmat(x(end), nSamples, 1)];
endfunction
