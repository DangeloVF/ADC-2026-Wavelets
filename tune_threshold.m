% TUNE_THRESHOLD  Sweep the gain computer threshold per file.
%
% Drums.mp3 at -18 dB is the reference: validated by ear. The aim on a
% denser file is to find the threshold whose gain curve behaves like the
% reference's, measured by
%   duty   : fraction of time the gain is above half the depth
%   events : rising crossings of half the depth, per second
%   A RMS  : Method A's RMS change (near the full depth = a volume knob)
%   A/B crest : crest-factor change, the "punch" measure
% The detector runs once per file; only the gain computer is swept.

pkg load signal;
pkg load ltfat;
ltfatstart(0);

files      = {"Drums.mp3", "Main sample.wav"};
thresholds = [-18, -12, -9, -6, -3, 0];
depthDb    = 6;
tiltDb     = 3;
wavelet    = "db4";
J          = 5;

gainOpt = struct("kneeDb", 9, "depthDb", depthDb, "attack", 0.001, ...
                 "release", 0.05, "lookaheadS", 0.003);

Rms   = @(v) sqrt(mean(v .^ 2));
Crest = @(v) 20 * log10(max(abs(v)) / Rms(v));

for f = 1:numel(files)
  [x, fs] = audioread(files{f});
  x = x(:, 1);
  c    = wavelet_decompose(x, wavelet, J);
  info = struct("wavelet", wavelet, "J", J);
  detectFn = transient_detector(c, fs, struct("baselineTau", 0.05, "holdTime", 0.03));

  dDb = 10 * log10(detectFn + 1e-12);
  printf("\n=== %s: detection level percentiles (dB) 50th %.1f, 75th %.1f, 90th %.1f, 99th %.1f ===\n", ...
         files{f}, prctile(dDb, [50, 75, 90, 99]));
  printf("  thresh   duty  events/s   A RMS   A crest   B crest\n");

  for th = thresholds
    gainOpt.thresholdDb = th;
    gainDb = gain_computer(detectFn, fs, gainOpt);

    above  = gainDb > depthDb / 2;
    duty   = mean(above);
    events = sum(diff(above) == 1) / (numel(x) / fs);

    yA = x .* 10 .^ (gainDb / 20);
    yB = wavelet_reconstruct(coefficient_gain(c, gainDb, struct("tiltDbPerLevel", tiltDb)), info);
    yB = yB(1:numel(x));

    printf("  %+5.0f  %5.1f%%  %8.1f  %+6.2f  %+8.2f  %+8.2f\n", th, 100 * duty, events, ...
           20 * log10(Rms(yA) / Rms(x)), Crest(yA) - Crest(x), Crest(yB) - Crest(x));
  endfor
endfor
