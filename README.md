Windows-relevant parts of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with MUMPS and HSL linear solvers and detailed compilation instructions.

Instructions to compile the mex file on Windows PC. Tested with Windows 11 and MATLAB R2021b

1) Install MSYS2 to `C:\msys64`
2) Install toolchain and compilers

```
pacman -S --needed binutils diffutils git grep make patch pkgconf
pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran
pacman -S --needed mingw-w64-x86_64-lapack mingw-w64-x86_64-metis
```	
Restart MSYS2, make sure to launch the `MSYS2 MinGW x64` shortcut and **not** the `MSYS2 MSYS` app. 

To compile for linux using WSL, install toolchain in WSL
```
sudo apt-get install gcc g++ gfortran git patch wget pkg-config liblapack-dev libmetis-dev make
```

3) Install MUMPS
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="/opt/ipopt"
make
sudo make install
cd ~
```
4) Get COIN-OR Tools project ThirdParty-HSL
```
git clone https://github.com/coin-or-tools/ThirdParty-HSL.git
```
5) Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `ThirdParty-HSL/coinhsl`.
6) In ThirdParty-HSL, configure, build, and install the HSL sources
```
cd ThirdParty-HSL
mkdir ./build
cd build
../configure --prefix="/opt/ipopt"
make
sudo make install
cd ~
```
7) Get Ipopt code, compile, build, and test Ipopt
```
git clone https://github.com/coin-or/Ipopt.git
mkdir ./Ipopt/build
cd Ipopt/build
~/Ipopt/configure --with-mumps-cflags="-I/opt/ipopt/include/coin-or/mumps" --with-mumps-lflags="-L/opt/ipopt/lib -lcoinmumps" --with-hsl-cflags="-I/opt/ipopt/include/coin-or/hsl" --with-hsl-lflags="-L/opt/ipopt/lib -lcoinhsl" --prefix="/opt/ipopt"
make
make test
```
8) Install Ipopt
```
sudo make install
cd ~
```
9) Get modified Ipopt MATLAB interface and copy the Ipopt wrapper files to the toolbox directory
```
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
cp -R ~/ipopt_mex/lib/* /opt/ipopt/lib/
cp -R ~/ipopt_mex/examples /opt/ipopt/examples
```
10) Copy dependencies to the Ipopt folder
```
cd /mingw64/bin
cp libblas*.dll libgcc_s_seh*.dll libgfortran*.dll libgomp*.dll liblapack*.dll libmetis*.dll libquadmath*.dll libstdc++*.dll libwinpthread*.dll /opt/ipopt/bin/
cd ~
```
11) Compile to MATLAB mex file. First, make sure mingw64 is set as the C and C++ compiler.
```
setenv('MW_MINGW64_LOC','C:\msys64\mingw64')
mex -setup 
mex -setup c++
```
Then, run `CompileIpoptMexLib.m`.

The complete toolbox with MUMPS and HSL linear solvers should now be in `C:\msys64\opt\ipopt`. The toolbox should be portable to any Windows computer. As long as the directories `...\ipopt\bin` and `...\ipopt\lib` are on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `...\ipopt\examples` directory.
```
addpath('C:\msys64\opt\ipopt\lib')
addpath('C:\msys64\opt\ipopt\bin')
cd ..\examples
test_BartholomewBiggs
