% RUN_ALL  Повна обчислювальна перевірка задачі Стіглера в GNU Octave через GLPK.
%
% Запуск (із каталогу research_nutrition):
%
%   octave-cli --no-gui --quiet run_all.m 2>&1 | tee results/logs/console_full.log
%
% Повідомлення бібліотеки GLPK надходять безпосередньо до стандартного виводу,
% тому повний журнал зберігається через tee. Стислий журнал результатів
% записується до results/logs/run_summary.log незалежно від способу запуску.

1;  % файл є скриптом

here = fileparts (mfilename ('fullpath'));
addpath (fullfile (here, 'src'));
more off;
global STG_RUNS
STG_RUNS = [];

cfg = stg_config ();
for d = {cfg.outdir, cfg.csvdir, cfg.texdir, cfg.logdir}
  if (! exist (d{1}, 'dir')), mkdir (d{1}); end
end
logf = fullfile (cfg.logdir, 'run_summary.log');
if (exist (logf, 'file')), delete (logf); end
diary (logf);

% --- 1. Середовище і дані ---------------------------------------------------
env = stg_environment (cfg);
printf ('== Середовище ==\n');
printf ('GNU Octave %s (%s), %s\n', env.octave, env.host, env.os);
printf ('GLPK: бібліотека %s, версія пакета libglpk40 %s\n', env.glpk_lib, env.glpk_version);
printf ('oct-файл: %s\n', env.glpk_oct);
printf ('glpsol: %s\n', env.glpsol);
printf ('Параметри glpk: %s\n', disp (cfg.glpk));

D39 = stg_load1939 (cfg);
D44 = stg_load1944 (cfg);
Dc = stg_datacheck (D39, D44, cfg);
printf ('== Дані ==\n');
printf ('1939: %d продуктів, %d показників; джерело: %s\n', columns (D39.A), rows (D39.A), D39.source);
printf ('1944: %d продуктів, %d показників; джерело: %s\n', columns (D44.A), rows (D44.A), D44.source);
bad = find (! isnan (Dc.edible) & Dc.edible > Dc.edible_cap)';
printf ('1939: частка їстівної маси в межах (0, 1] з урахуванням округлення: %d із %d вагових одиниць\n', ...
        sum (! isnan (Dc.edible)) - numel (bad), sum (! isnan (Dc.edible)));
for i = bad
  printf ('  увага: %s (%s, %.1f цента): %g г на 1 дол. проти %.1f г у торговій одиниці на 1 дол.\n', ...
          D39.key{i}, D39.unit{i}, D39.price(i), D39.weight(i), ...
          D39.lb_per_unit(i) * cfg.lb_gram / (D39.price(i) / 100));
end
printf ('1944: перехресна перевірка %d рядків таблиці B за таблицею A: найбільше відхилення %.2f од. друку\n', ...
        Dc.n_cross, Dc.max_dev_units);
[jj, ii] = find (abs (Dc.dev_units) > 1);
for k = 1:numel (jj)
  printf ('  увага: № %d (%s), %s: у таблиці B %g, за таблицею A %.2f\n', D44.id(ii(k)), ...
          D44.name{ii(k)}, cfg.nutrient_keys{jj(k)}, D44.A(jj(k), ii(k)), Dc.pred(jj(k), ii(k)));
end

for k = 1:rows (Dc.footnote)
  printf ('1944: № %d: їстівна маса на 1 дол. у примітці %d г; за ціною й торговою одиницею %.1f г\n', ...
          Dc.footnote(k, 1), Dc.footnote(k, 2), Dc.footnote(k, 3));
end

