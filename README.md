This is a slightly modified copy of Enrico Bertolazzi and Peter Carbonetto's MATLAB interface for Ipopt with **MUMPS**, **SPRAL**, and **HSL** linear solvers and detailed compilation instructions.

**Table of contents:**

IPOPT with MATLAB's MA57 linear solver
 - [MacOS arm64](#mexmaca64min)
 - [Windows x86-64](#mexw64min)
 - [Linux x86-64](#mexa64min)
   
IPOPT with MUMPS, SPRAL, and HSL linear solvers
 - [MacOS arm64](#mexmaca64)
 - [Windows x86-64](#mexw64)
 - [Linux x86-64](#mexa64)

# IPOPT with MATLAB's MA57 linear solver
This section shows how to use the `-DFUNNY_MA57_FINT` flag to compile IPOPT that dynamically loads (at runtime) the MA57 solver that is bundled with MATALB.
<a id="mexmaca64min"></a>
## Macos arm64 (homebrew)
1) Set up the environment and compile IPOPT
```
DIR=$(pwd)
export PREFIX=$DIR/install
export LIBDIR=$PREFIX/lib
export PKGDIR=$DIR/ipopt
brew update
brew upgrade
brew install bash gcc pkg-config dylibbundler
brew link --overwrite gcc
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3" LDFLAGS="-Wl,-rpath,@loader_path"
make install
brew unlink gcc
```
2) Compile the mex file in MATLAB
	- Make sure C and C++ compilers are set up in MATLAB using `mex -setup` and `mex -setup c++`.
	- Navigate to the `ipopt_mex/src` folder and run `CompileIpoptMexLib.m`.
3) Make the installation portable
```
cd $PKGDIR/lib
dylibbundler -b -of -x ipopt.mexmaca64 -d . -p @loader_path
for file in *.dylib *.mexmaca64; do
	rpath_count=$(otool -l "$file" | grep -c "path @loader_path")
	while [ "$rpath_count" -gt 1 ]; do
		install_name_tool -delete_rpath @loader_path/ "$file" 2>/dev/null || install_name_tool -delete_rpath @loader_path "$file" 2>/dev/null
		rpath_count=$((rpath_count - 1))
	done
	codesign --force --sign - "$file"
done
```
4) Set up IPOPT options to use MATLAB's MA57 by adding the following to your IPOPT options list
```
options.ipopt.linear_solver    = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'maca64', 'libmwma57.dylib');
```

<a id="mexw64min"></a>
## Windows x86-64 (MSYS2)
1) Set up the environment
	- Install MSYS2 (In the following, MSYSDIR refers to the folder where MSYS2 is installed)
	- Install toolchain and compilers
	```
	pacman -S --needed binutils diffutils git grep make patch pkgconf mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-lapack
	```	
	- Restart MSYS2, make sure to launch the `MSYS2 MinGW x64` shortcut and **not** the `MSYS2 MSYS` app.
2) Compile IPOPT
```
DIR=$(pwd)
export PREFIX=$DIR/install
export LIBDIR=$PREFIX/lib
export PKGDIR=$DIR/ipopt
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3"
make install
cd $DIR
mkdir $PKGDIR
mkdir $PKGDIR/lib
mv $PREFIX/bin/* $PKGDIR/lib
mv $LIBDIR/* $PKGDIR/lib
for dll in $PKGDIR/lib/*.dll; do
	ldd "$dll" | grep -i "/mingw64/bin" | awk '{print $3}' | while read -r dep_path; do
		cp -n "$dep_path" "$PKGDIR/lib/"
	done
done
```
3) Compile the mex file in MATLAB
	- Make sure C and C++ compilers are set up in MATLAB using
	```
 	setenv('MW_MINGW64_LOC','$MSYSDIR\mingw64')
	mex -setup 
	mex -setup c++
 	```
	- Navigate to the `ipopt_mex/src` folder and run `CompileIpoptMexLib.m`.
4) Set up IPOPT options to use MATLAB's MA57 by adding the following to your IPOPT options list
```
options.ipopt.linear_solver    = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'win64', 'libmwma57.dll');
```

