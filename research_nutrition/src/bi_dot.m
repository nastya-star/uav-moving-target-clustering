function r = bi_dot (v, c)
  % BI_DOT  Сума v(k) * c{k}: v --- цілі типу double, c --- комірки довгих цілих.
  r = bi (0);
  for k = 1:numel (v)
    if (v(k) != 0)
      r = bi_add (r, bi_mul (bi (v(k)), c{k}));
    end
  end
end
