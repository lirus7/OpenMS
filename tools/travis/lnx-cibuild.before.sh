#!/bin/bash

function build_contrib {
  cmake . -DBUILD_TYPE=$1

  if [ $? -ne 0 ]; then
    # we give it another try
    echo "1st attempt to build $1 failed .. retry"
    cmake . -DBUILD_TYPE=$1 -DNUMBER_OF_JOBS=4

    if [ $? -ne 0 ]; then
      echo "2nd attempt to build $1 failed .. abort"
      exit $?
    fi
  fi
}

# Which one does travis like and let us use? We need to be consistent as cmake
# tends to have a different opinion...
which pip
which python

/opt/python/2.7.13/bin/pip install -U setuptools
/opt/python/2.7.13/bin/pip install -U pip
/opt/python/2.7.13/bin/pip install -U nose
/opt/python/2.7.13/bin/pip install -U numpy
/opt/python/2.7.13/bin/pip install -U wheel
/opt/python/2.7.13/bin/pip install -U Cython

git clone -b feature/pxd_files https://git@github.com/hroest/autowrap.git
pushd autowrap
/opt/python/2.7.13/bin/python setup.py install
popd

/opt/python/2.7.13/bin/python -c "import autowrap; print autowrap"
/opt/python/2.7.13/bin/python -c "import Cython; print Cython"

# fetch contrib and build seqan
git clone git://github.com/OpenMS/contrib/
pushd contrib

# we build seqan as the versions shipped in Ubuntu are not recent enough
build_contrib SEQAN

# we build WildMagic
build_contrib WILDMAGIC

# we build Eigen as the versions shipped in Ubuntu are not recent enough
build_contrib EIGEN

# we build Sqlite as the versions shipped in Ubuntu are not recent enough
build_contrib SQLITE

# leave contrib
popd

# build custom cppcheck if we want to perform style tests
if [ "${ENABLE_STYLE_TESTING}" = "ON" ]; then
  git clone git://github.com/danmar/cppcheck.git
  pushd cppcheck
  git checkout 1.65
  CXX=clang++ make SRCDIR=build CFGDIR=`pwd`/cfg HAVE_RULES=yes -j4
  popd
else
  # regular builds .. get the search engine executables via githubs SVN interface (as git doesn't allow single folder checkouts)
  svn export --force https://github.com/OpenMS/THIRDPARTY/trunk/Linux/64bit/ _thirdparty
  svn export --force https://github.com/OpenMS/THIRDPARTY/trunk/All/ _thirdparty
fi


