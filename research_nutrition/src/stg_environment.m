function env = stg_environment (cfg)
  % STG_ENVIRONMENT  Фактичні версії середовища виконання.
  env.octave = OCTAVE_VERSION;
  env.host = computer ();
  [st, out] = system ('. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME"');
  env.os = strtrim (out);
  env.glpk_oct = which ('__glpk__');
  [st, out] = system (['ldd "', env.glpk_oct, '" 2>/dev/null | grep -i glpk']);
  env.glpk_lib = strtrim (out);
  [st, out] = system ("dpkg-query -W -f='${Package} ${Version}; ' libglpk40 octave glpk-utils 2>/dev/null");
  env.packages = strtrim (out);
  [st, out] = system ('glpsol --version 2>/dev/null | head -1');
  env.glpsol = strtrim (out);
  t = regexp (env.packages, 'libglpk40 ([0-9.]+)', 'tokens', 'once');
  if (isempty (t)), env.glpk_version = 'невідомо'; else, env.glpk_version = t{1}; end
  env.date = datestr (now (), 'yyyy-mm-dd HH:MM:SS');
  [st, out] = system (['sha256sum "', fullfile(cfg.datadir, 'stigler.mod'), '" "', ...
                       fullfile(cfg.datadir, 'stigler1944.csv'), '" 2>/dev/null']);
  env.sha256 = strtrim (out);
end
