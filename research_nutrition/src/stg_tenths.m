function D = stg_tenths (D)
  % STG_TENTHS  Цілочислове подання даних: A10 = 10*A, price10 = 10*price.
  % Усі табличні числа мають щонайбільше один десятковий знак, тому
  % A10 і price10 --- точні цілі числа.
  D.A10 = round (10 * D.A);
  D.price10 = round (10 * D.price);
  assert (max (abs (10 * D.A(:) - D.A10(:))) < 1e-9);
  assert (max (abs (10 * D.price - D.price10)) < 1e-9);
  % коефіцієнт переходу від торгової одиниці до фунтів (NaN, якщо одиниця не вагова)
  n = numel (D.unit);
  D.lb_per_unit = nan (n, 1);
  for i = 1:n
    t = regexp (D.unit{i}, '^([0-9.]+)\s*(lb|oz)\.?$', 'tokens', 'once');
    if (! isempty (t))
      v = str2double (t{1});
      if (strcmp (t{2}, 'oz')), v = v / 16; end
      D.lb_per_unit(i) = v;
    end
  end
end
