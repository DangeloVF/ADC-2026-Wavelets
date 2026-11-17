% RUN_PITCH_MAIN  High-Q wavelet (CQT + PGHI) pitch shift of the funk mix.
%
% The mix is where the Q dial is audible both ways: narrow filters (low
% Qvar) keep the keys and bass harmonics clean but smear the kick and
% snare in time; wide filters (high Qvar) keep the drums tighter but let
% neighbouring harmonics share a channel. One output per Qvar, to choose
% the presented setting by ear.
%
% Levels, as in run_shaper_compare.m: every output is RMS-matched to the
% dry signal; if anything then clips, all outputs plus a mono dry copy
% share one scale factor. Channel 1 only (mono), like the other scripts.
%
% Writes out_main_dry_mono.wav and out_main_cqt_qvar<q>_<st>st.wav.

pkg load ltfat;
ltfatstart(0);

audioFile = "Main sample.wav";
semitones = -3;                      % 12 channels down at 48 per octave
qVars     = [1, 2, 4];

[x, fs] = audioread(audioFile);
x = x(:, 1);
printf("%s: %.1f s, shifting %+d semitones\n", audioFile, numel(x) / fs, semitones);

Rms   = @(v) sqrt(mean(v .^ 2));
outs  = {};
names = {};
for q = qVars
  tic;
  y = pitch_shift_cqt(x, fs, semitones, struct("qVar", q));
  printf("  Qvar %g: done in %.0f s, raw RMS change %+.2f dB\n", q, toc, 20 * log10(Rms(y) / Rms(x)));
  outs{end + 1}  = y * Rms(x) / Rms(y);
  names{end + 1} = sprintf("out_main_cqt_qvar%g_%+dst.wav", q, semitones);
endfor
outs{end + 1}  = x;
names{end + 1} = "out_main_dry_mono.wav";

peakAll = max(cellfun(@(v) max(abs(v)), outs));
scale   = min(1, 0.98 / peakAll);
if (scale < 1)
  printf("  level match: all outputs scaled by %.2f dB to keep the loudest peak at -0.18 dBFS\n", 20 * log10(scale));
endif
for k = 1:numel(outs)
  audiowrite(names{k}, outs{k} * scale, fs);
  printf("  wrote %s\n", names{k});
endfor
