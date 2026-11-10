function Dc = stg_datacheck (D39, D44, cfg)
  % STG_DATACHECK  Перевірки вихідних даних, які не потребують розв'язувача.
  %
  % 1939: частка їстівної маси f_i = weight_i * (p_i/100) / (грамів у торговій
  %       одиниці) для вагових одиниць; має бути 0 < f_i <= 1.
  % 1944: для рядків таблиці B з номерами <= 77 коефіцієнти на долар мають
  %       дорівнювати коефіцієнтам 1939 року, помноженим на p39/p44
  %       (склад продукту не змінюється, змінюється лише ціна).
  %       Відхилення вимірюється в одиницях останнього друкованого знака.

  % --- 1939 -----------------------------------------------------------------
  g_unit = D39.lb_per_unit * cfg.lb_gram;
  Dc.edible = D39.weight .* (D39.price / 100) ./ g_unit;   % NaN для невагових
  % ціну надруковано з кроком 0.1 цента, масу --- з кроком 1 г; звідси
  % найбільше значення f_i, сумісне зі стовідсотковою їстівною часткою
  Dc.edible_cap = (1 + 0.05 ./ D39.price) .* (1 + 0.5 ./ D39.weight);
  Dc.edible_ok = all (isnan (Dc.edible) | (Dc.edible > 0 & Dc.edible <= Dc.edible_cap));

  % --- 1944 -----------------------------------------------------------------
  step = [0.1; 1; 0.1; 1; 0.1; 0.1; 0.1; 1; 1];   % крок друку кожного нутрієнта
  n = numel (D44.id);
  Dc.pred = nan (9, n); Dc.dev_units = nan (9, n); Dc.ratio = nan (1, n);
  Dc.name39 = repmat ({''}, 1, n);
  for i = 1:n
    k = D44.id(i);
    if (k <= 77)
      Dc.ratio(i) = D39.price(k) / D44.price(i);
      Dc.pred(:, i) = D39.A(:, k) * Dc.ratio(i);
      Dc.dev_units(:, i) = (D44.A(:, i) - Dc.pred(:, i)) ./ step;
      Dc.name39{i} = D39.name{k};
    end
  end
  Dc.step = step;
  Dc.max_dev_units = max (abs (Dc.dev_units(:)));
  % нулі таблиці B мають збігатися з нулями таблиці A
  both = ! isnan (Dc.pred);
  Dc.zero_pattern_ok = all ((D44.A(both) == 0) == (Dc.pred(both) == 0));
  Dc.n_cross = sum (D44.id <= 77);

  % Примітки до таблиці B наводять їстівну масу на 1 дол. для нових продуктів:
  % № 78 (20 унцій) --- 4647 г, № 80 (1 фунт) --- 2071 г
  % (source_check/SOURCE_CHECK_NOTES.md). Перевірка ціни й торгової одиниці:
  fn = [78, 4647; 80, 2071];
  Dc.footnote = zeros (rows (fn), 3);
  for k = 1:rows (fn)
    i = find (D44.id == fn(k, 1));
    g = D44.lb_per_unit(i) * cfg.lb_gram / (D44.price(i) / 100);
    Dc.footnote(k, :) = [fn(k, 1), fn(k, 2), g];
  end
end
