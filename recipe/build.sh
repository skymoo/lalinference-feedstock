#!/bin/bash
#
# Configure, build, and test a LALSuite subpackage (e.g. `lal`), including
# the SWIG interface files, but without any actual language bindings
#

set -e

# only link libraries we actually use
export GSL_LIBS="-L${PREFIX}/lib -lgsl"

# select MPI implementation
if [[ "${mpi}" == "nompi" ]]; then
	MPI_CONFIG_ARGS="--disable-mpi"
else
	MPI_CONFIG_ARGS="--enable-mpi"
fi

# configure
./configure \
	--prefix="${PREFIX}" \
	--disable-doxygen \
	--disable-gcc-flags \
	--disable-python \
	--disable-swig-octave \
	--disable-swig-python \
	--enable-help2man \
	--enable-openmp \
	--enable-silent-rules \
	--enable-swig-iface \
	${MPI_CONFIG_ARGS} \
;

# build
make -j ${CPU_COUNT}

# check
make -j ${CPU_COUNT} check

# install
make -j ${CPU_COUNT} install

# -- create activate/deactivate scripts
PKG_NAME_UPPER=$(echo ${PKG_NAME} | awk '{ print toupper($0) }')

# activate.sh
ACTIVATE_SH="${PREFIX}/etc/conda/activate.d/activate_${PKG_NAME}.sh"
mkdir -p $(dirname ${ACTIVATE_SH})
cat > ${ACTIVATE_SH} << EOF
#!/bin/bash
export CONDA_BACKUP_${PKG_NAME_UPPER}_DATADIR="\${${PKG_NAME_UPPER}_DATADIR:-empty}"
export ${PKG_NAME_UPPER}_DATADIR="/opt/anaconda1anaconda2anaconda3/share/${PKG_NAME}"
EOF
# deactivate.sh
DEACTIVATE_SH="${PREFIX}/etc/conda/deactivate.d/deactivate_${PKG_NAME}.sh"
mkdir -p $(dirname ${DEACTIVATE_SH})
cat > ${DEACTIVATE_SH} << EOF
#!/bin/bash
if [ "\${CONDA_BACKUP_${PKG_NAME_UPPER}_DATADIR}" = "empty" ]; then
	unset ${PKG_NAME_UPPER}_DATADIR
else
	export ${PKG_NAME_UPPER}_DATADIR="\${CONDA_BACKUP_${PKG_NAME_UPPER}_DATADIR}"
fi
unset CONDA_BACKUP_${PKG_NAME_UPPER}_DATADIR
EOF
