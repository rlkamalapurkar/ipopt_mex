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
    IPOPT_HOME = 'C:\msys64\opt\ipopt\include';
    IPOPT_BIN  = 'C:\msys64\opt\ipopt\bin';
    IPOPT_LIB  = 'C:\msys64\opt\ipopt\lib';
    LIBS = [' -L' IPOPT_LIB ];
    NAMES = {'ipopt.dll','sipopt.dll'};
    for kkk=1:length(NAMES)
      LIBS = [ LIBS, ' -l', NAMES{kkk} ];
    end
    CMD = [ CMD ...
      '-DOS_WIN -I' IPOPT_HOME '\coin-or ' ...
      '-output ' IPOPT_BIN '\ipopt_win ' LIBS ...
    ];
%     CMD = [ CMD ...
%       '-DOS_WIN -I' IPOPT_HOME '/coin-or ' ...
%       '-output ' IPOPT_BIN 'ipopt_win' ];
else
  error('architecture not supported');
end

disp(CMD);
eval(CMD);

cd(old_dir);

disp('----------------------- DONE ----------------------------');