% --- 2-5. Базові задачі, єдиність, чутливість, надлишковість ------------------
DD = {D39, D44};
for y = 1:2
  D = DD{y};
  printf ('== %s: пряма і двоїста задачі ==\n', D.label);
  R = stg_base (D, cfg, [], D.label, 3);
  assert (R.ok, '%s: базові перевірки не пройдено', D.label);
  E = stg_exact (D.A10, cfg.b10, 1, R.support, R.Jplus);
  Uq = stg_uniqueness (D, R, cfg);
  Sn = stg_sensitivity (D, R, cfg);
  Rd = stg_redundancy (D, R, cfg);
  Q = stg_units (D, R.x, cfg);
  Y(y) = struct ('D', D, 'R', R, 'E', E, 'Uq', Uq, 'Sn', Sn, 'Rd', Rd, 'Q', Q);

  printf ('C* = %.17g дол./день; 365 C* = %.12f; 365.25 C* = %.12f\n', R.C, 365 * R.C, 365.25 * R.C);
  printf ('errnum/status: пряма %d/%d, двоїста %d/%d\n', R.errnum(1), R.status(1), R.errnum(2), R.status(2));
  printf ('порушення прямої допустимості %.3g; двоїстої %.3g; розрив %.3g; max|u s| %.3g; max|x r| %.3g\n', ...
          R.checks.primal_infeas, R.checks.dual_infeas, R.checks.gap, R.checks.comp_rows, R.checks.comp_cols);
  printf ('max|u - u(двоїста ЛП)| = %.3g; max|x - множники двоїстої ЛП| = %.3g\n', ...
          R.checks.u_vs_dual_lp, R.checks.x_vs_dual_lp);
  printf ('носій S: %s\n', strjoin (D.name(R.support), '; '));
  printf ('активні рядки: %s;  J+: %s\n', mat2str (R.active), mat2str (R.Jplus));
  for i = R.support
    printf ('  %-24s x = %.15f  z/день = %.12f  од./365 = %.6f  од./365.25 = %.6f  фунтів/365.25 = %.6f\n', ...
            D.name{i}, R.x(i), Q.z_day(i), Q.z_365(i), Q.z_36525(i), Q.lb_36525(i));
  end
  for j = 1:9
    printf ('  %-13s b = %-5g Ax = %.10f  s = %.10f  u = %.12f\n', cfg.nutrient_keys{j}, R.b(j), ...
            R.Ax(j), R.s(j), R.u(j));
  end
  printf ('точна перевірка: det(10 A_{J+,S}) = %s; оптимальність %d; єдиність x* %d; єдиність u* %d\n', ...
          bi_str (E.det10), E.optimal, E.unique, E.dual_unique);
  printf ('точне C* = %s/%s = %.17g\n', bi_str (E.sumX), bi_str (E.Dpos), E.C);
  printf ('найменша зведена вартість поза S: %.12f\n', min (E.r(setdiff (1:columns (D.A), R.support))));
  printf ('єдиність: %d задач, усі errnum = 0 і status = 5: %d; max(верх - низ) = %.3g; max відхилення від x* = %.3g\n', ...
          Uq.n_lp, Uq.all_optimal, Uq.max_span, Uq.max_dev_from_x);
  printf ('чутливість: max|приріст - 0.01 b u| = %.3g; базис збережено в усіх 9 випадках: %d\n', ...
          max (abs (Sn.diff)), all (Sn.basis_kept));
  printf ('усі вимоги +1%%: C = %.15f; приріст - 0.01 C* = %.3g; базис збережено: %d\n', ...
          Sn.all_cost, Sn.all_delta - Sn.all_pred, Sn.all_basis_kept);
  for j = Rd.inactive
    printf ('  неактивний рядок %-10s m_j = %.10f < b_j = %g; вартість без рядка - C* = %.3g\n', ...
            cfg.nutrient_keys{j}, Rd.m(j), R.b(j), Rd.cost_without(j) - R.C);
  end
  printf ('без усіх рядків із u_j = 0: вартість - C* = %.3g; max|зміна x| = %.3g\n', ...
          Rd.cost_without_all - R.C, Rd.x_without_all_dev);
end

