function r = bi_mul (a, b)
  % BI_MUL  Точний добуток. Згортка розрядів: кожний доданок < 10^14,
  % кількість доданків у стовпці не перевищує min(numel) <= 64, тому
  % проміжні суми менші за 2^53.
  if (a.s == 0 || b.s == 0), r.s = 0; r.d = 0; return; end
  assert (min (numel (a.d), numel (b.d)) <= 64, 'bi_mul: завеликі операнди');
  r = bi_norm (a.s * b.s, conv (a.d, b.d));
end
