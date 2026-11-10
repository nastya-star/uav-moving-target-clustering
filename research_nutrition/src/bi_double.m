function v = bi_double (a)
  % BI_DOUBLE  Наближене значення типу double (лише для друку).
  v = 0;
  for k = numel (a.d):-1:1
    v = v * 1e7 + a.d(k);
  end
  v = a.s * v;
end
