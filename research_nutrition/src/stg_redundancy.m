function Rd = stg_redundancy (D, R, cfg)
  % STG_REDUNDANCY  Неактивні рядки: мінімальне надходження m_j за решти
  % обмежень і вплив вилучення рядків із нульовими множниками на вартість.
  A = D.A; [m, n] = size (A);
  inact = setdiff (1:m, R.active);
  zero_u = find (R.u <= cfg.tol_support)';
  Rd.inactive = inact; Rd.zero_u = zero_u;
  Rd.m = nan (m, 1); Rd.cost_without = nan (m, 1);
  for j = inact
    keep = setdiff (1:m, j);
    [xx, mj] = stg_lp (A(j, :)', A(keep, :), R.b(keep), repmat ('L', 1, m - 1), 1, cfg, ...
                       sprintf ('%s:redund:min_row:%d', D.label, j));
    Rd.m(j) = mj;
  end
  for j = zero_u
    keep = setdiff (1:m, j);
    [xx, Cj] = stg_lp (ones (n, 1), A(keep, :), R.b(keep), repmat ('L', 1, m - 1), 1, cfg, ...
                       sprintf ('%s:redund:drop_row:%d', D.label, j));
    Rd.cost_without(j) = Cj;
  end
  keep = setdiff (1:m, zero_u);
  [xx, Call] = stg_lp (ones (n, 1), A(keep, :), R.b(keep), repmat ('L', 1, numel (keep)), 1, ...
                       cfg, sprintf ('%s:redund:drop_all_zero_u', D.label));
  Rd.cost_without_all = Call;
  Rd.x_without_all_dev = max (abs (xx - R.x));
end
