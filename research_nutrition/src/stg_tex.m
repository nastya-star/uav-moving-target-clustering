function stg_tex (cfg, Y, Dc, Md, Mx, H)
  % STG_TEX  Готові LaTeX-таблиці (booktabs, десяткова кома).
  o = cfg.texdir; nu = cfg.nutrient_uk;

  for y = 1:2
    D = Y(y).D; R = Y(y).R; Q = Y(y).Q; L = D.label; S = R.support;

    % --- оптимальний вектор витрат -------------------------------------------
    fid = topen (o, ['tab_solution_', L, '.tex']);
    fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Оптимальний вектор витрат, ', ...
                   '%s рік (GLPK); решта компонент дорівнюють нулю}\n\\label{tab:glpk-solution-%s}\n'], L, L);
    fprintf (fid, '\\begin{tabular}{lrrr}\n\\toprule\n');
    fprintf (fid, 'Продукт & $x_i^*$, дол./день & Дол. за 365 днів & Дол. за $365{,}25$ дня \\\\\n\\midrule\n');
    for i = S
      fprintf (fid, '%s & %s & %s & %s \\\\\n', stg_name_uk (D, i), tx (R.x(i), 12), ...
               tx (Q.cost_365(i), 6), tx (Q.cost_36525(i), 6));
    end
    fprintf (fid, '\\midrule\nРазом & %s & %s & %s \\\\\n', tx (R.C, 12), tx (365 * R.C, 6), ...
             tx (365.25 * R.C, 6));
    tclose (fid);

    % --- фізичні кількості ----------------------------------------------------
    fid = topen (o, ['tab_units_', L, '.tex']);
    fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\footnotesize\\setlength{\\tabcolsep}{3pt}\n', ...
                   '\\caption{Фізичні кількості продуктів, %s рік: $z_i=100x_i^*/p_i$ торгових одиниць ', ...
                   'на день}\n\\label{tab:glpk-units-%s}\n'], L, L);
    fprintf (fid, '\\begin{tabular}{llrrrrrr}\n\\toprule\n');
    fprintf (fid, [' & Торгова & $p_i$, & $z_i$, & \\multicolumn{2}{c}{Торгових одиниць за} & ', ...
                   '\\multicolumn{2}{c}{Фунтів за} \\\\\n\\cmidrule(lr){5-6}\\cmidrule(lr){7-8}\n', ...
                   'Продукт & одиниця & центів & од./день & 365 днів & $365{,}25$ дня & 365 днів & ', ...
                   '$365{,}25$ дня \\\\\n\\midrule\n']);
    for i = S
      fprintf (fid, '%s & %s & %s & %s & %s & %s & %s & %s \\\\\n', stg_name_uk (D, i), ...
               unit_uk (D.unit{i}), tx (D.price(i), 1), tx (Q.z_day(i), 9), tx (Q.z_365(i), 6), ...
               tx (Q.z_36525(i), 6), tx (Q.lb_365(i), 6), tx (Q.lb_36525(i), 6));
    end
    tclose (fid);

    % --- надходження, запаси, множники ----------------------------------------
    fid = topen (o, ['tab_dual_', L, '.tex']);
    fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Надходження, запаси і двоїсті ', ...
                   'змінні, %s рік (GLPK)}\n\\label{tab:glpk-dual-%s}\n'], L, L);
    fprintf (fid, '\\begin{tabular}{lrrrr}\n\\toprule\nПоказник & $b_j$ & $(Ax^*)_j$ & $s_j$ & $u_j^*$ \\\\\n\\midrule\n');
    for j = 1:9
      fprintf (fid, '%s & %s & %s & %s & %s \\\\\n', nu{j}, tx (R.b(j), 1), tx (R.Ax(j), 6), ...
               tx (R.s(j), 6), tx (R.u(j), 9));
    end
    tclose (fid);
  end

  % --- перевірки оптимальності ----------------------------------------------------
  c1 = Y(1).R.checks; c2 = Y(2).R.checks;
  fid = topen (o, 'tab_checks.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Перевірка допустимості, двоїстого ', ...
                 'розриву та доповняльної нежорсткості}\n\\label{tab:glpk-checks}\n']);
  fprintf (fid, '\\begin{tabular}{lrrr}\n\\toprule\nВеличина & 1939 & 1944 & Допуск \\\\\n\\midrule\n');
  fprintf (fid, 'Код завершення, статус (пряма задача) & %d; %d & %d; %d & 0; 5 \\\\\n', ...
           Y(1).R.errnum(1), Y(1).R.status(1), Y(2).R.errnum(1), Y(2).R.status(1));
  fprintf (fid, 'Код завершення, статус (двоїста задача) & %d; %d & %d; %d & 0; 5 \\\\\n', ...
           Y(1).R.errnum(2), Y(1).R.status(2), Y(2).R.errnum(2), Y(2).R.status(2));
  line3 (fid, 'Порушення $Ax^*\ge b$, $x^*\ge0$', c1.primal_infeas, c2.primal_infeas, cfg.tol_feas);
  line3 (fid, 'Порушення $A^\top u^*\le\mathbf1$, $u^*\ge0$', c1.dual_infeas, c2.dual_infeas, cfg.tol_feas);
  line3 (fid, '$|\mathbf1^\top x^*-b^\top u^*|$', c1.gap, c2.gap, cfg.tol_gap);
  line3 (fid, 'Різниця значень прямої та двоїстої задач', c1.gap_two_lps, c2.gap_two_lps, cfg.tol_gap);
  line3 (fid, '$\max_j|u_j^*s_j|$', c1.comp_rows, c2.comp_rows, cfg.tol_comp);
  line3 (fid, '$\max_i|x_i^*r_i|$', c1.comp_cols, c2.comp_cols, cfg.tol_comp);
  line3 (fid, '$\max_j|u_j^*-u_j^{\mathrm{D}}|$', c1.u_vs_dual_lp, c2.u_vs_dual_lp, cfg.tol_feas);
  line3 (fid, '$\max_i|x_i^*-\lambda_i^{\mathrm{D}}|$', c1.x_vs_dual_lp, c2.x_vs_dual_lp, cfg.tol_feas);
  tclose (fid);

  % --- єдиність -----------------------------------------------------------------------
  fid = topen (o, 'tab_uniqueness.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Перевірка єдиності оптимального ', ...
                 'вектора}\n\\label{tab:glpk-uniqueness}\n']);
  fprintf (fid, '\\begin{tabular}{lrr}\n\\toprule\nВеличина & 1939 & 1944 \\\\\n\\midrule\n');
  fprintf (fid, 'Кількість допоміжних задач & %d & %d \\\\\n', Y(1).Uq.n_lp, Y(2).Uq.n_lp);
  fprintf (fid, 'Задач із кодом 0 і статусом 5 & %d & %d \\\\\n', ...
           sum (sum (Y(1).Uq.st(:, [2, 4]) == 5 & Y(1).Uq.st(:, [1, 3]) == 0)), ...
           sum (sum (Y(2).Uq.st(:, [2, 4]) == 5 & Y(2).Uq.st(:, [1, 3]) == 0)));
  fprintf (fid, '$\\max_i(\\overline x_i-\\underline x_i)$, дол./день & $%s$ & $%s$ \\\\\n', ...
           sci (Y(1).Uq.max_span), sci (Y(2).Uq.max_span));
  fprintf (fid, 'Найбільше відхилення меж від $x_i^*$, дол./день & $%s$ & $%s$ \\\\\n', ...
           sci (Y(1).Uq.max_dev_from_x), sci (Y(2).Uq.max_dev_from_x));
  fprintf (fid, '$|S|=|J_+|$ & %d & %d \\\\\n', numel (Y(1).R.support), numel (Y(2).R.support));
  fprintf (fid, '$\\det(10A_{J_+,S})$ & $%s$ & $%s$ \\\\\n', bi_str (Y(1).E.det10), bi_str (Y(2).E.det10));
  mr = @(k) min (Y(k).E.r(setdiff (1:columns (Y(k).D.A), Y(k).R.support)));
  fprintf (fid, '$\\min_{i\\notin S}r_i$ & %s & %s \\\\\n', tx (mr (1), 10), tx (mr (2), 10));
  ms = @(k) min (Y(k).E.s(setdiff (1:9, Y(k).R.Jplus)));
  fprintf (fid, '$\\min_{j\\notin J_+}s_j$ & %s & %s \\\\\n', tx (ms (1), 6), tx (ms (2), 6));
  yn = {'ні', 'так'};
  fprintf (fid, 'Точна перевірка умов сертифіката & %s & %s \\\\\n', yn{1 + Y(1).E.unique}, yn{1 + Y(2).E.unique});
  tclose (fid);

  % --- чутливість -----------------------------------------------------------------------
  fid = topen (o, 'tab_sensitivity.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\footnotesize\n\\caption{Приріст мінімальної добової вартості ', ...
                 'при збільшенні вимог на $1\\%%$ і прогноз $0{,}01\\,b_ju_j^*$, дол.}\n\\label{tab:glpk-sensitivity}\n']);
  fprintf (fid, '\\begin{tabular}{lrrrr}\n\\toprule\n');
  fprintf (fid, ' & \\multicolumn{2}{c}{1939} & \\multicolumn{2}{c}{1944} \\\\\n\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n');
  fprintf (fid, 'Змінена вимога & $\\Delta C^*$ & $0{,}01\\,b_ju_j^*$ & $\\Delta C^*$ & $0{,}01\\,b_ju_j^*$ \\\\\n\\midrule\n');
  for j = 1:9
    fprintf (fid, '%s & %s & %s & %s & %s \\\\\n', nu{j}, tx (Y(1).Sn.delta(j), 12), ...
             tx (Y(1).Sn.pred(j), 12), tx (Y(2).Sn.delta(j), 12), tx (Y(2).Sn.pred(j), 12));
  end
  fprintf (fid, '\\midrule\nУсі дев’ять вимог & %s & %s & %s & %s \\\\\n', tx (Y(1).Sn.all_delta, 12), ...
           tx (Y(1).Sn.all_pred, 12), tx (Y(2).Sn.all_delta, 12), tx (Y(2).Sn.all_pred, 12));
  tclose (fid);

  % --- надлишковість ----------------------------------------------------------------------
  fid = topen (o, 'tab_redundancy.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Мінімальне надходження $m_j$ за решти ', ...
                 'обмежень для неактивних рядків}\n\\label{tab:glpk-redundancy}\n']);
  fprintf (fid, '\\begin{tabular}{lrrr}\n\\toprule\nПоказник & $b_j$ & $m_j$, 1939 & $m_j$, 1944 \\\\\n\\midrule\n');
  for j = union (Y(1).Rd.inactive, Y(2).Rd.inactive)
    fprintf (fid, '%s & %s & %s & %s \\\\\n', nu{j}, tx (cfg.b(j), 1), nanx (Y(1).Rd.m(j), 6), ...
             nanx (Y(2).Rd.m(j), 6));
  end
  tclose (fid);

  % --- семиденна задача --------------------------------------------------------------------
  fid = topen (o, 'tab_multiday_days.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Одноденні мінімуми та добові витрати ', ...
                 'у спільній семиденній задачі}\n\\label{tab:glpk-multiday-days}\n']);
  fprintf (fid, ['\\begin{tabular}{crrrr}\n\\toprule\nДень & Енергія, тис. ккал & Білок, г & $C_t^*$, дол. & ', ...
                 'У семиденній задачі, дол. \\\\\n\\midrule\n']);
  for t = 1:7
    fprintf (fid, '%d & %s & %s & %s & %s \\\\\n', t, tx (Md.bt(1, t), 1), tx (Md.bt(2, t), 1), ...
             tx (Md.Cday(t), 12), tx (Md.Cjoint_day(t), 12));
  end
  fprintf (fid, '\\midrule\nРазом & & & %s & %s \\\\\n', tx (Md.sum_days, 12), tx (Md.C, 12));
  tclose (fid);

  specs = {'iron', 'заліза за сім днів', 'мг', 'tab_multiday_iron.tex', 'glpk-multiday-iron'; ...
           'protein', 'білка на множині $D_j=\{2,3,5,6,7\}$', 'г', 'tab_multiday_protein.tex', 'glpk-multiday-protein'};
  for q = 1:2
    S = Md.(specs{q, 1});
    fid = topen (o, specs{q, 4});
    fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Вплив нижньої межі середнього ', ...
                   'надходження %s}\n\\label{tab:%s}\n'], specs{q, 2}, specs{q, 5});
    fprintf (fid, ['\\begin{tabular}{rrrr}\n\\toprule\n$B_j$, %s & $C^*$, дол. & $\\Delta C^*$, дол. & ', ...
                   'Середнє в оптимумі, %s \\\\\n\\midrule\n'], specs{q, 3}, specs{q, 3});
    for k = 1:numel (S.bounds)
      fprintf (fid, '%s & %s & %s & %s \\\\\n', tx (S.bounds(k), 5), tx (S.cost(k), 12), ...
               tx (S.delta(k), 12), tx (S.mean_at_opt(k), 8));
    end
    tclose (fid);
  end

  % --- історичний раціон 1944 року ---------------------------------------------------------
  h = H.y1944; D = Y(2).D; Q = Y(2).Q; R = Y(2).R;
  fid = topen (o, 'tab_historic_1944.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Історичний раціон 1944 року і розв’язок ', ...
                 'ЛП для опублікованої матриці (365 днів)}\n\\label{tab:glpk-historic-1944}\n']);
  fprintf (fid, ['\\begin{tabular}{lrrrr}\n\\toprule\n & \\multicolumn{2}{c}{Кількість, фунтів} & ', ...
                 '\\multicolumn{2}{c}{Вартість, дол.} \\\\\n\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n', ...
                 'Продукт & Стіглер & ЛП & Стіглер & ЛП \\\\\n\\midrule\n']);
  for k = 1:numel (h.idx)
    i = h.idx(k);
    fprintf (fid, '%s & %s & %s & %s & %s \\\\\n', stg_name_uk (D, i), tx (h.qty(k), 0), ...
             tx (Q.lb_365(i), 2), tx (h.cost(k), 2), tx (Q.cost_365(i), 4));
  end
  fprintf (fid, '\\midrule\nРазом & & & %s & %s \\\\\n', tx (h.total, 2), tx (365 * R.C, 4));
  tclose (fid);

  fid = topen (o, 'tab_historic_1944_nutrients.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Добове надходження історичного раціону ', ...
                 '1944 року за опублікованою матрицею (річні вартості поділено на 365)}\n', ...
                 '\\label{tab:glpk-historic-1944-nutrients}\n']);
  fprintf (fid, '\\begin{tabular}{lrrr}\n\\toprule\nПоказник & $b_j$ & Надходження & Частка від $b_j$, \\%% \\\\\n\\midrule\n');
  for j = 1:9
    fprintf (fid, '%s & %s & %s & %s \\\\\n', nu{j}, tx (R.b(j), 1), tx (h.intake_cost(j, 1), 4), ...
             tx (100 * h.ratio_cost(j, 1), 2));
  end
  tclose (fid);

  % --- перехресна перевірка таблиці B ------------------------------------------------------
  D44 = Y(2).D;
  fid = topen (o, 'tab_datacheck_1944.tex');
  fprintf (fid, ['\\begin{table}[htbp]\n\\centering\\small\n\\caption{Узгодженість таблиці B з таблицею A: ', ...
                 'найбільше відхилення $a^{1944}_{ji}-a^{1939}_{ji}p^{1939}_i/p^{1944}_i$ в одиницях ', ...
                 'останнього друкованого знака}\n\\label{tab:glpk-datacheck-1944}\n']);
  fprintf (fid, ['\\begin{tabular}{rlrrr}\n\\toprule\n№ & Продукт & $p_i^{1939}$, центів & $p_i^{1944}$, центів & ', ...
                 'Найбільше відхилення \\\\\n\\midrule\n']);
  for i = 1:numel (D44.id)
    if (D44.id(i) <= 77)
      fprintf (fid, '%d & %s & %s & %s & %s \\\\\n', D44.id(i), D44.name{i}, ...
               tx (Y(1).D.price(D44.id(i)), 1), tx (D44.price(i), 1), ...
               tx (max (abs (Dc.dev_units(:, i))), 2));
    else
      fprintf (fid, '%d & %s & --- & %s & --- \\\\\n', D44.id(i), D44.name{i}, tx (D44.price(i), 1));
    end
  end
  tclose (fid);
