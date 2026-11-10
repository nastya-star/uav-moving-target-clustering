function cfg = stg_config ()
  % STG_CONFIG  Спільні параметри всіх обчислень задачі Стіглера.
  %
  % Порядок показників зафіксовано: енергія, білок, кальцій, залізо,
  % вітамін A, тіамін, рибофлавін, ніацин, вітамін C.
  % Енергія вимірюється в тисячах ккал, вітамін A --- у тисячах МО.

  cfg.nutrient_keys = {'calories','protein','calcium','iron','vitaminA', ...
                       'thiamine','riboflavin','niacin','ascorbicAcid'};
  cfg.nutrient_uk = {'Енергія, тис. ккал','Білок, г','Кальцій, г','Залізо, мг', ...
                     'Вітамін A, тис. МО','Вітамін B$_1$, мг','Вітамін B$_2$, мг', ...
                     'Ніацин, мг','Вітамін C, мг'};
  cfg.b = [3; 70; 0.8; 12; 5; 1.8; 2.7; 18; 75];
  % Ті самі вимоги в десятих частках одиниці (цілі числа для точної перевірки).
  cfg.b10 = [30; 700; 8; 120; 50; 18; 27; 180; 750];

  % --- Параметри GLPK (функція glpk GNU Octave) -------------------------
  p = struct ();
  p.msglev   = 1;      % лише повідомлення про помилки (3 --- для базових задач)
  p.lpsolver = 1;      % модифікований симплекс-метод
  p.dual     = 1;      % двофазний прямий симплекс-метод
  p.presol   = 0;      % без пресолвера: статус і базис стосуються вихідної задачі
  p.scale    = 16;     % GLP_SF_EQ, рівноважне масштабування (типове в Octave)
  p.price    = 34;     % GLP_PT_PSE, найкрутіше ребро
  p.rtest    = 34;     % GLP_RT_HAR, двопрохідний тест Гарріса
  p.tolbnd   = 1e-9;   % відносний допуск прямої допустимості
  p.toldj    = 1e-9;   % абсолютний допуск двоїстої допустимості
  p.tolpiv   = 1e-10;  % відносний допуск вибору провідного елемента
  p.itlim    = 100000; % межа кількості ітерацій
  cfg.glpk = p;

  % --- Допуски подальших перевірок (не параметри розв'язувача) ----------
  cfg.tol_feas    = 1e-9;   % припустиме порушення Ax>=b, x>=0, A'u<=1, u>=0
  cfg.tol_gap     = 1e-12;  % припустимий двоїстий розрив |1'x - b'u|
  cfg.tol_comp    = 1e-12;  % припустимі |u_j s_j| та |x_i r_i|
  cfg.tol_support = 1e-9;   % x_i > tol_support  => продукт належить носію
  cfg.tol_active  = 1e-9;   % |s_j| <= tol_active*max(1,|b_j|) => рядок активний

  % SHA-256 файлу examples/stigler.mod з архіву glpk-4.65.tar.gz
  cfg.sha256_stigler_mod = 'b0930f90e9b9ddee6f4aacea7a9d64aad6a5e1b3ec19eadc65d5cba75d493a93';

  cfg.lb_gram   = 453.6;    % грамів у фунті (значення, вжите в таблиці A)
  cfg.days      = [365, 365.25];

  % --- Багатоденний експеримент -----------------------------------------
  cfg.md_energy  = [3, 3.3, 3.6, 3, 3.3, 3.6, 3.3];
  cfg.md_protein = [70, 73.5, 77, 70, 73.5, 77, 73.5];
  cfg.md_iron_bounds    = [12, 62.03914, 65.14113];
  cfg.md_protein_days   = [2, 3, 5, 6, 7];
  cfg.md_protein_bounds = [74.9, 158.66131, 166.594];
  cfg.md_budget_base = 0.79671475;   % значення з тексту роботи
  cfg.md_budget_eps  = 1e-7;         % допуск до вартості

  here = fileparts (mfilename ('fullpath'));
  cfg.root    = fileparts (here);
  cfg.datadir = fullfile (cfg.root, 'data');
  cfg.outdir  = fullfile (cfg.root, 'results');
  cfg.csvdir  = fullfile (cfg.outdir, 'csv');
  cfg.texdir  = fullfile (cfg.outdir, 'tex');
  cfg.logdir  = fullfile (cfg.outdir, 'logs');
end
