% PITCH_TWO_TONE_TEST  Isolate why the wavelet pitch shifter fails.
%
% Case 1: one tone (1500 Hz). Case 2: two tones (1500 + 1800 Hz) that both
% fall inside the same wavelet level (about 1.4-2.8 kHz). Both cases are
% shifted up 5 semitones (expected output: 2002 Hz, and 2002 + 2402 Hz).
%
% Expected result: the phase vocoder gets both cases right, because its
% bins resolve the two tones separately. The octave-band wavelet method
% gets case 1 right (one sinusoid per band, so the analytic phase is that
% sinusoid's phase) and case 2 wrong (two sinusoids in one band beat at
% 300 Hz, so the "phase" being scaled is a beat pattern). The high-Q
% wavelet (CQT) has channels about 40 Hz wide at 1.5 kHz, so the two tones
% land in separate channels and case 2 should come out clean. Writes fig8.

pkg load signal;
pkg load ltfat;
ltfatstart;

fs        = 44100;
semitones = 5;
wavelet   = "db4";
J         = 8;
r         = 2 ^ (semitones / 12);

t = (0:fs - 1)' / fs;                  % 1 second
cases = {
  [1500],       "One tone, 1500 Hz";
  [1500, 1800], "Two tones in one wavelet band, 1500 + 1800 Hz"
};

methodNames  = {"phase vocoder", "octave wavelet", "high-Q wavelet"};
methodStyles = {"b", "r", "g"};

nFft = 2 ^ 15;
mid  = round(0.25 * fs) + (1:round(0.5 * fs))';   % middle half second, away from edges
win  = 0.5 - 0.5 * cos(2 * pi * (0:numel(mid) - 1)' / numel(mid));
f    = (0:nFft / 2)' * fs / nFft;

fig8 = figure;
for k = 1:rows(cases)
  freqs = cases{k, 1};
  x = sum(sin(2 * pi * t * freqs), 2) / numel(freqs);

  ys = {pitch_shift_pv(x, semitones), ...
        pitch_shift_wavelet(x, semitones, wavelet, J), ...
        pitch_shift_cqt(x, fs, semitones)};

  subplot(rows(cases), 1, k);
  hold on;
  printf("%s\n  expected: %s Hz\n", cases{k, 2}, mat2str(round(freqs * r)));
  for m = 1:numel(ys)
    spec = 20 * log10(abs(fft(win .* ys{m}(mid), nFft))(1:nFft / 2 + 1) + 1e-9);
    spec = spec - max(spec);
    plot(f, spec, methodStyles{m});

    % Threshold 25 dB: a Hann window's first sidelobe is about -31 dB, so
    % anything within 25 dB of the max is a real component, not leakage.
    % findpeaks needs non-negative data, hence the +100 offset.
    minDist  = round(20 / (fs / nFft));   % 20 Hz
    [~, loc] = findpeaks(max(spec, -100) + 100, "MinPeakHeight", 75, "MinPeakDistance", minDist);
    printf("  %-15s peaks within 25 dB of max: %d, at %s Hz\n", methodNames{m}, numel(loc), mat2str(round(f(loc))'));
  endfor
  for e = freqs * r
    plot([e, e], [-100, 5], "k--");
  endfor
  xlim([1000, 3500]); ylim([-80, 5]);
  xlabel("Frequency (Hz)"); ylabel("dB (rel. peak)");
  title(sprintf("%s, shifted +%d st (dashed = expected)", cases{k, 2}, semitones));
  legend(methodNames{:});
endfor

print(fig8, "fig8_pitch_two_tone.png", "-dpng", "-r150");
printf("wrote fig8_pitch_two_tone.png\n");
