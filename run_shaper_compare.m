% RUN_SHAPER_COMPARE  Method A vs Method B on several files, level-matched.
%
% For each file: one detector run and one gain curve per depth, applied
% both ways (A: broadband gain on the dry signal; B: tilted gain on the
% wavelet coefficients), so the only difference is the application point.
%
% Level matching, so neither method wins by being louder:
%   1. Every output is RMS-matched to the dry signal.
%   2. If anything then peaks above 1, all of that file's outputs, plus a
%      dry reference copy, are scaled down by one common factor. Relative
%      levels are kept and nothing clips.
% The raw (unmatched) peak, RMS and crest-factor changes are printed first,
% because those are the "punch without loudness" numbers.
%
% Writes out_<tag>_dry.wav, out_<tag>_methodA/B_depth<d>dB.wav and
% fig12_<tag>_detection.png (where the detector fired, full and zoomed).
% The existing prototype_shaper_method*.m scripts are left untouched.

1;                                   % script marker: local functions follow, defined before use

function s = ClipNote(peak)
  s = "";
  if (peak > 1)
    s = sprintf("  (raw output clips: peak %.2f)", peak);
  endif
endfunction

pkg load signal;
pkg load ltfat;
ltfatstart(0);

% thresholdDb per file: Drums.mp3 keeps the by-ear reference (-18 dB); the
% funk mix uses -3 dB, chosen by tune_threshold.m to match the reference's
% gain duty cycle (61.7% against 64%), not by which method it flatters.
files     = {"Drums.mp3", "drums", -18; "Main sample.wav", "main", -3};
depthList = [6, -6];
tiltDb    = 3;
wavelet   = "db4";
J         = 5;
zoomLen   = 2.0;                     % seconds shown in the zoomed panel

gainOpt = struct("kneeDb", 9, "attack", 0.001, ...
                 "release", 0.05, "lookaheadS", 0.003);

Rms   = @(v) sqrt(mean(v .^ 2));
Crest = @(v) 20 * log10(max(abs(v)) / Rms(v));

for f = 1:rows(files)
  [audioFile, tag, gainOpt.thresholdDb] = files{f, :};
  [x, fs] = audioread(audioFile);
  x  = x(:, 1);                      % left channel -> mono
  tx = (0:numel(x) - 1)' / fs;
  printf("\n=== %s (%.1f s), threshold %+d dB: dry peak %.2f dBFS, crest %.1f dB ===\n", ...
         audioFile, numel(x) / fs, gainOpt.thresholdDb, 20 * log10(max(abs(x))), Crest(x));

  c    = wavelet_decompose(x, wavelet, J);
  info = struct("wavelet", wavelet, "J", J);
  [detectFn, dbg] = transient_detector(c, fs, struct("baselineTau", 0.05, "holdTime", 0.03));

  outs  = {};
  names = {};
  for depthDb = depthList
    gainOpt.depthDb = depthDb;
    gainDb = gain_computer(detectFn, fs, gainOpt);

    yA = x .* 10 .^ (gainDb / 20);
    yB = wavelet_reconstruct(coefficient_gain(c, gainDb, struct("tiltDbPerLevel", tiltDb)), info);
    yB = yB(1:numel(x));

    for m = {{"methodA", yA}, {"methodB", yB}}
      [name, y] = m{1}{:};
      printf("  %s %+d dB raw: peak %+.2f dB, RMS %+.2f dB, crest %+.2f dB%s\n", name, depthDb, ...
             20 * log10(max(abs(y)) / max(abs(x))), 20 * log10(Rms(y) / Rms(x)), ...
             Crest(y) - Crest(x), ClipNote(max(abs(y))));
      outs{end + 1}  = y * Rms(x) / Rms(y);
      names{end + 1} = sprintf("out_%s_%s_depth%+ddB.wav", tag, name, depthDb);
    endfor
  endfor

  outs{end + 1}  = x;
  names{end + 1} = sprintf("out_%s_dry.wav", tag);
  peakAll = max(cellfun(@(v) max(abs(v)), outs));
  scale   = min(1, 0.98 / peakAll);
  if (scale < 1)
    printf("  level match: all %s outputs scaled by %.2f dB to keep the loudest peak at -0.18 dBFS\n", ...
           tag, 20 * log10(scale));
  endif
  for k = 1:numel(outs)
    audiowrite(names{k}, outs{k} * scale, fs);
  endfor
  printf("  wrote %d files: out_%s_*.wav\n", numel(outs), tag);

  % --- where the detector fired: full file, then a zoom on the densest 2 s ---
  times = pick_transients(dbg.combined, fs, struct("thresholdPercentile", 95, "minDistS", 0.03));
  counts    = arrayfun(@(t0) sum(times >= t0 & times < t0 + zoomLen), times);
  [~, best] = max(counts);
  z0 = min(times(best), max(0, tx(end) - zoomLen));
  zm = tx >= z0 & tx <= z0 + zoomLen;
  printf("  detector marked %d transients\n", numel(times));

  fig = figure("position", [100, 100, 1400, 800]);
  panels = {tx, x, "Dry signal, detected transients"; ...
            tx(zm), x(zm), sprintf("Zoom, %.1f-%.1f s", z0, z0 + zoomLen); ...
            tx(zm), dbg.combined(zm), "Cross-scale detection function, same window"};
  for p = 1:rows(panels)
    subplot(rows(panels), 1, p);
    plot(panels{p, 1}, panels{p, 2});
    hold on;
    yl  = ylim();
    tIn = times(times >= panels{p, 1}(1) & times <= panels{p, 1}(end));
    for e = tIn(:)'
      plot([e, e], yl, "r--");
    endfor
    title(sprintf("%s: %s", audioFile, panels{p, 3}));
    xlabel("Time (s)");
  endfor
  figName = sprintf("fig12_%s_detection.png", tag);
  print(fig, figName, "-dpng", "-r150");
  printf("  wrote %s\n", figName);
endfor
