function R = stg_base (D, cfg, b, tag, msglev)
  % STG_BASE  Пряма та двоїста задачі для матриці D.A і правої частини b.
  %
  %   (P)  min 1'x,  A x >= b,  x >= 0;
  %   (D)  max b'u,  A'u <= 1,  u >= 0.
  %
  % Обидві задачі розв'язуються окремо. Знаки множників GLPK узгоджуються
  % з (D) так: glpk повертає lambda_j = dC/db_j, тому для (P) із рядками
  % типу 'L' маємо u = lambda >= 0, а для (D) із рядками типу 'U' і
  % максимізацією множники рядків дорівнюють x >= 0. Зміна знака не потрібна;
  % це перевіряється порівнянням двох незалежних розв'язків.

  if (nargin < 3 || isempty (b)), b = cfg.b; end
  if (nargin < 4), tag = D.label; end
  if (nargin < 5), msglev = cfg.glpk.msglev; end
  A = D.A; [m, n] = size (A);

  [x, C, ip] = stg_lp (ones (n, 1), A, b, repmat ('L', 1, m), 1, cfg, ...
                       [tag, ':primal'], msglev);
  [ud, Cd, id] = stg_lp (b, A', ones (n, 1), repmat ('U', 1, n), -1, cfg, ...
                         [tag, ':dual'], msglev);

  R.label = D.label; R.b = b(:);
  R.x = x; R.C = C;
  R.u = ip.lambda;               % множники прямої задачі, u >= 0
  R.r_glpk = ip.redcosts;        % зведені вартості від GLPK
  R.u_dual = ud; R.C_dual = Cd;  % розв'язок окремої двоїстої задачі
  R.x_dual = id.lambda;          % її множники, мають дорівнювати x
  R.Ax = A * x;
  R.s = R.Ax - R.b;
  R.r = ones (n, 1) - A' * R.u;
  R.errnum = [ip.errnum, id.errnum]; R.status = [ip.status, id.status];

  % --- перевірки -----------------------------------------------------------
  k.primal_infeas = max ([0; -R.s; -x]);            % порушення Ax>=b, x>=0
  k.dual_infeas   = max ([0; -R.r; -R.u]);          % порушення A'u<=1, u>=0
  k.gap           = abs (C - R.b' * R.u);           % |1'x - b'u|
  k.gap_two_lps   = abs (C - Cd);                   % |C_P - C_D|
  k.comp_rows     = max (abs (R.u .* R.s));         % max |u_j s_j|
  k.comp_cols     = max (abs (x .* R.r));           % max |x_i r_i|
  k.u_vs_dual_lp  = max (abs (R.u - ud));           % узгодження знаків і значень u
  k.x_vs_dual_lp  = max (abs (x - id.lambda));      % множники (D) проти x
  k.r_vs_glpk     = max (abs (R.r - ip.redcosts));  % 1 - A'u проти redcosts
  k.dual_lp_infeas = max ([0; A' * ud - 1; -ud]);
  R.checks = k;
  R.ok = k.primal_infeas <= cfg.tol_feas && k.dual_infeas <= cfg.tol_feas ...
         && k.gap <= cfg.tol_gap && k.gap_two_lps <= cfg.tol_gap ...
         && k.comp_rows <= cfg.tol_comp && k.comp_cols <= cfg.tol_comp ...
         && k.u_vs_dual_lp <= cfg.tol_feas && k.x_vs_dual_lp <= cfg.tol_feas ...
         && k.dual_lp_infeas <= cfg.tol_feas;

  R.support = find (x > cfg.tol_support)';
  R.active  = find (abs (R.s) <= cfg.tol_active * max (1, abs (R.b)))';
  R.Jplus   = find (R.u > cfg.tol_support)';
end