<a id="mexa64min"></a>
# Linux x86-64
MATLAB on linux ships Intel MKL, which includes LAPACK. The MKL library uses 64-bit integers, but Ipopt expects 32-bit integers, which causes a segmentation fault. I could not figure out how to get dynamically linked Ipopt to use openblas instead of MKL, but statically linked Ipopt works.
1) Set up the toolchain and compile IPOPT
```
sudo apt install gcc g++ gfortran git patch wget pkg-config libopenblas-dev make cmake
DIR=$(pwd)
export PREFIX=$DIR/ipopt
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include/coin-or
mkdir ipopt
mkdir ipopt/lib
cp /usr/lib/x86_64-linux-gnu/libopenblas.a $LIBDIR/libopenblas.a
git clone https://github.com/rlkamalapurkar/ipopt_mex.git
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared
make install
```
2) Compile the mex file in MATLAB
	- Make sure C and C++ compilers are set up in MATLAB using `mex -setup` and `mex -setup c++`.
	- Navigate to the `ipopt_mex/src` folder and run `CompileIpoptMexLib.m`.

**Point IPOPT to the `ma57` solver that ships with MATLAB when you set IPOPT options.**
```
options.ipopt.linear_solver = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'glnxa64', 'libmwma57.so');
```
**IMPORTANT: On Linux, MATLAB ships its own C++ library which may have a version conflict with the standard library. To use Ipopt, MATLAB must be launched from a terminal by running (replace `/usr/local/MATLAB/R2025a` with your MATLAB installation directory, replace `/usr/lib/x86_64-linux-gnu/` by the appropriate standard library path if needed)**
```
cd /usr/local/MATLAB/R2025a/bin
export LD_PRELOAD=$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libstdc++.so.6
./matlab
```
Remove files that are no longer needed (optional)
```
cd $PREFIX
rm -rf bin include modules share
```
# IPOPT with MUMPS, SPRAL, and HSL linear solvers
<a id="mexmaca64"></a>
## MacOS arm64

1) Set up environment
	- Save current directory
	```
	DIR=$(pwd)
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
    export PKGDIR=$DIR/ipopt
	```
	- Install toolchain and compilers (meson and ninja are only needed for SPRAL)
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

2) Compile linear solvers (need at least one)
	- MUMPS
	```
	git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
	cd mumps
	./get.Mumps
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX"
	make install
	```
	- SPRAL
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
 	unset CC
	unset CXX
 	unset FC
	```
	- HSL
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

4) Compile Ipopt (remove the SPRAL flags if SPRAL is not needed)
```
cd $DIR
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" LDFLAGS="-Wl,-rpath,@loader_path" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$PREFIX/lib -lspral -L/opt/homebrew/lib -lmetis"
make install
```
If you want to use MATLAB's built-in MA57 instead of HSL, configure using
```
../configure --prefix="$PREFIX" LDFLAGS="-Wl,-rpath,@loader_path" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$PREFIX/lib -lspral -L/opt/homebrew/lib -lmetis"
```
and use the IPOPT options
```
options.ipopt.linear_solver    = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'maca64', 'libmwma57.dylib');
```
5) Compile the mex file
	- Get modified Ipopt MATLAB interface
	```
	cd $DIR
	git clone https://github.com/rlkamalapurkar/ipopt_mex.git
	```
	- Make sure C and C++ compilers are set up in MATLAB.
	```
	mex -setup 
	mex -setup c++
	```
	- Navigate to the `ipopt_mex/src` folder and run `CompileIpoptMexLib.m`.
7) Make the package portable (remove `-x libhsl.dylib` if HSL solvers are not compiled) (the for loop fixes multiple `@loader_path` entries added by `dylibbundler`)
```
cd $PKGDIR/lib
dylibbundler -b -of -x ipopt.mexmaca64 -x libhsl.dylib -d . -p @loader_path
for file in *.dylib *.mexmaca64; do
	rpath_count=$(otool -l "$file" | grep -c "path @loader_path")
	while [ "$rpath_count" -gt 1 ]; do
		install_name_tool -delete_rpath @loader_path/ "$file" 2>/dev/null || install_name_tool -delete_rpath @loader_path "$file" 2>/dev/null
		rpath_count=$((rpath_count - 1))
	done
	codesign --force --sign - "$file"
done
brew unlink gcc
```
The complete toolbox with MUMPS, SPRAL, and HSL linear solvers should now be in the `$DIR/ipopt` folder. The toolbox should be portable to any MacOS arm64 computer. As long as the directory `$DIR/ipopt/lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `$DIR/ipopt/examples` directory. **If you see `error flag -53` when using SPRAL, then run**
```
setenv('OMP_CANCELLATION','TRUE'); 
setenv('OMP_PROC_BIND','TRUE');
```
in MATLAB before using IPOPT.

