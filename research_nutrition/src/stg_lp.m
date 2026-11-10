function [x, f, info] = stg_lp (c, A, b, ctype, sense, cfg, tag, msglev)
  % STG_LP  Один запуск GLPK із перевіркою коду завершення та статусу.
  %
  %   min/max c'x,  A x (ctype) b,  x >= 0.
  % ctype: рядок із символів 'L' (>=), 'U' (<=), 'S' (=).
  % sense: 1 --- мінімізація, -1 --- максимізація.
  %
  % Запуск вважається успішним лише за errnum = 0 і status = 5 (GLP_OPT).
  % Кожний запуск додається до журналу STG_RUNS (файл lp_runs.csv).

  global STG_RUNS
  n = numel (c);
  p = cfg.glpk;
  if (nargin >= 8), p.msglev = msglev; end
  [x, f, errnum, extra] = glpk (c(:), A, b(:), zeros (n, 1), [], ctype, ...
                                repmat ('C', 1, n), sense, p);
  info.errnum = errnum;
  info.status = extra.status;
  info.lambda = extra.lambda;      % d f / d b для кожного рядка
  info.redcosts = extra.redcosts;  % c - A' * lambda
  info.time = extra.time;
  r.tag = tag; r.rows = rows (A); r.cols = n; r.sense = sense;
  r.errnum = errnum; r.status = extra.status; r.fval = f;
  if (isempty (STG_RUNS)), STG_RUNS = r; else, STG_RUNS(end+1) = r; end
  if (errnum != 0 || extra.status != 5)
    error ('stg_lp:%s: errnum = %d, status = %d', tag, errnum, extra.status);
  end
end
