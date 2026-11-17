% PROTOTYPE_PITCH_SHIFT  Plugin 3: when wavelets fail at pitch, and what fixes it.
%
% Shifts the vocal three ways and RMS-matches every output to the dry
% signal (so none wins by being louder):
%   - phase vocoder (STFT, textbook, no phase locking)
%   - octave-band wavelet (the DWT from plugins 1 and 2): fails, because
%     each band holds several harmonics
%   - high-Q wavelet (constant-Q filterbank + PGHI) at several Qvar
%     settings, the "Q dial": narrow filters separate harmonics, wide
%     filters keep consonants sharp
% Harmonics are where the difference shows in the spectrograms: clean
% parallel lines, or smeared within each band.

pkg load signal;
pkg load ltfat;
ltfatstart;

audioFile = "Vocal.mp3";
semitones = 5;
wavelet   = "db4";
J         = 8;                       % finest low-frequency resolution we can give the wavelets
qVars     = [1, 2, 4];               % high-Q sweep: Q of about 69, 35 and 17 at 48 bins/octave
qVarPlot  = 2;                       % the one shown in the spectrogram figure
zoomStart = 0.6;                     % seconds - spectrogram window (vocal starts at about 0.63 s)
zoomEnd   = 3.6;
maxFreq   = 5000;                    % Hz - top of the spectrogram, where the harmonics are visible

[x, fs] = audioread(audioFile);
x = x(:, 1);

printf("shifting %.1f s of audio by %+d semitones\n", numel(x) / fs, semitones);
yPv  = pitch_shift_pv(x, semitones);
yWav = pitch_shift_wavelet(x, semitones, wavelet, J);

outputs = {yPv, yWav};
names   = {"pv", "wavelet"};
for q = qVars
  outputs{end + 1} = pitch_shift_cqt(x, fs, semitones, struct("qVar", q));
  names{end + 1}   = sprintf("cqt_qvar%g", q);
endfor

dryRms = sqrt(mean(x .^ 2));
for k = 1:numel(outputs)
  y = outputs{k} * dryRms / sqrt(mean(outputs{k} .^ 2));   % RMS-match to dry
  if (max(abs(y)) > 1)
    printf("warning: %s output peaks at %.2f after RMS matching - clipping\n", names{k}, max(abs(y)));
  endif
  outputs{k} = y;
  outName = sprintf("out_pitch_%s_%+dst.wav", names{k}, semitones);
  audiowrite(outName, y, fs);
  printf("wrote %s\n", outName);
endfor

cqtIdx  = 2 + find(qVars == qVarPlot);
signals = {x, outputs{1}, outputs{2}, outputs{cqtIdx}};
titles  = {"Dry", sprintf("Phase vocoder, %+d st", semitones), ...
           sprintf("Octave wavelet (J = %d, %s), %+d st", J, wavelet, semitones), ...
           sprintf("High-Q wavelet (48 bins/oct, Qvar %g), %+d st", qVarPlot, semitones)};

nWin    = 2048;
hannW   = 0.5 - 0.5 * cos(2 * pi * (0:nWin - 1)' / nWin);
zoomEnd = min(zoomEnd, numel(x) / fs);   % clamp to the file length
seg     = round(zoomStart * fs) + 1:round(zoomEnd * fs);

fig7 = figure;
for k = 1:numel(signals)
  [S, f, tt] = specgram(signals{k}(seg), nWin, fs, hannW, nWin * 3 / 4);
  keep = f <= maxFreq;
  sDb  = 20 * log10(abs(S(keep, :)) + 1e-9);

  subplot(numel(signals), 1, k);
  imagesc(tt + zoomStart, f(keep), sDb, max(sDb(:)) + [-70, 0]);
  set(gca, "ydir", "normal");
  xlabel("Time (s)"); ylabel("Frequency (Hz)"); title(titles{k});
endfor
colormap(jet);

print(fig7, "fig7_pitch_spectrograms.png", "-dpng", "-r150");
printf("wrote fig7_pitch_spectrograms.png\n");
