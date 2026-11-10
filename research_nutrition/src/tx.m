function s = tx (v, nd)
  % TX  Число для LaTeX із десятковою комою: 0{,}123.
  s = strrep (sprintf ('%.*f', nd, v), '.', '{,}');
  if (strcmp (regexprep (s, '[0{},]', ''), '-')), s = s(2:end); end  % "-0,000" -> "0,000"
end
