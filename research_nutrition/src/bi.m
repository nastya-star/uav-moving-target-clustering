function r = bi (v)
  % BI  Довге ціле число: структура із полями s (знак -1, 0, 1) і d (розряди
  % за основою 10^7, молодші першими). Аргумент --- ціле число типу double
  % (|v| < 2^53) або десятковий рядок.
  if (ischar (v))
    s = 1;
    if (v(1) == '-'), s = -1; v = v(2:end); end
    assert (! isempty (regexp (v, '^\d+$', 'once')), 'bi: некоректний рядок');
    d = [];
    while (numel (v) > 7)
      d(end+1) = str2double (v(end-6:end)); v = v(1:end-7);
    end
    d(end+1) = str2double (v);
    r = bi_norm (s, d);
  else
    assert (isscalar (v) && v == round (v) && abs (v) < 2^53, 'bi: потрібне ціле |v| < 2^53');
    s = sign (v); v = abs (v); d = [];
    do
      d(end+1) = mod (v, 1e7); v = floor (v / 1e7);
    until (v == 0)
    r = bi_norm (s, d);
  end
end
