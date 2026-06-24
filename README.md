This is a slightly modified copy of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with **MUMPS** and **HSL** linear solvers and detailed compilation instructions.

**Table of contents:**
 - [MacOS arm64](#mexmaca64)
 - [Windows x86-64](#mexw64)
 - [Linux x86-64](#mexa64)

<a id="mexmaca64"></a>
# MacOS arm64
Tested with MacBook Air M3 Sonoma and MATLAB R2024b

1) Set up environment
	- Save current directory
	```
	DIR=$(pwd)
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
    export PKGDIR=$PREFIX/ipopt
	export INCLUDEDIR=$PREFIX/include/coin-or
	```
	- Install toolchain and compilers (meson and ninja are only needed for spral)
	```
	brew update
	brew upgrade
	brew install bash gcc
	brew link --overwrite gcc
	brew install pkg-config
	brew install metis
    brew install meson ninja
    brew install dylibbundler
	```
**You will need to compile at least one linear solver from the three options below (MUMPS, SPRAL, and HSL).**

2) Compile MUMPS (optional)
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$PREFIX"
make install
```
3) Compile SPRAL (optional)
```
cd $DIR
git clone https://github.com/ralna/spral.git spral
cd spral
GCC_VER=$(basename $(ls /opt/homebrew/bin/gcc-* | head -n 1) | sed 's/gcc-//')
export CC="/opt/homebrew/bin/gcc-${GCC_VER}"
export CXX="/opt/homebrew/bin/g++-${GCC_VER}"
export FC="/opt/homebrew/bin/gfortran-${GCC_VER}"
export LDFLAGS="-L/opt/homebrew/lib"
meson setup build --prefix="$PREFIX" --default-library=shared -Dlibblas=blas -Dliblapack=lapack -Dtests=false -Dexamples=false
meson compile -C build
meson install -C build
```
4) Compile Ipopt (remove the spral flags if spral is not needed)
	- Get Ipopt code, compile, build, and test Ipopt
	```
	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX" LDFLAGS="-Wl,-rpath,@loader_path" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$PREFIX/lib -lspral -L/opt/homebrew/lib -lmetis"
	make test
	```
	- If all tests pass, compilation is successful, move the binaries in the `install` directory
	```
	make install
	```
5) Compile HSL (optional)
	- Get COIN-OR Tools project ThirdParty-HSL
	```
	cd $DIR
	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git hsl
	```
	- Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `hsl/coinhsl`.
	- Configure, build, and install the HSL sources (*the prefix is different here*)
	```
	cd hsl
	mkdir ./build
	cd build
	../configure --prefix="$PKGDIR" --enable-openmp --with-metis-cflags="-I/opt/homebrew/include" --with-metis-lflags="-L/opt/homebrew/lib -lmetis"
	make install
	```
 	- Change the name of the library so it can be loaded by Ipopt at runtime
	```
	mv $PKGDIR/lib/libcoinhsl.2.dylib $PKGDIR/lib/libhsl.dylib
	```
6) Compile the mex file
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
7) Make the installation portable
 	- Use `dylibbundler` to copy dependencies and fix install names (remove `-x libhsl.dylib` if hsl solvers are not compiled)
	```
 	cd $PKGDIR/lib
	dylibbundler -b -of -x ipopt.mexmaca64 -x libhsl.dylib -d . -p @loader_path
	```
 	- Fix multiple `@loader_path` entries added by `dylibbundler`
	```
	for file in *.dylib *.mexmaca64; do
        rpath_count=$(otool -l "$file" | grep -c "path @loader_path")
        while [ "$rpath_count" -gt 1 ]; do
            install_name_tool -delete_rpath @loader_path/ "$file" 2>/dev/null || install_name_tool -delete_rpath @loader_path "$file" 2>/dev/null
            rpath_count=$((rpath_count - 1))
        done
        codesign --force --sign - "$file"
    done
	```
The complete toolbox with MUMPS and HSL linear solvers should now be in the `$DIR/install/ipopt` folder. The toolbox should be portable to any MacOS arm64 computer. As long as the directory `$DIR/install/ipopt/lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `$DIR/install/ipopt/examples` directory. In MATLAB, navigate to the `$DIR/install/ipopt` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
**If you see `error flag -53` when using spral, then run**
```
setenv('OMP_CANCELLATION','TRUE'); 
setenv('OMP_PROC_BIND','TRUE');
```
before using ipopt.
<a id="mexw64"></a>
# Windows x86-64
Tested with Windows 11 and MATLAB R2024b
1) Set up the environment
	- Install MSYS2 (In the following, MSYSDIR refers to the folder where MSYS2 is installed)
	- Install toolchain and compilers (meson, ninja, and hwloc are only needed if you are compiling spral)
	```
	pacman -S --needed binutils diffutils git grep make patch pkgconf
	pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran
	pacman -S --needed mingw-w64-x86_64-lapack mingw-w64-x86_64-metis
    pacman -S --needed mingw-w64-x86_64-meson mingw-w64-x86_64-ninja mingw-w64-x86_64-hwloc
	```	
	- Restart MSYS2, make sure to launch the `MSYS2 MinGW x64` shortcut and **not** the `MSYS2 MSYS` app.
	- Store current directory
	```
 	DIR=$(pwd)
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
	export INCLUDEDIR=$PREFIX/include/coin-or
 	```
