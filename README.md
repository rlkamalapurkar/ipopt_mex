Windows and MacOS relevant parts of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with MUMPS and HSL linear solvers and detailed compilation instructions.

# MacOS arm64
Tested with MacBook Air M3 Sonoma and MATLAB R2024b

1) Set up environment
	- Save current directory
	```
	DIR=$(pwd)
	```
	- Install toolchain and compilers
	```
	brew update
	brew upgrade
	brew install bash gcc
	brew link --overwrite gcc
	brew install pkg-config
	brew install metis
	``` 
2) Compile MUMPS
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
7) Compile Ipopt
	- Get Ipopt code, compile, build, and test Ipopt
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
	- If all tests pass, compilation is successful, move the binaries in the `install` directory
	```
	make install
	```
4) Compile HSL
	- Get COIN-OR Tools project ThirdParty-HSL
	```
	cd $DIR
	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git hsl
	```
	- Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `hsl/coinhsl`.
	- Configure, build, and install the HSL sources
	```
	cd hsl
	mkdir ./build
	cd build
	../configure --prefix="$DIR/install" --enable-openmp
	make
	make install
	```
5) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
	cd $DIR
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure C and C++ compilers are set up in MATLAB. Navigate to the `ipopt_mex/src` folder and run
	```
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex/src` folder and run `CompileIpoptMexLib.m`.
6) Make the installation portable
	- Adjust install names
	```
	cd $DIR/install/lib
	install_name_tool -change $DIR/install/lib/libipopt.3.dylib @loader_path/libipopt.3.dylib ipopt.mexmaca64
	install_name_tool -change $DIR/install/lib/libsipopt.3.dylib @loader_path/libsipopt.3.dylib ipopt.mexmaca64
	install_name_tool -change $DIR/install/lib/libcoinmumps.3.dylib @loader_path/libcoinmumps.3.dylib libipopt.3.dylib
	install_name_tool -change $DIR/install/lib/libipopt.3.dylib @loader_path/libipopt.3.dylib libsipopt.3.dylib
	```
	- Change the name of the library so it can be loaded by Ipopt at runtime
	```
	cp ./libcoinhsl.dylib ./libhsl.dylib
	```
The complete toolbox with MUMPS and HSL linear solvers should now be in the `install` folder. The toolbox should be portable to any MacOS arm64 computer. As long as the directory `install/lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `install/examples` directory. In MATLAB, navigate to the `install` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
# Windows x86-64
Tested with Windows 11 and MATLAB R2024b
1) Set up the environment
	- Install MSYS2 (In the following, MSYSDIR refers to the folder where MSYS2 is installed)
	- Install toolchain and compilers
	```
	pacman -S --needed binutils diffutils git grep make patch pkgconf
	pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran
	pacman -S --needed mingw-w64-x86_64-lapack mingw-w64-x86_64-metis
	```	
	- Restart MSYS2, make sure to launch the `MSYS2 MinGW x64` shortcut and **not** the `MSYS2 MSYS` app.
	- Store current directory
	```
 	DIR=$(pwd)

3) Compile MUMPS
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
4) Compile HSL
	- Get COIN-OR Tools project ThirdParty-HSL
	```
	cd $DIR
	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git hsl
	```
	- Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `hsl/coinhsl`.
	- In ThirdParty-HSL, configure, build, and install the HSL sources
	```
	cd hsl
	mkdir ./build
	cd build
	../configure --prefix="$DIR/install"
	make
	make install
	```
7) Compile Ipopt
	- Get Ipopt code, compile, build, and test Ipopt
	```
 	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --with-mumps-cflags="-I$DIR/install/include/coin-or/mumps" --with-mumps-lflags="-L$DIR/install/lib -lcoinmumps" --with-hsl-cflags="-I$DIR/install/include/coin-or/hsl" --with-hsl-lflags="-L$DIR/install/lib -lcoinhsl" --prefix="$DIR/install"
	make
	make test
	```
	- If all tests passed, then install Ipopt
	```
	make install
	```
10) Manage dependencies on the target PC (replace $MSYSDIR with your MSYS2 installation folder)
```
cd $MSYSDIR/mingw64/bin
cp libblas*.dll libgcc_s_seh*.dll libgfortran*.dll libgomp*.dll liblapack*.dll libmetis*.dll libquadmath*.dll libstdc++*.dll libwinpthread*.dll $DIR/install/lib/
cd $DIR
mv $DIR/install/bin/* $DIR/install/lib
```
9) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure mingw64 is set as the C and C++ compiler. In MATLAB, navigate to the `ipopt_mex\src` folder (`$DIR\ipopt_mex\src`) and run (replace $MSYSDIR with your MSYS2 installation folder)
	```
	setenv('MW_MINGW64_LOC',$MSYSDIR\mingw64')
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex\src` folder and run `CompileIpoptMexLib.m`.

The complete toolbox with MUMPS and HSL linear solvers should now be in `$DIR\ipopt_mex\src\install`. The toolbox should be portable to any Windows computer. As long as the directory `$DIR\install\lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `$DIR\install\examples` directory. In MATLAB, navigate to the `install` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
# Linux (DOES NOT WORK)
- To compile for linux, install linux toolchain
	```
	sudo apt install gcc g++ gfortran git patch wget pkg-config liblapack-dev libblas-dev libmetis-dev make
	```
- On Linux, make sure BLAS and LAPACK are installed
```
sudo apt install liblapack-dev libmetis-dev
```
Linux: use the configure command
```
export ORIGIN='$ORIGIN'
export PREFIX=/home/$USER/install
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include/coin-or
../configure --prefix="$PREFIX" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="-L$LIBDIR -lcoinmumps" --with-hsl-cflags="-I$INCLUDEDIR/hsl" --with-hsl-lflags="-L$LIBDIR -lcoinhsl" --with-lapack-lflags="-L/usr/lib/x86_64-linux-gnu -lblas -llapack" LDFLAGS="-Wl,-rpath,\$\$ORIGIN -Wl,-rpath,." 
```