end

function fid = topen (o, name)
  fid = fopen (fullfile (o, name), 'w');
  assert (fid > 0);
  fprintf (fid, '%% Згенеровано run_all.m (GNU Octave, GLPK). Потребує пакета booktabs.\n');
end

function tclose (fid)
  fprintf (fid, '\\bottomrule\n\\end{tabular}\n\\end{table}\n');
  fclose (fid);
end

function line3 (fid, name, a, b, tol)
  fprintf (fid, '%s & $%s$ & $%s$ & $%s$ \\\\\n', name, sci (a), sci (b), sci (tol));
end

function s = sci (v)
  if (v == 0), s = '0'; return; end
  e = floor (log10 (abs (v)));
  m = v / 10 ^ e;
  if (abs (m) >= 9.995), m = m / 10; e++; end
  s = sprintf ('%s\\cdot10^{%d}', strrep (sprintf ('%.2f', m), '.', '{,}'), e);
end

function s = nanx (v, nd)
  if (isnan (v)), s = '---'; else, s = tx (v, nd); end
end

function s = unit_uk (u)
  t = regexp (u, '^([0-9.]+)\s*(lb|oz)\.?$', 'tokens', 'once');
  if (isempty (t)), s = u; return; end
  v = str2double (t{1});
  if (strcmp (t{2}, 'lb'))
    if (v == 1), w = 'фунт'; else, w = 'фунтів'; end
  else
    w = 'унцій';
  end
  s = sprintf ('%s %s', strrep (t{1}, '.', '{,}'), w);
end
