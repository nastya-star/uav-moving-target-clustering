function r = bi_norm (s, d)
  % BI_NORM  Перенесення розрядів і нормалізація (розряди можуть бути
  % будь-якими цілими, зокрема від'ємними, але |d_k| < 2^52).
  carry = 0;
  for k = 1:numel (d)
    t = d(k) + carry;
    carry = floor (t / 1e7);
    d(k) = t - carry * 1e7;
  end
  while (carry > 0)
    d(end+1) = mod (carry, 1e7); carry = floor (carry / 1e7);
  end
  assert (carry == 0, 'bi_norm: від''ємне перенесення');
  k = find (d != 0, 1, 'last');
  if (isempty (k))
    r.s = 0; r.d = 0;
  else
    r.s = s; r.d = d(1:k);
  end
end
