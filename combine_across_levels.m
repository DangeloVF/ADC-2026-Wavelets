function combined = combine_across_levels(relDiff, opt)
  % COMBINE_ACROSS_LEVELS  Weighted geometric mean of per-level onset signals.
  %
  %   combined = combine_across_levels(relDiff, opt)
  %
  % relDiff : L x J matrix. Column 1 is the finest (highest-frequency) wavelet
  %           level, column J is the coarsest (lowest-frequency). Each column
  %           is already normalised against its own baseline (see
  %           transient_detector.m), so columns are roughly comparable in scale.
  %
  % opt.taperLevels : how many levels at the COARSE (low-frequency) end get
  %                   progressively down-weighted. Default 2.
  % opt.taperSlope  : width in levels of the sigmoid transition between
  %                   "full weight" and "tapered". Default 1 (fairly sharp).
  %                   Larger = softer, more gradual roll-off.
  % opt.epsFloor    : floor added before taking logs, so a genuine 0 in a
  %                   column doesn't produce -Inf. Default 1e-6.
  %
  % Weighted geometric mean: combined = prod(relDiff_i ^ w_i), sum(w_i) = 1.
  % Plain geometric mean (w_i = 1/J for all i) is the default; it still
  % requires every level to agree, which is right for a hiss/wash false
  % positive but too strict for a transient whose energy is concentrated
  % in the fine levels only (a guitar pick attack, a voiced plosive burst)
  % and barely reaches the coarse end at all. Tapering the coarse levels'
  % weight down (sigmoid, not a hard cutoff, so there's no seam in the
  % output) means a weak coarse-level reading can no longer single-handedly
  % veto an otherwise strong fine-level consensus.

  if (nargin < 2)
    opt = struct();
  endif
  taperLevels = GetOpt(opt, "taperLevels", 2);
  taperSlope  = GetOpt(opt, "taperSlope",  1);
  epsFloor    = GetOpt(opt, "epsFloor",    1e-6);

  J       = columns(relDiff);
  idx     = (1:J)';
  center  = J - taperLevels + 0.5;              % transition sits between the kept and tapered levels
  wRaw    = 1 ./ (1 + exp((idx - center) / taperSlope));  % sigmoid, ~1 for fine levels, ->0 for coarse
  weights = wRaw / sum(wRaw);

  logRel   = log(relDiff + epsFloor);
  combined = exp(logRel * weights);
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction
