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

To compile for linux, install linux toolchain
```
sudo apt install gcc g++ gfortran git patch wget pkg-config liblapack-dev libblas-dev libmetis-dev make
```

3) Install MUMPS
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="/home/$USER/ipopt_precompiled"
make
make install
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
../configure --prefix="/home/$USER/ipopt_precompiled"
make
make install
cd ~
```
7) Get Ipopt code, compile, build, and test Ipopt
Windows:
```
git clone https://github.com/coin-or/Ipopt.git
cd Ipopt
mkdir ./build
cd build
../configure --with-mumps-cflags="-I/home/$USER/ipopt_precompiled/include/coin-or/mumps" --with-mumps-lflags="-L/home/$USER/ipopt_precompiled/lib -lcoinmumps" --with-hsl-cflags="-I/home/$USER/ipopt_precompiled/include/coin-or/hsl" --with-hsl-lflags="-L/home/$USER/ipopt_precompiled/lib -lcoinhsl" --prefix="/home/$USER/ipopt_precompiled"
make
make test
```
Linux: use the configure command
```
export ORIGIN='$ORIGIN'
../configure --prefix="/home/$USER/ipopt_precompiled" --with-mumps-cflags="-I/home/$USER/ipopt_precompiled/include/coin-or/mumps" --with-mumps-lflags="-L/home/$USER/ipopt_precompiled/lib -lcoinmumps" --with-hsl-cflags="-I/home/$USER/ipopt_precompiled/include/coin-or/hsl" --with-hsl-lflags="-L/home/$USER/ipopt_precompiled/lib -lcoinhsl" --with-lapack-lflags="-L/usr/lib/x86_64-linux-gnu -lblas -llapack" LDFLAGS="-Wl,-rpath,\$\$ORIGIN -Wl,-rpath,."
```
8) Install Ipopt
```
make install
cd ~
```
9) Get modified Ipopt MATLAB interface
```
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
```
10) Manage dependencies on the target PC

    - On Windows, copy dependencies to the Ipopt folder
	```
	cd /mingw64/bin
	cp libblas*.dll libgcc_s_seh*.dll libgfortran*.dll libgomp*.dll liblapack*.dll libmetis*.dll libquadmath*.dll libstdc++*.dll libwinpthread*.dll /home/$USER/ipopt_precompiled/bin/
	cd ~
	```
	- On Linux, make sure BLAS and LAPACK are installed (DOES NOT WORK)
	```diff
	- sudo apt install liblapack-dev libmetis-dev
	```
11) Compile to MATLAB mex file. 

	- On Windows, make sure mingw64 is set as the C and C++ compiler. In MATLAB, navigate to the `ipopt_mex\src` folder (`C:\msys64\home\YOUR_MSYS2_USER_NAME\ipopt_mex\src`) and run
	```
	setenv('MW_MINGW64_LOC','C:\msys64\mingw64')
	mex -setup 
	mex -setup c++
	```
In MATLAB, navigate to the `ipopt_mex\src` folder (Windows: `C:\msys64\home\YOUR_MSYS2_USER_NAME\ipopt_mex\src` or Linux: `\home\$USER\ipopt_mex\src`) and run `CompileIpoptMexLib.m`.

The complete toolbox with MUMPS and HSL linear solvers should now be in the `ipopt_precompiled` folder (Windows: `C:\msys64\home\YOUR_MSYS2_USER_NAME\ipopt_precompiled` or Linux: `\home\$USER\ipopt_precompiled`). The toolbox should be portable to any Windows computer and any Linux machine that has BLAS and LAPACK installed. As long as the directories `ipopt_precompiled\bin` and `ipopt_precompiled\lib` are on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `ipopt_precompiled\examples` directory. In MATLAB, navigate to the `ipopt_precompiled` directory and run
```
addpath(fullfile(pwd,'lib'));
addpath(fullfile(pwd,'bin'));
cd examples
test_BartholomewBiggs
```
