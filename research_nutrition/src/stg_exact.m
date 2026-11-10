function E = stg_exact (A10, B, scale, S, J)
  % STG_EXACT  Точна (цілочислова) перевірка сертифіката оптимальності та
  % єдиності для базису (S, J).
  %
  % Дані: A10 = 10*A (цілі), B --- цілий вектор, B = 10*scale*b, де scale ---
  % натуральне число (1 для початкових вимог). Нехай M = A10(J,S),
  % Dt = det M, adj M --- приєднана матриця. Тоді
  %     x_S = adj(M) * B_J / (scale * Dt),      u_J = 10 * adj(M)' * 1 / Dt.
  % Чисельники X = adj(M)*B_J і U = 10*adj(M)'*1 --- цілі числа. Після
  % нормування знака (Dt > 0) перевіряються лише знаки цілих чисел:
  %   (1) Dt != 0;
  %   (2) X_i > 0, i in S;                      (x_S > 0)
  %   (3) U_j > 0, j in J;                      (u_J > 0)
  %   (4) T_j = A10(j,S)*X - B_j*Dt >= 0;       (A x >= b; = 0 для j in J)
  %   (5) Q_i = 10*Dt - A10(J,i)'*U >= 0;       (A'u <= 1; = 0 для i in S)
  %   (6) 10*sum(X) = sum(B_J .* U).            (1'x = b'u)
  % Строгі нерівності Q_i > 0 (i поза S) разом із (1) і (3) дають єдиність
  % прямого оптимуму; строгі X_i > 0 і T_j > 0 (j поза J) --- єдиність двоїстого.

  k = numel (S);
  assert (numel (J) == k);
  [m, n] = size (A10);
  M = A10(J, S);
  Dt = bi_det (M);
  E.det10 = Dt;                       % det(10*A_{J,S}) = 10^k * det A_{J,S}
  E.nonsingular = (Dt.s != 0);
  E.k = k;
  if (! E.nonsingular), E.unique = false; return; end

  % приєднана матриця: adj(p,q) = (-1)^(p+q) * мінор(q,p)
  adj = cell (k, k);
  for p = 1:k
    for q = 1:k
      c = bi_det (M([1:q-1, q+1:k], [1:p-1, p+1:k]));
      if (mod (p + q, 2) == 1), c = bi_neg (c); end
      if (Dt.s < 0), c = bi_neg (c); end   % нормування: далі Dt > 0
      adj{p, q} = c;
    end
  end
  Dp = Dt; Dp.s = 1;

  X = cell (k, 1); U = cell (k, 1);
  for p = 1:k
    X{p} = bi_dot (B(J), adj(p, :));
    U{p} = bi_mul (bi (10), bi_dot (ones (1, k), adj(:, p)'));
  end
  E.X = X; E.U = U; E.Dpos = Dp; E.scale = scale;

  E.x_pos = all (cellfun (@(v) v.s > 0, X));
  E.u_pos = all (cellfun (@(v) v.s > 0, U));

  % (4) запаси
  T = cell (m, 1); sgnT = zeros (m, 1);
  for j = 1:m
    T{j} = bi_sub (bi_dot (A10(j, S), X), bi_mul (bi (B(j)), Dp));
    sgnT(j) = T{j}.s;
  end
  E.T = T; E.slack_sign = sgnT;
  E.rows_feasible = all (sgnT >= 0) && all (sgnT(J) == 0);
  E.rows_strict = all (sgnT(setdiff (1:m, J)) > 0);

  % (5) зведені вартості
  Q = cell (n, 1); sgnQ = zeros (n, 1);
  tenD = bi_mul (bi (10), Dp);
  for i = 1:n
    Q{i} = bi_sub (tenD, bi_dot (A10(J, i)', U));
    sgnQ(i) = Q{i}.s;
  end
  E.Q = Q; E.redcost_sign = sgnQ; E.tenD = tenD;
  E.cols_feasible = all (sgnQ >= 0) && all (sgnQ(S) == 0);
  E.cols_strict = all (sgnQ(setdiff (1:n, S)) > 0);

  % (6) рівність значень прямої та двоїстої задач
  sumX = bi (0);
  for p = 1:k, sumX = bi_add (sumX, X{p}); end
  E.sumX = sumX;
  lhs = bi_mul (bi (10), sumX);
  rhs = bi_dot (B(J), U);
  E.gap_zero = (bi_sub (lhs, rhs).s == 0);

  E.optimal = E.x_pos && E.rows_feasible && E.u_pos && E.cols_feasible && E.gap_zero;
  E.unique  = E.optimal && E.cols_strict;                 % єдиність x*
  E.dual_unique = E.optimal && E.rows_strict;             % єдиність u*

  % наближені значення для друку
  E.x = cellfun (@(v) bi_ratio (v, Dp), X) / scale;
  E.u = cellfun (@(v) bi_ratio (v, Dp), U);
  E.C = bi_ratio (sumX, Dp) / scale;
  E.r = cellfun (@(v) bi_ratio (v, tenD), Q);
  E.s = cellfun (@(v) bi_ratio (v, Dp), T) / (10 * scale);
end
