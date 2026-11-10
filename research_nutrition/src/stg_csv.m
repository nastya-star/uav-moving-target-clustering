function stg_csv (fname, header, rowsc)
  % STG_CSV  Записує CSV. rowsc --- масив комірок; числа друкуються з %.17g.
  fid = fopen (fname, 'w');
  assert (fid > 0, 'не вдалося відкрити %s', fname);
  fprintf (fid, '%s\n', strjoin (header, ','));
  for i = 1:rows (rowsc)
    s = cell (1, columns (rowsc));
    for k = 1:columns (rowsc)
      v = rowsc{i, k};
      if (ischar (v))
        if (any (v == ',') || any (v == '"'))
          v = ['"', strrep(v, '"', '""'), '"'];
        end
        s{k} = v;
      elseif (islogical (v))
        s{k} = sprintf ('%d', v);
      elseif (isnan (v))
        s{k} = '';
      elseif (v == round (v) && abs (v) < 1e15)
        s{k} = sprintf ('%d', v);
      else
        s{k} = sprintf ('%.17g', v);
      end
    end
    fprintf (fid, '%s\n', strjoin (s, ','));
  end
  fclose (fid);
end
