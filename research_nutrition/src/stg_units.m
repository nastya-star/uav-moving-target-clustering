function Q = stg_units (D, x, cfg)
  % STG_UNITS  Перехід від витрат x_i (дол./день) до торгових одиниць:
  %   z_i = 100 x_i / p_i,  p_i --- ціна торгової одиниці в центах.
  % Річні кількості обчислюються окремо для 365 і 365.25 дня.
  % Фунти визначені лише для вагових одиниць (lb, oz): 10 lb -> 10, 20 oz -> 1.25.
  Q.z_day = 100 * x ./ D.price;
  Q.z_365 = 365 * Q.z_day;
  Q.z_36525 = 365.25 * Q.z_day;
  Q.lb_day = Q.z_day .* D.lb_per_unit;
  Q.lb_365 = Q.z_365 .* D.lb_per_unit;
  Q.lb_36525 = Q.z_36525 .* D.lb_per_unit;
  Q.cost_365 = 365 * x;
  Q.cost_36525 = 365.25 * x;
end
