function [times, idx] = pick_transients(combined, fs, opt)
  % PICK_TRANSIENTS  Reduce a continuous detection function to discrete event times.
  %
  %   [times, idx] = pick_transients(combined, fs, opt)
  %
  % combined : L x 1 detection function (pre-hold is fine; MinPeakDistance
  %            below does the same job as transient_detector's hold time).
  % opt.thresholdPercentile : peaks below this percentile of `combined` are
  %                           ignored. Default 95.
  % opt.minDistS            : minimum spacing between reported events, in
  %                           seconds. Default 0.03 (matches the detector's
  %                           default hold time).
  %
  % Used only for visualisation/inspection - picking a single instant per
  % transient to mark on a waveform plot, not part of the detector itself.

  if (nargin < 3)
    opt = struct();
  endif
  thresholdPct = GetOpt(opt, "thresholdPercentile", 95);
  minDistS     = GetOpt(opt, "minDistS",            0.03);

  threshold      = prctile(combined, thresholdPct);
  minDistSamples = round(minDistS * fs);

  [~, idx] = findpeaks(combined, "MinPeakHeight", threshold, "MinPeakDistance", minDistSamples);
  times = (idx - 1) / fs;
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction
