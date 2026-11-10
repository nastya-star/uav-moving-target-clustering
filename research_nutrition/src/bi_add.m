function r = bi_add (a, b)
  % BI_ADD  Точна сума двох довгих цілих.
  if (a.s == 0), r = b; return; end
  if (b.s == 0), r = a; return; end
  n = max (numel (a.d), numel (b.d));
  da = [a.d, zeros(1, n - numel (a.d))];
  db = [b.d, zeros(1, n - numel (b.d))];
  if (a.s == b.s)
    r = bi_norm (a.s, da + db);
  else
    c = bi_cmpabs (a, b);
    if (c == 0)
      r.s = 0; r.d = 0;
    elseif (c > 0)
      r = bi_norm (a.s, da - db);
    else
      r = bi_norm (b.s, db - da);
    end
  end
end