% --- Варіант таблиці B: білок пшеничної крупи (№ 3) 393 замість 398 ---------------
% Єдина клітинка, яку звірка зі сканом с. 307 не підтвердила однозначно
% (source_check/SOURCE_CHECK_NOTES.md); за таблицею A очікується 393.
Dv = D44; Dv.label = '1944v';
iv = find (D44.id == 3);
Dv.A(2, iv) = 393; Dv = stg_tenths (Dv);
V.D = Dv;
V.R = stg_base (Dv, cfg, [], Dv.label);
assert (V.R.ok);
V.E = stg_exact (Dv.A10, cfg.b10, 1, V.R.support, V.R.Jplus);
V.Uq = stg_uniqueness (Dv, V.R, cfg);
V.Rd = stg_redundancy (Dv, V.R, cfg);
printf ('== Варіант 1944: білок пшеничної крупи 393 замість 398 ==\n');
printf ('C*(393) - C*(398) = %.3g; max|x(393) - x(398)| = %.3g; max|u(393) - u(398)| = %.3g\n', ...
        V.R.C - Y(2).R.C, max (abs (V.R.x - Y(2).R.x)), max (abs (V.R.u - Y(2).R.u)));
printf ('точна перевірка: оптимальність %d; єдиність %d; той самий визначник: %d\n', V.E.optimal, ...
        V.E.unique, strcmp (bi_str (V.E.det10), bi_str (Y(2).E.det10)));
printf ('max|r(393) - r(398)| = %.3g; єдиність: max(верх - низ) = %.3g\n', ...
        max (abs (V.R.r - Y(2).R.r)), V.Uq.max_span);
for j = V.Rd.inactive
  printf ('  m_j %-10s: %.10f (398) -> %.10f (393)\n', cfg.nutrient_keys{j}, Y(2).Rd.m(j), V.Rd.m(j));
end
rowsc = {'C_dollars_per_day', Y(2).R.C, V.R.C};
for i = 1:columns (D44.A), rowsc(end+1, :) = {['x_', D44.name{i}], Y(2).R.x(i), V.R.x(i)}; end
for j = 1:9, rowsc(end+1, :) = {['u_', cfg.nutrient_keys{j}], Y(2).R.u(j), V.R.u(j)}; end
for j = 1:9, rowsc(end+1, :) = {['Ax_', cfg.nutrient_keys{j}], Y(2).R.Ax(j), V.R.Ax(j)}; end
for i = 1:columns (D44.A), rowsc(end+1, :) = {['reduced_cost_', D44.name{i}], Y(2).R.r(i), V.R.r(i)}; end
for j = V.Rd.inactive
  rowsc(end+1, :) = {['min_intake_without_own_row_', cfg.nutrient_keys{j}], Y(2).Rd.m(j), V.Rd.m(j)};
end
rowsc(end+1, :) = {'exact_primal_optimum_unique', Y(2).E.unique, V.E.unique};
rowsc(end+1, :) = {'uniqueness_max_abs_span', Y(2).Uq.max_span, V.Uq.max_span};
for k = 1:rows (rowsc), rowsc{k, 4} = rowsc{k, 3} - rowsc{k, 2}; end
stg_csv (fullfile (cfg.csvdir, 'variant_1944_cereal_protein_393.csv'), ...
         {'quantity', 'value_with_398', 'value_with_393', 'difference'}, rowsc);

% --- 3. Історичні раціони ------------------------------------------------------
H = stg_historic (D39, D44, Y(1).R, Y(2).R, cfg);
printf ('== Історичні раціони (табл. 2) ==\n');
yy = {'y1939', 'y1944'};
for y = 1:2
  h = H.(yy{y});
  printf ('%s: сума вартостей %.2f; вартість за кількостями й цінами %.4f; 365 C* = %.4f; 365.25 C* = %.4f\n', ...
          DD{y}.label, h.sum_cost, h.sum_cost_from_qty, h.lp_annual(1), h.lp_annual(2));
  printf ('  бюджет/мінімум ЛП: %.6f (365 днів), %.6f (365.25 дня)\n', h.theta(1), h.theta(2));
  printf ('  надходження/вимога за 365 днів: %s\n', sprintf ('%.4f ', h.ratio_cost(:, 1)));
  printf ('  те саме для коефіцієнтів, збільшених на половину кроку друку: %s\n', ...
          sprintf ('%.4f ', h.ratio_cost_up));
  printf ('  мінімум ЛП за 365 днів для матриць, сумісних з округленням: від %.4f до %.4f дол.\n', ...
          365 * h.C_up, 365 * h.C_dn);
