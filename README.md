Windows and MacOS relevant parts of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with MUMPS and HSL linear solvers and detailed compilation instructions.

# MacOS arm64
Tested with MacBook Air M3 Sonoma and MATLAB R2024b

1) Set up environment
	- Save current directory
	```
	DIR=$(pwd)
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
	export INCLUDEDIR=$PREFIX/include/coin-or
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
../configure --prefix="$PREFIX"
make
make install
```
3) Compile Ipopt
	- Get Ipopt code, compile, build, and test Ipopt
	```
	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX" --with-mumps-cflags="-I$INCLUDEDIR/coin-or/mumps" --with-mumps-lflags="-L$LIBDIR -lcoinmumps" LDFLAGS="-Wl,-rpath,@loader_path"
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
	../configure --prefix="$PREFIX" --enable-openmp
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
	cd $LIBDIR
	install_name_tool -change $LIBDIR/libipopt.3.dylib @loader_path/libipopt.3.dylib ipopt.mexmaca64
	install_name_tool -change $LIBDIR/libsipopt.3.dylib @loader_path/libsipopt.3.dylib ipopt.mexmaca64
	install_name_tool -change $LIBDIR/libcoinmumps.3.dylib @loader_path/libcoinmumps.3.dylib libipopt.3.dylib
	install_name_tool -change $LIBDIR/libipopt.3.dylib @loader_path/libipopt.3.dylib libsipopt.3.dylib
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
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
	export INCLUDEDIR=$PREFIX/include/coin-or
 	```
2) Compile MUMPS
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$PREFIX"
make
make install
```
3) Compile HSL
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
	../configure --prefix="$PREFIX"
	make
	make install
	```
4) Compile Ipopt
	- Get Ipopt code, compile, build, and test Ipopt
	```
 	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX" --with-mumps-cflags="-I$INCLUDEDIR/coin-or/mumps" --with-mumps-lflags="-L$LIBDIR -lcoinmumps" --with-hsl-cflags="-I$INCLUDEDIR/coin-or/hsl" --with-hsl-lflags="-L$LIBDIR -lcoinhsl"
	make
	make test
	```
	- If all tests passed, then install Ipopt
	```
	make install
	```
5) Manage dependencies on the target PC (replace $MSYSDIR with your MSYS2 installation folder)
```
cd $MSYSDIR/mingw64/bin
cp libblas*.dll libgcc_s_seh*.dll libgfortran*.dll libgomp*.dll liblapack*.dll libmetis*.dll libquadmath*.dll libstdc++*.dll libwinpthread*.dll $LIBDIR
cd $DIR
mv $PREFIX/bin/* $LIBDIR
```
6) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
 	cd $DIR
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure mingw64 is set as the C and C++ compiler. In MATLAB, navigate to the `ipopt_mex\src` folder (`$DIR\ipopt_mex\src`) and run (replace $MSYSDIR with your MSYS2 installation folder)
	```
	setenv('MW_MINGW64_LOC',$MSYSDIR\mingw64')
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex\src` folder and run `CompileIpoptMexLib.m`.

The complete toolbox with MUMPS and HSL linear solvers should now be in `$DIR\install`. The toolbox should be portable to any Windows computer. As long as the directory `$DIR\install\lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `$DIR\install\examples` directory. In MATLAB, navigate to the `install` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
# Linux (MUMPS, MA27, MA57, and MA97)
MATLAB on linux ships Intel MKL, which includes LAPACK. The MKL library uses 64-bit integers, but Ipopt expects 32-bit integers, which causes a segmentation fault. I could not figure out how to get dynamically linked Ipopt to use openblas instead of MKL, but statically linked Ipopt works.
1) Install linux toolchain
	```
	sudo apt install gcc g++ gfortran git patch wget pkg-config liblapack-dev libopenblas-dev libmetis-dev make
	```
2) Copy the static blas library to the install folder
```
DIR=$(pwd)
export PREFIX=$DIR/install
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include/coin-or
mkdir install
mkdir install/lib
cp /usr/lib/x86_64-linux-gnu/libopenblas.a $LIBDIR/libopenblas.a
```
3) Compile MUMPS as a static library
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared
make
make install
```
4) Compile HSL (MA27, MA57, and MA97 work, others cause segmentation faults)
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
	../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared
	make
	make install
	```
5) Compile Ipopt as a static library
	- Get Ipopt code, compile, and build Ipopt
	```
 	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="$LIBDIR/libcoinmumps.a" --with-hsl-cflags="-I$INCLUDEDIR/hsl" --with-hsl-lflags="$LIBDIR/libcoinhsl.a $LIBDIR/libopenblas.a -lgfortran -lm" --disable-shared
	make
	make install
	```
 	- If you run `make test`, the tests will fail since they are not linked against `libcoinmumps.a`, but the mex file will be, so ignore the tests.
6) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
 	cd $DIR
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure mex compilers are set up correctly (gcc and g++)
	```
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex\src` folder and run `CompileIpoptMexLib.m`.

**IMPORTANT: On Linux, MATLAB ships its own C++ library which may have a version conflict with the standard library. If you run into issues related to `libstdc++`, launch MATLAB from a terminal by running**
```
export LD_PRELOAD=$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libstdc++.so.6
matlab
```
**(replace `/usr/lib/x86_64-linux-gnu/` by the appropriate standard library path if needed).**

The complete toolbox with MUMPS and HSL linear solvers should now be in `$DIR\ipopt_mex\src\install`. The toolbox should be portable to any Linux computer. As long as the directory `$DIR\install\lib` is on your MATLAB path, Ipopt should work.