<a id="mexw64"></a>
## Windows x86-64
1) Set up the environment
	- Install MSYS2 (In the following, MSYSDIR refers to the folder where MSYS2 is installed)
	- Install toolchain and compilers (meson, ninja, and hwloc are only needed if you are compiling SPRAL)
	```
	pacman -S --needed binutils diffutils git grep make patch pkgconf
	pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran
	pacman -S --needed mingw-w64-x86_64-lapack mingw-w64-x86_64-metis
    pacman -S --needed mingw-w64-x86_64-meson mingw-w64-x86_64-ninja mingw-w64-x86_64-hwloc
	```	
	- Restart MSYS2, make sure to launch the `MSYS2 MinGW x64` shortcut and **not** the `MSYS2 MSYS` app.
	- Set up directories
	```
 	DIR=$(pwd)
 	export PREFIX=$DIR/install
	export LIBDIR=$PREFIX/lib
 	export PKGDIR=$DIR/ipopt
 	```
**You will either need to compile at least one linear solver from the three options below (MUMPS, SPRAL, and HSL) or enable the use of the `ma57` solver shipped with MATLAB by compiling IPOPT with the `-DFUNNY_MA57_FINT -O3` flag (see step 5 below).**

2) Compile linear solvers (need at least one)
	- Mumps
	```
	git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git mumps
	cd mumps
	./get.Mumps
	mkdir ./build
	cd build
	../configure --prefix="$PREFIX"
	make install
	```
	- SPRAL
	```
	cd $DIR
	git clone https://github.com/ralna/spral.git spral
	cd spral
	meson setup build --prefix="$PREFIX" --default-library=shared -Dlibblas=blas -Dliblapack=lapack -Dtests=false -Dexamples=false
	meson compile -C build
	meson install -C build
	```
	- HSL
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
3) Compile Ipopt (remove the SPRAL flags if not needed)
```
cd $DIR
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$LIBDIR -lspral -lhwloc -fopenmp -lmetis -llapack -lblas -lgfortran -lstdc++ -lm -lquadmath -lwinpthread"
make install
```
If you want to use MATLAB's built-in MA57 instead of HSL, use
```
../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="-L$LIBDIR -lspral -lhwloc -fopenmp -lmetis -llapack -lblas -lgfortran -lstdc++ -lm -lquadmath -lwinpthread"
```
and the ipopt options
```
options.ipopt.linear_solver    = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'win64', 'libmwma57.dll');
```
4) Make the package portable
```
cd $DIR
mkdir $PKGDIR
mkdir $PKGDIR/lib
mv $PREFIX/bin/* $PKGDIR/lib
mv $LIBDIR/* $PKGDIR/lib
for dll in $PKGDIR/lib/*.dll; do
	ldd "$dll" | grep -i "/mingw64/bin" | awk '{print $3}' | while read -r dep_path; do
		cp -n "$dep_path" "$PKGDIR/lib/"
	done
done
```
5) Compile the mex file
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

The complete toolbox with MUMPS, SPRAL, and HSL linear solvers should now be in `$DIR\ipopt`. The toolbox should be portable to any Windows computer. As long as the directory `$DIR\ipopt\lib` is on your MATLAB path, Ipopt should work.

Test your setup by running the examples in the `$DIR/ipopt/examples` directory. **If you see `error flag -53` when using SPRAL, then run**
```
setenv('OMP_CANCELLATION','TRUE'); 
setenv('OMP_PROC_BIND','TRUE');
```
in MATLAB before using IPOPT.

<a id="mexa64"></a>
# Linux x86-64
MATLAB on linux ships Intel MKL, which includes LAPACK. The MKL library uses 64-bit integers, but Ipopt expects 32-bit integers, which causes a segmentation fault. I could not figure out how to get dynamically linked Ipopt to use openblas instead of MKL, but statically linked Ipopt works.
1) Set up the environment 
	- Install the toolchain (hwloc, meson, and ninja are only needed for SPRAL)
	```
	sudo apt install gcc g++ gfortran git patch wget pkg-config libopenblas-dev make cmake
	sudo apt install hwloc libhwloc-dev meson ninja-build
	```
	- Set up directories and copy the static blas library to the install folder
	```
	DIR=$(pwd)
	export PREFIX=$DIR/ipopt
	export LIBDIR=$PREFIX/lib
	export INCLUDEDIR=$PREFIX/include/coin-or
	mkdir ipopt
	mkdir ipopt/lib
	cp /usr/lib/x86_64-linux-gnu/libopenblas.a $LIBDIR/libopenblas.a
	```
