function tab = stg_readtable2 (cfg)
  % STG_READTABLE2  Історичні раціони з data/stigler_table2_historic.csv.
  lines = strsplit (strtrim (fileread (fullfile (cfg.datadir, 'stigler_table2_historic.csv'))), "\n");
  tab.year = {}; tab.id = []; tab.qty = []; tab.qty_unit = {}; tab.cost = []; tab.name = {};
  tab.total = [NaN, NaN];
  for k = 2:numel (lines)
    t = strsplit (strtrim (lines{k}), ',', 'CollapseDelimiters', false);
    if (strcmp (t{2}, 'total'))
      tab.total(1 + strcmp (t{1}, '1944')) = str2double (t{6});
    else
      tab.year{end+1} = t{1}; tab.id(end+1) = str2double (t{2}); tab.name{end+1} = t{3};
      tab.qty(end+1) = str2double (t{4}); tab.qty_unit{end+1} = t{5};
      tab.cost(end+1) = str2double (t{6});
    end
  end
  tab.id = tab.id(:); tab.qty = tab.qty(:); tab.cost = tab.cost(:);
  tab.qty_unit = tab.qty_unit(:);
end
