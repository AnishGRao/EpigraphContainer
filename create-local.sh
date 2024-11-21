#!/bin/bash

export DOCKER_BUILDKIT=1 
docker build --file Dockerfile --output out .

export LD_LIBRARY_PATH=$(pwd)/out/Epigraph/build/solvers/osqp/out/:$(pwd)/out/Epigraph/build/solvers/ecos/:$(pwd)/out/Epigraph/build/:$(pwd)/out/Epigraph/build/solvers/osqp/lin_sys/direct/qdldl/qdldl_sources/out

g++-8 -std=c++17 -Dosqp_EXPORTS \
    -DENABLE_ECOS=TRUE \
    -DENABLE_OSQP=TRUE \
    -I out/Epigraph/solvers/ecos/include/ \
    -I out/Epigraph/solvers/osqp/lin_sys/direct/qdldl \
    -I out/Epigraph/solvers/osqp/lin_sys/direct/qdldl/qdldl_sources/include \
    -I out/Epigraph/solvers/osqp/lin_sys/direct/pardiso \
    -I out/Epigraph/solvers/osqp/include \
    -I out/Epigraph/include/ \
    -I out/Epigraph/include/wrappers/ \
    -I out/Epigraph/solvers/osqp/lin_sys \
    -I out/eigen/ \
    -I out/qdldl_include/ \
    -I out/osqp_include/ \
    -I out/ecos_include/ \
    -I out/Epigraph/solvers/ecos/external/SuiteSparse_config  \
    -L out/Epigraph/build/solvers/osqp/out/ \
    -L out/Epigraph/build/solvers/ecos/ \
    -L out/Epigraph/build/  \
    -L out/Epigraph/build/solvers/osqp/lin_sys/direct/qdldl/qdldl_sources/out  \
    -lqdldl \
    -lepigraph \
    -losqp \
    -lecos \
    -O3 \
    -fPIC test.cc