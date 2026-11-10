function v = bi_ratio (a, b)
  % BI_RATIO  Наближене значення a/b типу double (лише для друку).
  % Старші розряди вирівнюються, щоб уникнути переповнення.
  if (a.s == 0), v = 0; return; end
  sh = max (numel (a.d), numel (b.d));
  fa = 0; for k = numel (a.d):-1:1, fa = fa + a.d(k) * 1e7 ^ (k - sh); end
  fb = 0; for k = numel (b.d):-1:1, fb = fb + b.d(k) * 1e7 ^ (k - sh); end
  v = a.s * b.s * fa / fb;
end
