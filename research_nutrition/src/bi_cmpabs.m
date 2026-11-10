function c = bi_cmpabs (a, b)
  % BI_CMPABS  Порівняння модулів: -1, 0 або 1.
  na = numel (a.d); nb = numel (b.d);
  if (na != nb), c = sign (na - nb); return; end
  k = find (a.d != b.d, 1, 'last');
  if (isempty (k)), c = 0; else, c = sign (a.d(k) - b.d(k)); end
end
