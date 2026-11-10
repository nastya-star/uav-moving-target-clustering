function H = stg_historic (D39, D44, R39, R44, cfg)
  % STG_HISTORIC  Історичні раціони Стіглера (таблиця 2 роботи) проти
  % опублікованих матриць.
  %
  % Для кожного продукту: кількість, заявлена вартість, вартість за ціною
  % торгової одиниці. Допустимість перевіряється для добових витрат
  % x = (річна вартість)/T, T = 365 і 365.25.

  tab = stg_readtable2 (cfg);
  yrs = {'1939', '1944'}; DD = {D39, D44}; RR = {R39, R44};
  for y = 1:2
    D = DD{y}; R = RR{y};
    sel = strcmp (tab.year, yrs{y});
    id = tab.id(sel); qty = tab.qty(sel); cost = tab.cost(sel); total = tab.total(y);
    idx = zeros (size (id));
    for k = 1:numel (id), idx(k) = find (D.id == id(k)); end
    h.idx = idx; h.qty = qty; h.cost = cost; h.total = total;
    h.qty_unit = tab.qty_unit(sel);
    h.sum_cost = sum (cost);
    % кількість у торгових одиницях (фунти -> одиниці для вагових одиниць)
    lbu = D.lb_per_unit(idx);
    isw = strcmp (h.qty_unit, 'lb');
    units = qty; units(isw) = qty(isw) ./ lbu(isw);
    h.units = units;
    h.cost_from_qty = units .* D.price(idx) / 100;
    h.sum_cost_from_qty = sum (h.cost_from_qty);
    n = columns (D.A);
    for d = 1:2
      T = cfg.days(d);
      xs = zeros (n, 1); xs(idx) = cost / T;          % за заявленими вартостями
      xq = zeros (n, 1); xq(idx) = h.cost_from_qty / T; % за кількостями
      h.intake_cost(:, d) = D.A * xs;
      h.intake_qty(:, d) = D.A * xq;
      h.daily_budget(d) = total / T;
      h.lp_annual(d) = T * R.C;
      % найбільша частка вимог, яку покриває бюджет: V(theta b) = theta V(b)
      h.theta(d) = (total / T) / R.C;
    end
    h.ratio_cost = h.intake_cost ./ R.b;   % надходження / вимога
    h.ratio_qty = h.intake_qty ./ R.b;

    % --- вплив округлення друкованих коефіцієнтів ------------------------------
    % Кожний ненульовий елемент a_ji надруковано з кроком step_j, тому
    % неокруглене значення лежить у [a_ji - step_j/2, a_ji + step_j/2].
    % Якщо A' >= A поелементно, то V(A') <= V(A); звідси межі мінімальної
    % вартості для всіх матриць, сумісних з округленням.
    step = [0.1; 1; 0.1; 1; 0.1; 0.1; 0.1; 1; 1];
    half = repmat (step / 2, 1, n) .* (D.A > 0);
    Aup = D.A + half; Adn = max (D.A - half, 0);
    m = rows (D.A);
    [xu, h.C_up] = stg_lp (ones (n, 1), Aup, R.b, repmat ('L', 1, m), 1, cfg, ...
                           [D.label, ':rounding:up']);
    [xd, h.C_dn] = stg_lp (ones (n, 1), Adn, R.b, repmat ('L', 1, m), 1, cfg, ...
                           [D.label, ':rounding:down']);
    xs = zeros (n, 1); xs(idx) = cost / 365;
    h.ratio_cost_up = (Aup * xs) ./ R.b;     % найбільше сумісне надходження / вимога
    h.ratio_cost_dn = (Adn * xs) ./ R.b;
    H.(['y', yrs{y}]) = h;
  end
end
