clc;
clear functions;

old_dir = cd(fileparts(which(mfilename)));

[~,mexLoaded] = inmem('-completenames');
  eval('while mislocked(''ipopt''); munlock(''ipopt''); end;');

disp('---------------------------------------------------------');
SRC = ' ./ipopt.cc ./IpoptInterfaceCommon.cc ';
CMD = [ 'mex -largeArrayDims -Isrc ' SRC ];
if ismac
  % use ipopt precompiled with gcc
  IPOPT_HOME = '../../install';
  IPOPT_LIB  = [IPOPT_HOME '/lib'];
  IPOPT_PKG  = [IPOPT_HOME '/ipopt/lib'];
  LIBS = [' -L' IPOPT_LIB ];
  NAMES = {'ipopt','sipopt'};
  for lib=1:length(NAMES)
    LIBS = [ LIBS, ' -l', NAMES{lib} ];
  end
  CMD = [ CMD ...
    '-I' IPOPT_HOME '/include/coin-or '...
    ' -DOS_MAC -output ' IPOPT_PKG '/ipopt ' LIBS ' '...
    'LDFLAGS=''$LDFLAGS -Wl,-rpath,.,-rpath,@loader_path -framework Accelerate -ldl'' ' ...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' ' ...
  ];
  copyfile ../examples/ ../../install/ipopt/examples
  copyfile ../lib ../../install/ipopt/lib
elseif ispc
  % use ipopt precompiled with mingw64
  IPOPT_HOME = '..\..\install';
  IPOPT_LIB  = [IPOPT_HOME '\lib'];
  LIBS = [' -L' IPOPT_LIB ];
  NAMES = {'ipopt.dll','sipopt.dll'};
  for lib=1:length(NAMES)
    LIBS = [ LIBS, ' -l', NAMES{lib} ];
  end
  CMD = [ CMD ...
    '-DOS_WIN -I' IPOPT_HOME '\include\coin-or ' ...
    '-output ' IPOPT_LIB '/ipopt ' LIBS ...
  ];
  copyfile ..\examples ..\..\install\examples
  copyfile ..\lib ..\..\install\lib
elseif isunix
  % use ipopt precompiled with gcc
  IPOPT_HOME = '../../install';
  IPOPT_LIB = [IPOPT_HOME '/lib'];
  LIBS = [' -L' IPOPT_LIB ];
  % NAMES = {'ipopt','sipopt',...
  %   'coinmumps','openblas','metis','GKlib',...
  %  'coinhsl',... % Remove if hsl not available
  %  'spral','hwloc',... % Remove if spral not available
  %  'dl','MatlabDataArray','mx','mex','mat','m','gfortran','gomp'};
  NAMES = {'ipopt', 'sipopt'};
  needs_metis = false;
  if ~isempty(dir(fullfile(IPOPT_LIB, 'libcoinmumps.*')))
    NAMES = [NAMES, {'coinmumps'}];
    needs_metis = true;
  end
  if ~isempty(dir(fullfile(IPOPT_LIB, 'libcoinhsl.*')))
    NAMES = [NAMES, {'coinhsl'}];
    % ThirdParty-HSL typically links Metis if available
    needs_metis = true; 
  end
  if ~isempty(dir(fullfile(IPOPT_LIB, 'libspral.*')))
    NAMES = [NAMES, {'spral', 'hwloc'}];
    needs_metis = true;
  end
  if needs_metis
    NAMES = [NAMES, {'metis', 'GKlib'}];
  end
  NAMES = [NAMES, {'openblas', 'dl', 'MatlabDataArray', 'mx', 'mex', 'mat', 'm', 'gfortran', 'gomp'}];
  for lib=1:length(NAMES)
    LIBS = [ LIBS, ' -l', NAMES{lib} ];
  end
  CMD = [ CMD ...
    '-I' IPOPT_HOME '/include/coin-or '...
    '-DOS_LINUX -output ' IPOPT_LIB '/ipopt '...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' '...
    'LDFLAGS=''$LDFLAGS -static-libgcc -static-libstdc++ '...
    '-Wl,-rpath,\$ORIGIN,-rpath,$MATLABROOT/bin/$ARCH'' '...
    '-L$MATLABROOT/bin/$ARCH ' LIBS];
  copyfile ../examples ../../install/examples
  copyfile ../lib ../../install/lib
else
  error('architecture not supported');
end

disp(CMD);
eval(CMD);

cd(old_dir);

disp('----------------------- DONE ----------------------------');