2) Compile linear solvers (need atleast one)
    - Compile GKlib as a static library
    ```
    cd $DIR
    git clone https://github.com/KarypisLab/GKlib.git gklib
    cd gklib
    make config prefix=$PREFIX cc=gcc
    make install
    ```
    - Compile metis as a static library (compilation without the `-Wno-stringop-overflow` flag fails)
    ```
    cd $DIR
    git clone https://github.com/KarypisLab/METIS.git metis
    cd metis
    make config prefix=$PREFIX cc=gcc CFLAGS="-Wno-stringop-overflow"
    make install
    ```
    - Compile MUMPS as a static library
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
    - Compile SPRAL as a static library. Since we are using static metis and GKlib libraries, we need to include the appropriate compiler flags. Tests and examples are disabled.
    ```
    cd $DIR
    git clone https://github.com/ralna/spral.git spral
    cd spral
    export CFLAGS="-I$PREFIX/include"
    export CXXFLAGS="-I$PREFIX/include"
    export LDFLAGS="-L$LIBDIR -lmetis -lGKlib -lm"
    meson setup build --prefix="$PREFIX" --default-library=static -Dlibblas=openblas -Dliblapack=openblas -Dtests=false -Dexamples=false
    meson compile -C build
    meson install -C build
    cp build/libspral.a $LIBDIR/libspral.a
    ```
    - Compile HSL as a static library.
      
	    -- Get COIN-OR Tools project ThirdParty-HSL
	    ```
	    cd $DIR
	    git clone https://github.com/coin-or-tools/ThirdParty-HSL.git hsl
	    ```
	    -- Download Coin-HSL Full from https://www.hsl.rl.ac.uk/ipopt/ and unpack the HSL sources archive, move and rename the resulting directory so that it becomes `hsl/coinhsl`.
	    -- In ThirdParty-HSL, configure, build, and install the HSL sources
	    ```
	    cd hsl
	    mkdir ./build
	    cd build
	    ../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --disable-shared --with-metis-lflags="$LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-metis-cflags="-I$PREFIX/include"
	    make install
	    ```

3) Compile Ipopt as a static library (the lapack flag is always needed and flags for linear solvers that you did not compile need to be removed)
```
cd $DIR
git clone https://github.com/coin-or/Ipopt.git ipopt_src
cd ipopt_src
mkdir ./build
cd build
../configure --prefix="$PREFIX" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="$LIBDIR/libcoinmumps.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-hsl-cflags="-I$INCLUDEDIR/hsl" --with-hsl-lflags="$LIBDIR/libcoinhsl.a $LIBDIR/libopenblas.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lgfortran -lm" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="$LIBDIR/libspral.a -lhwloc -fopenmp $LIBDIR/libopenblas.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lgfortran -lstdc++ -lm" --disable-shared
make install
```
If you want to use MATLAB's built-in MA57 library instead of HSL, use
```
../configure --prefix="$PREFIX" CXXFLAGS="-DFUNNY_MA57_FINT -O3" CFLAGS="-DFUNNY_MA57_FINT -O3" --with-lapack-lflags="$LIBDIR/libopenblas.a -lm" --with-mumps-cflags="-I$INCLUDEDIR/mumps" --with-mumps-lflags="$LIBDIR/libcoinmumps.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lm" --with-spral-cflags="-I$PREFIX/include" --with-spral-lflags="$LIBDIR/libspral.a -lhwloc -fopenmp $LIBDIR/libopenblas.a $LIBDIR/libmetis.a $LIBDIR/libGKlib.a -lgfortran -lstdc++ -lm" --disable-shared
```
and the ipopt options
```
options.ipopt.linear_solver = 'ma57';
options.ipopt.hsllib = fullfile(matlabroot, 'bin', 'glnxa64', 'libmwma57.so');
```

4) Compile the mex file
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

**IMPORTANT: On Linux, MATLAB ships its own C++ library which may have a version conflict with the standard library. To use Ipopt, MATLAB must be launched from a terminal by running (replace `/usr/local/MATLAB/R2025a` with your MATLAB installation directory, replace `/usr/lib/x86_64-linux-gnu/` by the appropriate standard library path if needed, and remove the OMP_ flags if SPRAL is not used)**
```
cd /usr/local/MATLAB/R2025a/bin
export LD_PRELOAD=$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libstdc++.so.6
export OMP_CANCELLATION=TRUE
export OMP_PROC_BIND=TRUE
./matlab
```
Remove files that are no longer needed (optional)
```
cd $PREFIX
rm -rf bin include modules share
```

The complete toolbox with MUMPS, SPRAL, and HSL linear solvers (if compiled) should now be in `$DIR\ipopt`. The toolbox should be portable to any Linux computer. As long as the directory `$DIR\ipopt\lib` is on your MATLAB path, Ipopt should work.
