function Mx = stg_multiday_exact (D, Md, cfg)
  % STG_MULTIDAY_EXACT  Точна перевірка тверджень про середні межі.
  %
  % Для кожного з семи днів перевіряється сертифікат єдиності добового
  % оптимуму (stg_exact). Середнє надходження в єдиній сукупності добових
  % оптимумів є раціональним числом; його порівняння з межею B_j виконується
  % в цілих числах після зведення до спільного знаменника. За твердженням 1 роботи: C* = sum C_t тоді й лише тоді, коли ця
  % сукупність задовольняє середню умову.

  T = 7; A10 = D.A10;
  Mx.day_unique = false (T, 1);
  X = cell (T, 1); Dt = cell (T, 1); Sd = cell (T, 1);
  for t = 1:T
    Bt = round (10 * Md.bt(:, t));
    assert (max (abs (10 * Md.bt(:, t) - Bt)) < 1e-9);
    E = stg_exact (A10, Bt, 1, Md.day{t}.support, Md.day{t}.Jplus);
    Mx.day_unique(t) = E.unique;
    X{t} = E.X; Dt{t} = E.Dpos; Sd{t} = Md.day{t}.support;
  end
  Mx.all_days_unique = all (Mx.day_unique);
  Mx.same_basis = all (cellfun (@(s) isequal (s, Sd{1}), Sd));

  % спільний знаменник: P = prod_t Dt{t}; cof{t} = P / Dt{t}
  P = bi (1); cof = cell (T, 1);
  for t = 1:T
    P = bi_mul (P, Dt{t});
    c = bi (1);
    for s = [1:t-1, t+1:T], c = bi_mul (c, Dt{s}); end
    cof{t} = c;
  end

  specs = struct ('name', {'iron', 'protein'}, 'row', {4, 2}, ...
                  'days', {1:T, cfg.md_protein_days}, ...
                  'bounds', {cfg.md_iron_bounds, cfg.md_protein_bounds});
  for q = 1:2
    sp = specs(q);
    % середнє = (1/|D_j|) * sum_t A10(row,S_t) X_t / (10 Dt_t) = N / den
    N = bi (0);
    for t = sp.days
      N = bi_add (N, bi_mul (bi_dot (A10(sp.row, Sd{t}), X{t}), cof{t}));
    end
    den = bi_mul (bi (10 * numel (sp.days)), P);
    r.mean = bi_ratio (N, den);
    nb = numel (sp.bounds); r.cmp = zeros (nb, 1);
    for k = 1:nb
      Bint = round (sp.bounds(k) * 1e5);
      assert (abs (sp.bounds(k) * 1e5 - Bint) < 1e-6);
      % sign( mean - B ) = sign( N*10^5 - Bint*den )
      r.cmp(k) = bi_sub (bi_mul (N, bi (1e5)), bi_mul (bi (Bint), den)).s;
    end
    Mx.(sp.name) = r;
  end
end
