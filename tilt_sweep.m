% TILT_SWEEP  Render Method B at several tiltDbPerLevel settings for listening.
%
% The detector and gain curve are computed once (they don't depend on the
% tilt), then only coefficient_gain + reconstruction repeat per setting.
% Smaller tilt = more of the gain reaches the coarser levels = more body in
% the boost (punchier, but closer to a broadband shaper); larger tilt =
% edge only (subtler).

pkg load signal;
pkg load ltfat;
ltfatstart;

audioFile    = "Drums.mp3";
depthDb      = 6;
tiltList     = [6, 4, 3, 2, 1];

[x, fs] = audioread(audioFile);
x = x(:, 1);

wavelet = "db4";
J       = 5;
c       = wavelet_decompose(x, wavelet, J);
info    = struct("wavelet", wavelet, "J", J);

[detectFn, dbg] = transient_detector(c, fs, struct( ...
  "baselineTau", 0.05, ...
  "holdTime",    0.03));

gainDb = gain_computer(detectFn, fs, struct( ...
  "thresholdDb", -18, ...
  "kneeDb",        9, ...
  "depthDb",  depthDb, ...
  "attack",    0.001, ...
  "release",    0.05, ...
  "lookaheadS", 0.003));

dryRms = sqrt(mean(x .^ 2));
printf("dry: peak %.3f, RMS %.4f\n", max(abs(x)), dryRms);

for k = 1:numel(tiltList)
  tilt = tiltList(k);
  c2   = coefficient_gain(c, gainDb, struct("tiltDbPerLevel", tilt));
  y    = wavelet_reconstruct(c2, info);

  peak = max(abs(y));
  printf("tilt %d dB/level: peak %.3f, RMS change %+.2f dB\n", ...
         tilt, peak, 20 * log10(sqrt(mean(y .^ 2)) / dryRms));
  if (peak > 1)
    printf("  warning: clipping\n");
  endif

  audiowrite(sprintf("out_methodB_tilt%ddB.wav", tilt), y, fs);
endfor
