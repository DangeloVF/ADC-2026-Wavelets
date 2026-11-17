% PROTOTYPE_SHAPER_METHODA  Wavelet detector + broadband time-domain gain.
%
% This is Method A from CLAUDE.md: the wavelet detector drives a broadband
% gain on the dry signal. It's the honest baseline the coefficient-domain
% Method B gets compared against later - same detector, different gain
% application point.
%
% Running this script writes three PNGs (fig1/fig2/fig3) alongside the two
% shaped .wav files, so the figures can be reviewed without re-running
% anything interactively.

pkg load signal;
pkg load ltfat;
ltfatstart;

audioFile = "Drums.mp3";
zoomStart = 2.0;                   % seconds - window shown in the fig3 zoom-in
zoomEnd   = 4.0;

[x, fs] = audioread(audioFile);
x = x(:, 1);                      % left channel -> mono

wavelet = "db4";
J       = 5;

c = wavelet_decompose(x, wavelet, J);
c.approx;                          % unused by Method A, kept for inspection

[detectFn, dbg] = transient_detector(c, fs, struct( ...
  "baselineTau", 0.05, ...
  "holdTime",    0.03));

depthList = [4, -4];               % sharpen, then soften, for an A/B pair
tx = (0:numel(x) - 1)' / fs;
yByDepth = cell(1, numel(depthList));

fig1 = figure;
subplot(4, 1, 1);
plot(tx, x);
xlabel("Time (s)"); ylabel("Amplitude"); title("Dry signal");

subplot(4, 1, 2);
plot(tx, dbg.combined);
xlabel("Time (s)"); ylabel("Detection"); title("Combined cross-scale detection function");

for k = 1:numel(depthList)
  depthDb = depthList(k);

  [gainDb, gdbg] = gain_computer(detectFn, fs, struct( ...
    "thresholdDb", -18, ...
    "kneeDb",        9, ...
    "depthDb",  depthDb, ...
    "attack",    0.001, ...
    "release",    0.05, ...
    "lookaheadS", 0.003));

  y = x .* 10 .^ (gainDb / 20);    % broadband time-domain gain on the dry signal
  yByDepth{k} = y;

  subplot(4, 1, 3);
  hold on;
  plot(tx, gainDb);
  subplot(4, 1, 4);
  hold on;
  plot(tx, y);

  outName = sprintf("out_methodA_depth%+ddB.wav", depthDb);
  audiowrite(outName, y, fs);
  printf("wrote %s\n", outName);
endfor

subplot(4, 1, 3);
xlabel("Time (s)"); ylabel("Gain (dB)"); title("Gain curve: sharpen (+6 dB) vs soften (-6 dB)");
legend("sharpen", "soften");

subplot(4, 1, 4);
xlabel("Time (s)"); ylabel("Amplitude"); title("Shaped output");
legend("sharpen", "soften");

print(fig1, "fig1_detector_gain.png", "-dpng", "-r150");
printf("wrote fig1_detector_gain.png\n");

% ---- Second figure: where the detector fired, against the actual waveforms ----
% pick_transients reduces the continuous detection function to discrete event
% times, purely for marking a plot - the detector/gain path above never uses
% discrete events, only the continuous function.
transientTimes = pick_transients(dbg.combined, fs, struct( ...
  "thresholdPercentile", 95, ...
  "minDistS",            0.03));
printf("marking %d detected transients\n", numel(transientTimes));

waveforms = [{x}, yByDepth];
titles    = [{"Dry signal"}, arrayfun(@(d) sprintf("Shaped, depth %+d dB", d), depthList, "UniformOutput", false)];

fig2 = figure;
for k = 1:numel(waveforms)
  subplot(numel(waveforms), 1, k);
  plot(tx, waveforms{k});
  hold on;
  yl = ylim();
  for e = 1:numel(transientTimes)
    plot([transientTimes(e), transientTimes(e)], yl, "r--");
  endfor
  xlabel("Time (s)"); ylabel("Amplitude"); title(titles{k});
endfor

print(fig2, "fig2_waveforms_markers.png", "-dpng", "-r150");
printf("wrote fig2_waveforms_markers.png\n");

% ---- Third figure: zoomed-in window, waveform and detection function stacked ----
% Same markers as fig2, but zoomed to [zoomStart, zoomEnd] so individual
% onsets can be checked against the waveform by eye.
zoomMask = tx >= zoomStart & tx <= zoomEnd;
zoomTimes = transientTimes(transientTimes >= zoomStart & transientTimes <= zoomEnd);

fig3 = figure;
subplot(2, 1, 1);
plot(tx(zoomMask), x(zoomMask));
hold on;
yl = ylim();
for e = 1:numel(zoomTimes)
  plot([zoomTimes(e), zoomTimes(e)], yl, "r--");
endfor
xlabel("Time (s)"); ylabel("Amplitude");
title(sprintf("Dry signal, %.1f-%.1fs, with detected transients", zoomStart, zoomEnd));

subplot(2, 1, 2);
plot(tx(zoomMask), dbg.combined(zoomMask));
hold on;
yl = ylim();
for e = 1:numel(zoomTimes)
  plot([zoomTimes(e), zoomTimes(e)], yl, "r--");
endfor
xlabel("Time (s)"); ylabel("Detection");
title("Combined cross-scale detection function, same window");

print(fig3, "fig3_zoom.png", "-dpng", "-r150");
printf("wrote fig3_zoom.png\n");
