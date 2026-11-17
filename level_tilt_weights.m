function w = level_tilt_weights(J, opt)
  % LEVEL_TILT_WEIGHTS  Per-level share of the gain trajectory for Method B.
  %
  %   w = level_tilt_weights(J, opt)
  %
  % J   : number of detail levels (c.detail is L x J, column 1 = finest).
  % opt.tiltDbPerLevel : how many fewer dB of the gain curve each
  %                      successively coarser level receives. Default 3
  %                      (chosen by ear on Drums.mp3 from a 1-6 sweep).
  %
  % Returns w, a J x 1 vector of weights in (0, 1]. w(1) = 1 (the finest
  % level gets the gain curve applied in full); w(i) = 10^(-(i-1)*tiltDbPerLevel/20).
  %
  % CLAUDE.md's design call for Method B is "a tilt across levels is enough
  % of a control" - boost the fine detail levels that carry the transient
  % edge without inflating the body of the sound, which a conventional
  % broadband shaper can't do without a crossover. One knob (dB per level)
  % is enough to express that: it reads directly as "how fast the effect
  % rolls off from edge to body," which is easy to defend in Q&A compared
  % to an arbitrary per-level curve.

  if (nargin < 2)
    opt = struct();
  endif
  tiltDbPerLevel = GetOpt(opt, "tiltDbPerLevel", 3);

  idx = (0:J - 1)';
  w   = 10 .^ (-idx * tiltDbPerLevel / 20);
endfunction

function val = GetOpt(opt, name, default)
  if (isfield(opt, name))
    val = opt.(name);
  else
    val = default;
  endif
endfunction
