function stg_write_compare (cfg, Cm)
  % STG_WRITE_COMPARE  Таблиця порівняння у CSV та LaTeX (longtable).
  rowsc = cell (numel (Cm), 7);
  for k = 1:numel (Cm)
    c = Cm(k);
    ts = sprintf ('%.17g', c.text); gs = sprintf ('%.17g', c.glpk);
    if (! isempty (c.tstr)), ts = c.tstr; gs = c.gstr; end
    rowsc(k, :) = {k, c.place, c.what, ts, gs, sprintf('%.3e', c.diff), c.verdict};
  end
  stg_csv (fullfile (cfg.csvdir, 'comparison.csv'), ...
           {'no','place_in_text','quantity','value_in_text','glpk_result','difference', ...
            'conclusion'}, rowsc);

  fid = fopen (fullfile (cfg.texdir, 'tab_comparison.tex'), 'w');
  fprintf (fid, '%% Згенеровано run_all.m; потребує пакетів longtable, booktabs, array.\n');
  fprintf (fid, '{\\scriptsize\\setlength{\\tabcolsep}{3pt}\n');
  fprintf (fid, '\\begin{longtable}{>{\\raggedright}p{4.3cm}rrr>{\\raggedright\\arraybackslash}p{2.3cm}}\n');
  fprintf (fid, '\\caption{Порівняння значень у тексті роботи з результатами GLPK}\\label{tab:glpk-comparison}\\\\\n');
  head = ['\\toprule\nМісце в роботі & Значення в тексті & Результат GLPK & ', ...
          'Різниця & Висновок \\\\\n\\midrule\n'];
  fprintf (fid, [head, '\\endfirsthead\n', head, '\\endhead\n\\bottomrule\n\\endfoot\n']);
  for k = 1:numel (Cm)
    c = Cm(k);
    sd = ['$', sci(c.diff), '$'];
    v = c.verdict;
    switch (c.kind)
      case 'round'
        st = ['$', tx(c.text, c.nd), '$']; sg = ['$', tx(c.glpk, min (c.nd + 2, 15)), '$'];
        if (! c.ok)
          v = sprintf ('розбіжність; пропоноване значення $%s$', tx (c.glpk, c.nd));
        end
      case 'less'
        st = ['$<', sci(c.text), '$']; sg = ['$', sci(c.glpk), '$']; sd = '---';
        if (! c.ok), v = 'нерівність не виконується'; end
      case 'solver'
        st = ['$', sci(c.text), '$']; sg = ['$', sci(c.glpk), '$'];
        v = sprintf ('числова похибка, залежить від розв’язувача; для GLPK: $%s$', sci (c.glpk));
      otherwise   % точні раціональні значення
        st = ['$', c.tstr, '$']; sg = ['$', c.gstr, '$']; sd = '$0$';
        if (! c.ok), sd = '---'; end
    end
    fprintf (fid, '%s: %s & %s & %s & %s & %s \\\\\n', upper1 (c.place), texesc (c.what), st, sg, sd, v);
  end
  fprintf (fid, '\\end{longtable}}\n');
  fclose (fid);
end

function s = upper1 (s)
  % перша літера велика: "табл. 4" -> "Табл. 4"
  if (strncmp (s, 'табл', 4)), s = ['Т', s(3:end)]; end
  if (strncmp (s, 'підрозд', 7)), s = ['П', s(3:end)]; end
end

function s = sci (v)
  % число у вигляді m \cdot 10^{e} з десятковою комою
  if (v == 0), s = '0'; return; end
  e = floor (log10 (abs (v)));
  m = v / 10 ^ e;
  if (abs (m) >= 9.995), m = m / 10; e++; end
  s = sprintf ('%s\\cdot10^{%d}', strrep (sprintf ('%.2f', m), '.', '{,}'), e);
end

function s = texesc (s)
  % математичні фрагменти в описах величин
  s = strrep (s, '10^-12', '$10^{-12}$');
  s = strrep (s, '10^-7', '$10^{-7}$');
  s = strrep (s, 'C_t*', '$C_t^*$');
  s = strrep (s, 'C*', '$C^*$');
  s = strrep (s, '(Ax*)_j', '$(Ax^*)_j$');
  s = strrep (s, 'u_j*', '$u_j^*$');
  s = strrep (s, 's_j', '$s_j$');
  s = strrep (s, 'm_j', '$m_j$');
  s = strrep (s, 'b_j u_j', '$b_ju_j^*$');
  s = strrep (s, 'D_j', '$D_j$');
  s = strrep (s, 'x*', '$x^*$');
  s = strrep (s, 'A(J+,S)', '$A_{J_+,S}$');
  s = strrep (s, ' x ', ' $\times$ ');
  s = strrep (s, '%', '\%');
  s = regexprep (s, '(\d),(\d)', '$1{,}$2');
end