**You will either need to compile at least one linear solver from the three options below (MUMPS, SPRAL, and HSL) or enable the use of the `ma57` solver shipped with MATLAB by compiling IPOPT with the `-DFUNNY_MA57_FINT -O3` flag (see step 5 below).**

2) Compile MUMPS (optional)
```
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$PREFIX"
make install
```
3) Compile SPRAL (optional)
```
cd $DIR
git clone https://github.com/ralna/spral.git spral
cd spral
meson setup build --prefix="$PREFIX" --default-library=shared -Dlibblas=blas -Dliblapack=lapack -Dtests=false -Dexamples=false
meson compile -C build
meson install -C build
```
4) Compile HSL (optional)
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
	make install
	```
5) Compile Ipopt
	- Get Ipopt code
	```
 	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
    ```
    - Configure IPOPT
      - With no extra flags passed to the configure script, IPOPT will link with MUMPS if it is available and dynamically loaded `libhsl.dll` at runtime if it is available.
      ```
      ../configure --prefix="$PREFIX"
      ```
      - To enable SPRAL in addition to the above options, use
      ```
	  ../configure --prefix="$PREFIX" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$LIBDIR -lspral -lhwloc -fopenmp -lmetis -llapack -lblas -lgfortran -lstdc++ -lm -lquadmath -lwinpthread"
      ```
      - To use dynamically loaded `libmwma57.dll` (MA57 solver that ships with MATLAB) instead of `libhsl.dll`, use (add SPRAL flags from above if SPRAL is also needed)
      ```
      ../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3"
      ```
	  **If you use this option, you need to point IPOPT to `libmwma57.dll` using (in your MATLAB script)**
      ```
 	  options.ipopt.linear_solver = 'ma57';
      options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'win64', 'libmwma57.dll');
      ```
    - Make and test IPOPT
    ```
    make
	make test
	```
	- If all tests passed, then install Ipopt
	```
	make install
	```
7) Manage dependencies on the target PC
    - Move the compiled binaries from PREFIX to LIBDIR
    ```
    cd $DIR
    mv $PREFIX/bin/* $LIBDIR
    ```
    - Automatically find and copy all MinGW-w64 dependencies
    ```
    for dll in $LIBDIR/*.dll; do
        ldd "$dll" | grep -i "/mingw64/bin" | awk '{print $3}' | while read -r dep_path; do
            cp -n "$dep_path" "$LIBDIR/"
        done
    done
    ```
7) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
 	cd $DIR
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure mingw64 is set as the C and C++ compiler. In MATLAB, navigate to the `ipopt_mex\src` folder (`$DIR\ipopt_mex\src`) and run (**replace $MSYSDIR with your MSYS2 installation folder**)
	```
	setenv('MW_MINGW64_LOC','$MSYSDIR\mingw64')
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex\src` folder and run `CompileIpoptMexLib.m`.

The complete toolbox with MUMPS and HSL linear solvers should now be in `$DIR\install`. The toolbox should be portable to any Windows computer. As long as the directory `$DIR\install\lib` is on your MATLAB path, Ipopt should work.

**IMPORTANT: SPRAL's SSIDS solver requires the environment variables `OMP_CANCELLATION` and `OMP_PROC_BIND` to be set to `TRUE` before MATLAB is launched, or it will fail with error flag -53.** On Windows this can be done via the system environment variables dialog, or from within MATLAB before solving with 
```
setenv('OMP_CANCELLATION','TRUE'); 
setenv('OMP_PROC_BIND','TRUE');
```

Test your setup by running the examples in the `$DIR\install\examples` directory. In MATLAB, navigate to the `install` directory and run
```
addpath(fullfile(pwd,'lib'));
cd examples
test_BartholomewBiggs
```
<a id="mexa64"></a>
# Linux x86-64
MATLAB on linux ships Intel MKL, which includes LAPACK. The MKL library uses 64-bit integers, but Ipopt expects 32-bit integers, which causes a segmentation fault. I could not figure out how to get dynamically linked Ipopt to use openblas instead of MKL, but statically linked Ipopt works.
1) Install linux toolchain
```
sudo apt install gcc g++ gfortran git patch wget pkg-config liblapack-dev libopenblas-dev make cmake hwloc libhwloc-dev meson ninja-build
```
2) Set up directories and copy the static blas library to the install folder
```
DIR=$(pwd)
export PREFIX=$DIR/install
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include/coin-or
mkdir install
mkdir install/lib
cp /usr/lib/x86_64-linux-gnu/libopenblas.a $LIBDIR/libopenblas.a
```
3) Compile GKlib as a static library
```
cd $DIR
git clone https://github.com/KarypisLab/GKlib.git gklib
cd gklib
make config prefix=$PREFIX cc=gcc
make install
```
4) Compile metis as a static library (compilation without the `-Wno-stringop-overflow` flag fails)
```
cd $DIR
git clone https://github.com/KarypisLab/METIS.git metis
cd metis
make config prefix=$PREFIX cc=gcc CFLAGS="-Wno-stringop-overflow"
make install
```
4) Compile MUMPS as a static library
```
cd $DIR
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
cd mumps
./get.Mumps
mkdir ./build
cd build
../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared --with-metis-lflags="$LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-metis-cflags="-I$PREFIX/include"
make install
```
5) Compile SPRAL as a static library. Since we are using static metis and GKlib libraries, we need to include the appropriate compiler flags. Tests and examples are disabled.
```
cd $DIR
git clone https://github.com/ralna/spral.git spral
cd spral
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$LIBDIR -lmetis -lGKlib -lm"
meson setup builddir --prefix="$PREFIX" --default-library=static -Dlibblas=openblas -Dliblapack=openblas -Dtests=false -Dexamples=false
meson compile -C builddir
meson install -C builddir
cp builddir/libspral.a $LIBDIR/libspral.a
```
5) Compile HSL
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
	../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared --with-metis-lflags="$LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-metis-cflags="-I$PREFIX/include"
	make install
	```
6) Compile Ipopt as a static library
	- Get Ipopt code, compile, and build Ipopt
	```
 	cd $DIR
	git clone https://github.com/coin-or/Ipopt.git
	cd Ipopt
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="$LIBDIR/libcoinmumps.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-hsl-cflags="-I$INCLUDEDIR/hsl" --with-hsl-lflags="$LIBDIR/libcoinhsl.a $LIBDIR/libopenblas.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lgfortran -lm" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="$LIBDIR/libspral.a -lhwloc -fopenmp $LIBDIR/libopenblas.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lgfortran -lstdc++ -lm" --disable-shared
	make install
	```
 	- If you run `make test`, the tests will fail since the tests themselves are not linked against `libcoinmumps.a`, but the mex file will be, so ignore the tests.
7) Compile the mex file
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

**IMPORTANT: On Linux, MATLAB ships its own C++ library which may have a version conflict with the standard library. Also, SPRAL needs some environment variables to be set. To use Ipopt, MATLAB must be launched from a terminal by running (replace `/usr/local/MATLAB/R2025a` with your MATLAB installation directory and replace `/usr/lib/x86_64-linux-gnu/` by the appropriate standard library path if needed)**
```
cd /usr/local/MATLAB/R2025a/bin
export LD_PRELOAD=$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libstdc++.so.6
export OMP_CANCELLATION=TRUE
export OMP_PROC_BIND=TRUE
./matlab
```

The complete toolbox with MUMPS, SPRAL, and HSL linear solvers should now be in `$DIR\install`. The toolbox should be portable to any Linux computer. As long as the directory `$DIR\install\lib` is on your MATLAB path, Ipopt should work.
