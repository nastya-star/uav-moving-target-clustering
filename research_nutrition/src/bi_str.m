function s = bi_str (a)
  % BI_STR  Десятковий запис.
  if (a.s == 0), s = '0'; return; end
  s = sprintf ('%d', a.d(end));
  for k = numel (a.d)-1:-1:1
    s = [s, sprintf('%07d', a.d(k))];
  end
  if (a.s < 0), s = ['-', s]; end
end
