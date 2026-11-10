function Md = stg_multiday (D, cfg)
  % STG_MULTIDAY  Семиденні експерименти на матриці 1939 року.
  %
  % Змінні x_{ti} упорядковано за днями: x = [x_1; ...; x_7]. Добові рядки
  % утворюють блочно-діагональну матрицю kron(I_7, A). Верхні межі середнього
  % надходження не задаються.

  A = D.A; [m, n] = size (A); T = 7;
  bt = repmat (cfg.b, 1, T);
  bt(1, :) = cfg.md_energy; bt(2, :) = cfg.md_protein;
  Md.bt = bt;

  % --- сім окремих добових задач ------------------------------------------
  Cday = zeros (T, 1); Xday = zeros (n, T); Uday = zeros (m, T);
  for t = 1:T
    Rt = stg_base (D, cfg, bt(:, t), sprintf ('md:day%d', t));
    assert (Rt.ok, 'добова задача %d не пройшла перевірки', t);
    Cday(t) = Rt.C; Xday(:, t) = Rt.x; Uday(:, t) = Rt.u;
    Md.day{t} = Rt;
  end
  Md.Cday = Cday; Md.sum_days = sum (Cday);

  % --- спільна семиденна задача без середніх умов ------------------------
  AA = kron (speye (T), sparse (A)); BB = bt(:);
  ctd = repmat ('L', 1, m * T);
  [xj, Cj, ij] = stg_lp (ones (n * T, 1), AA, BB, ctd, 1, cfg, 'md:joint', 3);
  Xj = reshape (xj, n, T);
  Md.C = Cj; Md.Xjoint = Xj; Md.Cjoint_day = sum (Xj, 1)';
  Md.decomp_gap = Cj - sum (Cday);
  Md.max_day_cost_dev = max (abs (Md.Cjoint_day - Cday));
  Md.max_x_dev = max (abs (Xj(:) - Xday(:)));
  Md.joint_infeas = max ([0; BB - AA * xj; -xj]);

  % --- рядки середнього надходження --------------------------------------
  jI = 4; jP = 2; Dp = cfg.md_protein_days;
  w_iron = repmat (A(jI, :) / T, 1, T);                     % середнє за 7 днів
  w_prot = zeros (1, n * T);
  for t = Dp, w_prot((t-1)*n + (1:n)) = A(jP, :) / numel (Dp); end
  Md.mean_rhs_iron = mean (bt(jI, :));                      % середня добова межа
  Md.mean_rhs_protein = mean (bt(jP, Dp));

  cases = struct ('name', {'iron', 'protein'}, 'w', {w_iron, w_prot}, ...
                  'bounds', {cfg.md_iron_bounds, cfg.md_protein_bounds});
  budget = cfg.md_budget_base + cfg.md_budget_eps;
  for q = 1:2
    w = cases(q).w; nm = cases(q).name;
    S = struct ();
    S.mean_joint = w * xj;              % у розв'язку спільної задачі
    S.mean_days  = w * Xday(:);         % у сукупності добових оптимумів
    % межі середнього на точній оптимальній грані 1'x = C* (повне значення C*)
    Ae = [AA; ones(1, n * T)]; be = [BB; Cj]; cte = [ctd, 'S'];
    [xa, S.face_min] = stg_lp (w', Ae, be, cte, 1, cfg, ['md:', nm, ':face_min']);
    [xb, S.face_max] = stg_lp (w', Ae, be, cte, -1, cfg, ['md:', nm, ':face_max']);
    % допоміжна максимізація за бюджету з допуском до вартості
    Ab = [AA; ones(1, n * T)]; bb = [BB; budget]; ctb = [ctd, 'U'];
    [xe, S.eps_max, ie] = stg_lp (w', Ab, bb, ctb, -1, cfg, ['md:', nm, ':eps_max']);
    S.eps_budget = budget;
    S.eps_cost = sum (xe);
    S.eps_budget_dual = ie.lambda(end);   % приріст середнього на 1 дол. бюджету
    % три нижні межі середнього
    nb = numel (cases(q).bounds);
    S.bounds = cases(q).bounds(:); S.cost = zeros (nb, 1); S.mean_at_opt = zeros (nb, 1);
    S.mult = zeros (nb, 1);
    for k = 1:nb
      Ac = [AA; w]; bc = [BB; S.bounds(k)]; ctc = [ctd, 'L'];
      [xc, S.cost(k), ic] = stg_lp (ones (n * T, 1), Ac, bc, ctc, 1, cfg, ...
                                    sprintf ('md:%s:bound%d', nm, k));
      S.mean_at_opt(k) = w * xc;
      S.mult(k) = ic.lambda(end);         % множник середньої умови, дол. на одиницю
    end
    S.delta = S.cost - Cj;
    Md.(nm) = S;
  end
  Md.budget = budget;
end
