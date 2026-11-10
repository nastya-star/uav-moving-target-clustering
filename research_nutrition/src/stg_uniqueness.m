function Uq = stg_uniqueness (D, R, cfg)
  % STG_UNIQUENESS  Межі кожної координати на множині
  %   { x : A x >= b, x >= 0, 1'x = C* },
  % де C* --- повне обчислене значення (без округлення). 2n задач ЛП.
  A = D.A; [m, n] = size (A);
  Ae = [A; ones(1, n)];
  be = [R.b; R.C];
  ct = [repmat('L', 1, m), 'S'];
  lo = zeros (n, 1); hi = zeros (n, 1); st = zeros (n, 4);
  for i = 1:n
    c = zeros (n, 1); c(i) = 1;
    [xa, fa, ia] = stg_lp (c, Ae, be, ct, 1, cfg, sprintf ('%s:uniq:min:%d', D.label, i));
    [xb, fb, ib] = stg_lp (c, Ae, be, ct, -1, cfg, sprintf ('%s:uniq:max:%d', D.label, i));
    lo(i) = fa; hi(i) = fb;
    st(i, :) = [ia.errnum, ia.status, ib.errnum, ib.status];
  end
  Uq.lo = lo; Uq.hi = hi; Uq.span = hi - lo; Uq.st = st;
  Uq.max_span = max (abs (Uq.span));
  Uq.max_dev_from_x = max (max (abs (lo - R.x)), max (abs (hi - R.x)));
  Uq.n_lp = 2 * n;
  Uq.all_optimal = all (st(:, 1) == 0 & st(:, 3) == 0 & st(:, 2) == 5 & st(:, 4) == 5);
end
