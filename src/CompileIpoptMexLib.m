clc;
clear functions;

old_dir = cd(fileparts(which(mfilename)));

[~,mexLoaded] = inmem('-completenames');
  eval('while mislocked(''ipopt''); munlock(''ipopt''); end;');

disp('---------------------------------------------------------');
SRC = ' ./ipopt.cc ./IpoptInterfaceCommon.cc ';
CMD = [ 'mex -largeArrayDims -Isrc ' SRC ];

if ispc
    % use ipopt precompiled with mingw64
    IPOPT_HOME = '..\..\ipopt_precompiled';
    IPOPT_BIN  = [IPOPT_HOME '\bin'];
    IPOPT_LIB  = [IPOPT_HOME '\lib'];
    LIBS = [' -L' IPOPT_LIB ];
    NAMES = {'ipopt.dll','sipopt.dll'};
    for kkk=1:length(NAMES)
      LIBS = [ LIBS, ' -l', NAMES{kkk} ];
    end
    CMD = [ CMD ...
      '-DOS_WIN -I' IPOPT_HOME '\include\coin-or ' ...
      '-output ' IPOPT_BIN '\ipopt_win ' LIBS ...
    ];
	copyfile ..\examples ..\..\ipopt_precompiled\examples
    copyfile ..\lib ..\..\ipopt_precompiled\lib
elseif isunix
	% use ipopt precompiled with gcc
    IPOPT_HOME = '../../ipopt_precompiled';
    IPOPT_LIB = [IPOPT_HOME '/lib'];
    IPOPT_BIN = [IPOPT_HOME '/bin'];
    CMD = [ CMD ...
    '-I' IPOPT_HOME '/include/coin-or ' ...
    '-DOS_LINUX -output ' IPOPT_BIN '/ipopt_linux '...
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