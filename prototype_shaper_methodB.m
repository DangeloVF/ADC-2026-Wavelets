% PROTOTYPE_SHAPER_METHODB  Wavelet detector + per-level, tilted coefficient-domain gain.
%
% Method B from CLAUDE.md: the centrepiece. Same detector and gain law as
% Method A (prototype_shaper_methodA.m), identical parameters, so the A/B
% comparison isolates the one thing that differs: gain is applied directly
% to the wavelet coefficients, tilted across levels so the finest (most
% transient-sensitive) level gets the gain curve in full and progressively
% coarser levels get less of it. The approximation (the body of the sound)
% is never touched.
%
% Donoho-Johnstone shrinkage denoising, run in reverse: instead of shrinking
% coefficients below a magnitude threshold towards zero, scale coefficients
% up or down exactly where/when the cross-scale-coherent detector fires.
%
% Writes fig1-fig4 PNGs and two shaped .wav files, same pattern as Method A.

pkg load signal;
pkg load ltfat;
ltfatstart;

audioFile = "Drums.mp3";
zoomStart = 2.0;                   % seconds - window shown in the fig3/fig4 zoom-ins
zoomEnd   = 4.0;

[x, fs] = audioread(audioFile);
x = x(:, 1);                      % left channel -> mono

wavelet = "db4";
J       = 5;

c    = wavelet_decompose(x, wavelet, J);
info = struct("wavelet", wavelet, "J", J);

[detectFn, dbg] = transient_detector(c, fs, struct( ...
  "baselineTau", 0.05, ...
  "holdTime",    0.03));

% Same gain-law parameters as Method A, so the comparison is fair.
depthList = [6, -6];               % sharpen, then soften, for an A/B pair
tx = (0:numel(x) - 1)' / fs;
yByDepth           = cell(1, numel(depthList));
levelGainDbByDepth = cell(1, numel(depthList));

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

  [c2, levelGainDb] = coefficient_gain(c, gainDb, struct("tiltDbPerLevel", 3));
  y = wavelet_reconstruct(c2, info);

  yByDepth{k}           = y;
  levelGainDbByDepth{k} = levelGainDb;

  peak = max(abs(y));
  if (peak > 1)
    printf("warning: depth %+d dB output peak is %.3f (%.2f dBFS) - clipping\n", ...
           depthDb, peak, 20 * log10(peak));
  endif

  outName = sprintf("out_methodB_depth%+ddB.wav", depthDb);
  audiowrite(outName, y, fs);
  printf("wrote %s\n", outName);
endfor

subplot(4, 1, 3);
plot(tx, levelGainDbByDepth{1});     % sharpen case: shows the tilt shape directly
xlabel("Time (s)"); ylabel("Gain (dB)");
title("Per-level gain curves, sharpen +6 dB (level 1 = finest)");
legend(arrayfun(@(i) sprintf("level %d", i), 1:J, "UniformOutput", false));

subplot(4, 1, 4);
hold on;
for k = 1:numel(depthList)
  plot(tx, yByDepth{k});
endfor
xlabel("Time (s)"); ylabel("Amplitude"); title("Shaped output");
legend("sharpen", "soften");

print(fig1, "fig1_methodB_detector_gain.png", "-dpng", "-r150");
printf("wrote fig1_methodB_detector_gain.png\n");

% ---- Second figure: where the detector fired, against the actual waveforms ----
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

print(fig2, "fig2_methodB_waveforms_markers.png", "-dpng", "-r150");
printf("wrote fig2_methodB_waveforms_markers.png\n");

% ---- Third figure: zoomed-in dry waveform vs shaped outputs ----
zoomMask  = tx >= zoomStart & tx <= zoomEnd;
zoomTimes = transientTimes(transientTimes >= zoomStart & transientTimes <= zoomEnd);

fig3 = figure;
subplot(3, 1, 1);
plot(tx(zoomMask), x(zoomMask));
hold on;
yl = ylim();
for e = 1:numel(zoomTimes)
  plot([zoomTimes(e), zoomTimes(e)], yl, "r--");
endfor
xlabel("Time (s)"); ylabel("Amplitude");
title(sprintf("Dry signal, %.1f-%.1fs, with detected transients", zoomStart, zoomEnd));

for k = 1:numel(depthList)
  subplot(3, 1, 1 + k);
  plot(tx(zoomMask), yByDepth{k}(zoomMask));
  hold on;
  yl = ylim();
  for e = 1:numel(zoomTimes)
    plot([zoomTimes(e), zoomTimes(e)], yl, "r--");
  endfor
  xlabel("Time (s)"); ylabel("Amplitude");
  title(sprintf("Shaped, depth %+d dB, same window", depthList(k)));
endfor

print(fig3, "fig3_methodB_zoom.png", "-dpng", "-r150");
printf("wrote fig3_methodB_zoom.png\n");

% ---- Fourth figure: per-level gain heatmap, zoomed - the direct evidence for the ----
% tilt doing what CLAUDE.md asks: strong effect on fine levels, near-nothing
% on the coarse ones, body (approximation) excluded entirely.
fig4 = figure;
imagesc(tx(zoomMask), 1:J, levelGainDbByDepth{1}(zoomMask, :)');
set(gca, "ydir", "normal");
colorbar;
xlabel("Time (s)"); ylabel("Level (1 = finest)");
title(sprintf("Per-level applied gain (dB), sharpen +6 dB, %.1f-%.1fs", zoomStart, zoomEnd));

print(fig4, "fig4_methodB_tilt_heatmap.png", "-dpng", "-r150");
printf("wrote fig4_methodB_tilt_heatmap.png\n");
