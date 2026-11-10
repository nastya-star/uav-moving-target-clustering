function Sn = stg_sensitivity (D, R, cfg)
  % STG_SENSITIVITY  Збільшення кожної вимоги окремо на 1% і всіх разом на 1%.
  % Для кожного випадку: нова мінімальна вартість, фактичний приріст,
  % прогноз 0.01*b_j*u_j та точна перевірка збереження базису (S, J).
  m = rows (D.A);
  Sn.cost = zeros (m, 1); Sn.delta = zeros (m, 1); Sn.pred = zeros (m, 1);
  Sn.basis_kept = false (m, 1);
  for j = 1:m
    bp = R.b; bp(j) = 1.01 * R.b(j);
    [xp, Cp] = stg_lp (ones (columns (D.A), 1), D.A, bp, repmat ('L', 1, m), 1, cfg, ...
                       sprintf ('%s:sens:%d', D.label, j));
    Sn.cost(j) = Cp;
    Sn.delta(j) = Cp - R.C;
    Sn.pred(j) = 0.01 * R.b(j) * R.u(j);
    % точна перевірка: 10*100*b' --- цілий вектор
    B = 100 * cfg.b10; B(j) = 101 * cfg.b10(j);
    E = stg_exact (D.A10, B, 100, R.support, R.Jplus);
    Sn.basis_kept(j) = E.optimal;
  end
  Sn.diff = Sn.delta - Sn.pred;
  % одночасне збільшення всіх вимог на 1%
  [xa, Ca] = stg_lp (ones (columns (D.A), 1), D.A, 1.01 * R.b, repmat ('L', 1, m), 1, cfg, ...
                     sprintf ('%s:sens:all', D.label));
  Sn.all_cost = Ca;
  Sn.all_delta = Ca - R.C;
  Sn.all_pred = 0.01 * R.C;            % V(1.01 b) - V(b) = 0.01 V(b)
  Sn.all_sum_single = sum (Sn.delta);  % сума дев'яти окремих приростів
  E = stg_exact (D.A10, 101 * cfg.b10, 100, R.support, R.Jplus);
  Sn.all_basis_kept = E.optimal;
end