end

% --- 6. Багатоденні експерименти ----------------------------------------------
printf ('== Семиденна задача (матриця 1939 року) ==\n');
Md = stg_multiday (D39, cfg);
Mx = stg_multiday_exact (D39, Md, cfg);
printf ('C* = %.17g; сума добових мінімумів = %.17g; різниця = %.3g\n', Md.C, Md.sum_days, Md.decomp_gap);
printf ('добові мінімуми: %s\n', sprintf ('%.12f ', Md.Cday));
printf ('усі добові оптимуми єдині (точна перевірка): %d; однаковий носій у всі дні: %d\n', ...
        Mx.all_days_unique, Mx.same_basis);
for t = 1:7
  printf ('  день %d: носій %s; J+ %s\n', t, strjoin (D39.key(Md.day{t}.support), ', '), ...
          mat2str (Md.day{t}.Jplus));
end
for nm = {'iron', 'protein'}
  S = Md.(nm{1});
  printf ('%s: середнє в оптимумі %.12f; на оптимальній грані [%.12f, %.12f]\n', nm{1}, ...
          S.mean_joint, S.face_min, S.face_max);
  printf ('  максимум за бюджету %.8f + %.0e (допуск до вартості): %.12f\n', cfg.md_budget_base, ...
          cfg.md_budget_eps, S.eps_max);
  for k = 1:3
    xs = sprintf ('; точний знак (середнє - межа) = %d', Mx.(nm{1}).cmp(k));
    printf ('  межа %.5f: C* = %.15f, приріст = %.3e%s\n', S.bounds(k), S.cost(k), S.delta(k), xs);
  end
end

% --- Допоміжна перевірка: вихідна модель MathProg у glpsol ------------------------
% Не входить до основних результатів; показує, що незмінений stigler.mod дає
% той самий річний підсумок (365.25 дня) у тій самій бібліотеці GLPK.
if (! isempty (env.glpsol))
  [st, out] = system (['glpsol -m "', fullfile(cfg.datadir, 'stigler.mod'), '" 2>&1']);
  fid = fopen (fullfile (cfg.logdir, 'glpsol_stigler_mod.log'), 'w'); fputs (fid, out); fclose (fid);
  t = regexp (out, 'Total:\s+\$\s*([0-9.]+)', 'tokens', 'once');
  if (st == 0 && ! isempty (t))
    printf ('== glpsol, stigler.mod ==\nрічний підсумок у звіті моделі: %s дол.; 365.25 C* = %.2f дол.\n', ...
            t{1}, 365.25 * Y(1).R.C);
  else
    printf ('== glpsol, stigler.mod ==\nзапуск не вдався (код %d)\n', st);
  end
end

% --- 7. Результати --------------------------------------------------------------
stg_write_csv (cfg, env, Y, Dc, Md, Mx, H);
Cm = stg_compare (cfg, Y, Md, Mx, H);
stg_write_compare (cfg, Cm);
stg_tex (cfg, Y, Dc, Md, Mx, H);
stg_paragraphs (cfg, env, Y, Dc, Md, Mx, H, Cm, V);

st = [STG_RUNS.status]; er = [STG_RUNS.errnum];
printf ('== Підсумок ==\n');
printf ('запусків GLPK: %d; errnum = 0 і status = 5: %d\n', numel (st), sum (st == 5 & er == 0));
printf ('порівняння з текстом: рядків %d; підтверджено %d; потребують уваги %d\n', numel (Cm), ...
        sum ([Cm.ok]), sum (! [Cm.ok]));
for k = find (! [Cm.ok])
  printf ('  %s | %s | текст %.15g | GLPK %.15g | %s\n', Cm(k).place, Cm(k).what, Cm(k).text, ...
          Cm(k).glpk, Cm(k).verdict);
end
for k = find (strcmp ({Cm.kind}, 'solver'))
  printf ('  %s | %s | текст %.3g | GLPK %.3g\n', Cm(k).place, Cm(k).what, Cm(k).text, Cm(k).glpk);
end
diary off
