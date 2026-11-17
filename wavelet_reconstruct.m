function x = wavelet_reconstruct(c, info)
  % WAVELET_RECONSTRUCT  Inverse of wavelet_decompose.
  %
  %   x = wavelet_reconstruct(c, info)
  %
  % Not needed for Method A (broadband gain never touches the coefficients),
  % but kept alongside wavelet_decompose so the pair can be round-trip tested,
  % and so Method B (coefficient-domain gain) can reuse it directly.

  raw = [c.approx, fliplr(c.detail)];   % undo the column reversal
  x   = iufwt(raw, info.wavelet, info.J);
endfunction
