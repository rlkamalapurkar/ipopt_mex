Windows and MacOS relevant parts of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with MUMPS and HSL linear solvers and detailed compilation instructions.

Instructions to compile Ipopt and the mex file on MacOS arm64. Tested with MacBook Air M3 Sonoma and MATLAB R2024b

0) Save current directory
```
DIR=$(pwd)
```

1) Install toolchain and compilers
```
brew update
brew upgrade
brew install bash gcc
brew link --overwrite gcc
brew install pkg-config
brew install metis
``` 
2) Install MUMPS
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$DIR/install"
make
make install
```
7) Get Ipopt code, compile, build, and test Ipopt
```
cd $DIR
git clone https://github.com/coin-or/Ipopt.git
cd Ipopt
mkdir ./build
cd build
../configure --with-mumps-cflags="-I$DIR/install/include/coin-or/mumps" --with-mumps-lflags="-L$DIR/install/lib -lcoinmumps" --prefix="$DIR/install" LDFLAGS="-Wl,-rpath,@loader_path"
make
make test
```
If all tests pass, compilation is successful, move the binaries in the `install` directory
```
make install
```
4) Get COIN-OR Tools project ThirdParty-HSL
```
cd $DIR
git clone https://github.com/coin-or-tools/ThirdParty-HSL.git hsl
```
5) Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `hsl/coinhsl`.
6) Configure, build, and install the HSL sources
```
cd hsl
mkdir ./build
cd build
../configure --prefix="$DIR/install" --enable-openmp
make
make install
```
7) Get modified Ipopt MATLAB interface
```
cd $DIR
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
```
8) Compile the mex file
In MATLAB, navigate to the `ipopt_mex\src` folder (Windows: `C:\msys64\home\YOUR_MSYS2_USER_NAME\ipopt_mex\src` or Linux: `\home\$USER\ipopt_mex\src`) and run `CompileIpoptMexLib.m`.
7) Make the installation portable
```
cd $DIR/install/lib
install_name_tool -change $DIR/install/lib/libipopt.3.dylib @loader_path/libipopt.3.dylib ipopt.mexmaca64
install_name_tool -change $DIR/install/lib/libsipopt.3.dylib @loader_path/libsipopt.3.dylib ipopt.mexmaca64
install_name_tool -change $DIR/install/lib/libcoinmumps.3.dylib @loader_path/libcoinmumps.3.dylib libipopt.3.dylib
install_name_tool -change $DIR/install/lib/libipopt.3.dylib @loader_path/libipopt.3.dylib libsipopt.3.dylib
```
Change the name of the library so it can be loaded by Ipopt at runtime
```
cp ./libcoinhsl.dylib ./libhsl.dylib
```
Instructions to compile the mex file on Windows PC. Tested with Windows 11 and MATLAB R2024b

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
../configure --prefix="/home/$USER/install"
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
../configure --prefix="/home/$USER/install"
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
../configure --with-mumps-cflags="-I/home/$USER/install/include/coin-or/mumps" --with-mumps-lflags="-L/home/$USER/install/lib -lcoinmumps" --with-hsl-cflags="-I/home/$USER/install/include/coin-or/hsl" --with-hsl-lflags="-L/home/$USER/install/lib -lcoinhsl" --prefix="/home/$USER/install"
make
make test
```
Linux: use the configure command
```
export ORIGIN='$ORIGIN'
export PREFIX=/home/$USER/install
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include/coin-or
../configure --prefix="$PREFIX" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="-L$LIBDIR -lcoinmumps" --with-hsl-cflags="-I$INCLUDEDIR/hsl" --with-hsl-lflags="-L$LIBDIR -lcoinhsl" --with-lapack-lflags="-L/usr/lib/x86_64-linux-gnu -lblas -llapack" LDFLAGS="-Wl,-rpath,\$\$ORIGIN -Wl,-rpath,." 
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
	cp libblas*.dll libgcc_s_seh*.dll libgfortran*.dll libgomp*.dll liblapack*.dll libmetis*.dll libquadmath*.dll libstdc++*.dll libwinpthread*.dll /home/$USER/install/bin/
	cd ~
	```
	Also move built libraries to the lib folder
	```
	mv ~/install/bin/* ~/install/lib
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

The complete toolbox with MUMPS and HSL linear solvers should now be in the `install` folder (Windows: `C:\msys64\home\YOUR_MSYS2_USER_NAME\install` or Linux: `\home\$USER\install`). The toolbox should be portable to any Windows computer. As long as the directories `install\bin` and `install\lib` are on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `install\examples` directory. In MATLAB, navigate to the `install` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
