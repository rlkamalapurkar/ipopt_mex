clc;
clear functions;

old_dir = cd(fileparts(which(mfilename)));

[~,mexLoaded] = inmem('-completenames');
  eval('while mislocked(''ipopt''); munlock(''ipopt''); end;');

disp('---------------------------------------------------------');
SRC = ' ./ipopt.cc ./IpoptInterfaceCommon.cc ';
CMD = [ 'mex -largeArrayDims -Isrc ' SRC ];
if ismac
  %
  % libipopt must be set with:
  % install_name_tool -id "@loader_path/libipopt.3.dylib" libipopt.3.dylib
  %
  HOME = char(java.lang.System.getProperty('user.home'));
  IPOPT_HOME = [HOME '/Files/Tools/MATLAB/IPOPT'];
  IPOPT_LIB  = [IPOPT_HOME '/lib'];
  LIBS = [' -L' IPOPT_LIB ];
  NAMES = {'ipopt','sipopt'};
  for lib=1:length(NAMES)
    LIBS = [ LIBS, ' -l', NAMES{lib} ];
  end
  CMD = [ CMD ...
    '-I' IPOPT_HOME '/include/coin-or '...
    ' -DOS_MAC -output ' IPOPT_LIB '/ipopt ' LIBS ' '...
    'LDFLAGS=''$LDFLAGS -Wl,-rpath,. -framework Accelerate -ldl'' ' ...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' ' ...
  ];
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
    IPOPT_HOME = '../../ipopt_precompiled';
    IPOPT_LIB = [IPOPT_HOME '/lib'];
    CMD = [ CMD ...
    '-I' IPOPT_HOME '/include/coin-or ' ...
    '-DOS_LINUX -output ' IPOPT_LIB '/ipopt '...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' ' ...
    'LDFLAGS=''$LDFLAGS -static-libgcc -static-libstdc++'' ' ...
    'LINKLIBS=''-L' IPOPT_LIB ' -L$MATLABROOT/bin/$ARCH -Wl,-rpath,$MATLABROOT/bin/$ARCH ' ...
              '-Wl,-rpath,. -lipopt -lcoinmumps -lopenblas -lgfortran -lgomp -ldl ' ...
              '-lMatlabDataArray -lmx -lmex -lmat -lm '' ' ...
    ];
    copyfile ../examples ../../ipopt_precompiled/examples
    copyfile ../lib ../../ipopt_precompiled/lib
else
  error('architecture not supported');
end

disp(CMD);
eval(CMD);

cd(old_dir);

disp('----------------------- DONE ----------------------------');