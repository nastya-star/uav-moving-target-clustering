function D = stg_load1944 (cfg)
  % STG_LOAD1944  Читає 14 рядків таблиці B (с. 307) із data/stigler1944.csv.
  %
  % Коефіцієнти вже нормовано на один долар; порожні клітинки таблиці
  % записано нулями.

  fname = fullfile (cfg.datadir, 'stigler1944.csv');
  lines = strsplit (strtrim (fileread (fname)), "\n");
  hdr = strsplit (strtrim (lines{1}), ',');
  n = numel (lines) - 1;
  assert (n == 14, 'stigler1944.csv: очікувано 14 рядків, знайдено %d', n);
  need = [{'id','name','unit','price_cents'}, cfg.nutrient_keys];
  assert (isequal (hdr, need), 'stigler1944.csv: інший порядок стовпців');

  D.label = '1944';
  D.source = 'Stigler (1945), таблиця B, с. 307; файл stigler1944.csv';
  D.A = zeros (9, n); D.price = zeros (n, 1); D.id = zeros (1, n);
  D.key = cell (1, n); D.name = cell (1, n); D.unit = cell (1, n);
  for i = 1:n
    tok = strsplit (strtrim (lines{i+1}), ',', 'CollapseDelimiters', false);
    assert (numel (tok) == 13, 'stigler1944.csv: рядок %d', i + 1);
    for q = 4:13
      assert (! isempty (regexp (tok{q}, '^(\d+|\d*\.\d)$', 'once')), ...
              'stigler1944.csv: число "%s" у рядку %d', tok{q}, i + 1);
    end
    D.id(i) = str2double (tok{1});
    D.key{i} = sprintf ('b%02d', D.id(i));
    D.name{i} = tok{2}; D.unit{i} = tok{3};
    D.price(i) = str2double (tok{4});
    D.A(:, i) = str2double (tok(5:13))';
  end
  D.weight = nan (n, 1);
  D = stg_tenths (D);
end
