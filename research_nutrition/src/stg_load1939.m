function D = stg_load1939 (cfg)
  % STG_LOAD1939  Читає 77 продуктів із data/stigler.mod (GLPK 4.65).
  %
  % Файл не змінюється. Стовпці шукаються за назвами в заголовках таблиць,
  % тому порядок нутрієнтів перевіряється, а не припускається.

  fname = fullfile (cfg.datadir, 'stigler.mod');
  txt = fileread (fname);
  lines = strsplit (txt, "\n");

  % --- назви й торгові одиниці ------------------------------------------
  i0 = find (strncmp (lines, 'param : C :', 11), 1);
  keys = {}; names = {}; units = {};
  k = i0 + 1;
  while (! strcmp (strtrim (lines{k}), ';'))
    t = regexp (lines{k}, '^(\w+)\s+"([^"]+)"\s+"([^"]+)"', 'tokens', 'once');
    assert (! isempty (t), 'stigler.mod: неочікуваний рядок %d', k);
    keys{end+1} = t{1}; names{end+1} = t{2}; units{end+1} = t{3};
    k++;
  end
  n = numel (keys);
  assert (n == 77, 'stigler.mod: очікувано 77 продуктів, знайдено %d', n);

  % --- порядок множини нутрієнтів ---------------------------------------
  i1 = find (strncmp (lines, 'set N :=', 8), 1);
  setN = {};
  k = i1 + 1;
  while (! strcmp (strtrim (lines{k}), ';'))
    t = regexp (lines{k}, '^(\w+)', 'tokens', 'once');
    setN{end+1} = t{1};
    k++;
  end
  assert (isequal (setN, cfg.nutrient_keys), 'stigler.mod: інший порядок нутрієнтів');

  % --- дві частини таблиці "param data" ---------------------------------
  cols = {}; vals = zeros (n, 0); ndec_bad = 0; nread = zeros (1, 2);
  hdr = find (! cellfun ('isempty', regexp (lines, '^:\s+\w+.*:=\s*$')));
  i2 = find (strncmp (lines, 'param data', 10), 1);
  hdr = hdr(hdr > i2);
  assert (numel (hdr) == 2, 'stigler.mod: очікувано дві частини таблиці');
  for h = 1:2
    names_h = strsplit (strtrim (regexprep (lines{hdr(h)}, '^:|:=\s*$', '')));
    part = nan (n, numel (names_h));
    k = hdr(h) + 1;
    while (true)
      s = strtrim (lines{k});
      if (isempty (s) || strcmp (s, ';') || s(1) == ':'), break; end
      if (s(1) != '#')
        tok = strsplit (s);
        row = find (strcmp (keys, tok{1}));
        assert (numel (row) == 1 && numel (tok) == numel (names_h) + 1, ...
                'stigler.mod: рядок %d', k);
        for q = 2:numel (tok)
          % кожне число має щонайбільше один десятковий знак
          if (isempty (regexp (tok{q}, '^(\d+|\d*\.\d)$', 'once'))), ndec_bad++; end
          part(row, q-1) = str2double (tok{q});
        end
        nread(h)++;
      end
      k++;
    end
    assert (nread(h) == n && ! any (isnan (part(:))), 'stigler.mod: неповна таблиця');
    cols = [cols, names_h]; vals = [vals, part];
  end
  assert (ndec_bad == 0, 'stigler.mod: є числа з більш ніж одним десятковим знаком');

  D.label = '1939';
  D.source = 'GLPK 4.65, examples/stigler.mod (таблиця A Стіглера, 15 серпня 1939 р.)';
  D.key = keys; D.name = names; D.unit = units;
  D.id = 1:n;
  D.price = vals(:, strcmp (cols, 'price'));        % центи за торгову одиницю
  D.weight = vals(:, strcmp (cols, 'weight'));      % їстівних грамів на 1 дол.
  A = zeros (9, n);
  for j = 1:9
    c = find (strcmp (cols, cfg.nutrient_keys{j}));
    assert (numel (c) == 1);
    A(j, :) = vals(:, c)';
  end
  D.A = A;
  D = stg_tenths (D);

  % --- добові вимоги з файлу мають збігатися із заданим b ----------------
  i3 = find (strncmp (lines, 'param allowance :=', 18), 1);
  ballow = nan (9, 1);
  for k = i3+1:i3+9
    tok = strsplit (strtrim (lines{k}));
    ballow(strcmp (cfg.nutrient_keys, tok{1})) = str2double (tok{2});
  end
  assert (isequal (ballow, cfg.b), 'stigler.mod: вимоги відрізняються від b');
  D.b_file = ballow;
end
