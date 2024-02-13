# HCP Pipelines ICAFIX subdirectory

This directory contains [HCP] and [Washington University] official versions of
scripts related to [FSL]'s [FIX], a tool for denoising of fMRI data using
spatial ICA (i.e., melodic) followed by automatic classification of components into
'signal' and 'noise' components.

The scripts here support both "single-run" FIX and "multi-run" FIX (MR-FIX).
MR-FIX concatenates a set of fMRI runs so as to provide more data to the
spatial ICA, to yield better separation of 'signal' and 'noise' components.

A typical workflow would be:
* Run single or multi-run FIX (see Examples/Scripts/IcaFixProcessingBatch.sh)
* Run PostFix to generate Workbench scenes for reviewing the FIX classification (see
  Examples/Scripts/PostFixBatch.sh)
* Review those scenes to QC the quality of the FIX classification. If you are
  satisfied with the quality, proceed to use the cleaned data.
* If you feel reclassification of certain components is necessary, enter the
  appropriate component numbers that you feel were mis-classified into the
  ReclassifyAsSignal.txt or ReclassifyAsNoise.txt files (as appropriate). THEN:
  * Run ApplyHandReClassifications (see
  Examples/Scripts/ApplyHandReClassificationsBatch.sh) [NOTE: If you reclassify
  components, be aware that the Signal/Noise labels displayed in the scenes
  generated by PostFix will NOT reflect the reclassification].
  * Run ReApplyFixPipeline.sh (for single-run FIX) or
  ReApplyFixMultiRunPipeline.sh (for multi-run FIX) to actually re-clean the data using
  the manual ("hand") reclassification. It is obviously important not to forget this
  final step (if you want the cleaned data to reflect the component reclassification)!

* The ReApplyFixPipeline.sh and ReApplyFixMultiRunPipeline.sh scripts serve a second
  role -- they are also the mechanism by which cleaned files are generated for
  an alternative surface registration (e.g., 'MSMAll'). Although, note that in this
  situation the ReApplyFix scripts are invoked automatically by the
  DeDriftAndResamplePipeline.

Note that `FSL_FIXDIR` environment variable needs to be set to the location of
your [FIX] installation. You may need to modify your FIX installation to fit
your compute environment. In particular, the `${FSL_FIXDIR}/settings.sh` file
likely needs modification. (The settings.sh.WUSTL_CHPC2 file in this directory
is the settings.sh file that is used on the WUSTL "CHPC2" cluster).

# Notes on MATLAB usage

Most of the scripts in this directory at some point rely on functions written
in MATLAB. This MATLAB code can be executed in 3 possible modes:

0. Compiled Matlab -- more on this below
1. Interpreted Matlab -- probably easiest to use, if it is an option for you
2. Interpreted Octave -- an alternative to Matlab, although:
	1. You'll need to configure various helper functions (such as `${HCPPIPEDIR/global/matlab/{ciftiopen.m, ciftisave.m}` and `$FSLDIR/etc/matlab/{read_avw.m, save_avw.m}`) to work within your Octave environment.
	2. Default builds of Octave are limited in the amount of memory and array dimensions that are supported. Especially in the context of multi-run FIX, you will likely need to build a version of Octave that supports increased memory, more on this below.

### Building Octave with support for large matrices

Several dependencies of octave also need to be built with nonstandard options to enable large matrices.  Other people have already made build recipes that automate most of this, our slightly altered version of one is here:

https://github.com/coalsont/GNU-Octave-enable-64

You will need to install most of the build dependencies of octave before using it (however, having a default build of libsuitesparse installed can result in a non-working octave executable, one effective solution is to uninstall the libsuitesparse headers):

```bash
#ubuntu 14.04 recipe
apt-add-repository ppa:ubuntu-toolchain-r/test
apt-get update && apt-get build-dep -y --no-install-recommends octave && apt-get install -y --no-install-recommends git cmake libpq-dev gcc-6 gfortran-6 g++-6 zip libosmesa6-dev libsundials-serial-dev bison && apt-get remove -y libsuitesparse-dev && apt-get autoremove -y
git clone https://github.com/coalsont/GNU-Octave-enable-64.git && cd GNU-Octave-enable-64 && make INSTALL_DIR=/usr/local CC=gcc-6 FC=gfortran-6 CXX=g++-6 && ldconfig
```

### Control of Matlab mode within specific scripts

#### hcp_fix and hcp_fix_multi_run

The Matlab mode is controlled by the `FSL_FIX_MATLAB_MODE` environment variable within the
`${FSL_FIXDIR}/settings.sh` file.
[Note: If the `${FSL_FIXDIR}/settings.sh` file is set up appropriately (i.e., FIX v1.068 or later),
it should respect the value of `FSL_FIX_MATLAB_MODE` in your current environment].

#### ReApplyFixPipeline, ReApplyFixMultiRunPipeline, and PostFix

The Matlab mode is controlled via the `--matlab-run-mode` input argument
(defaults to mode 1, interpreted Matlab).

#### ApplyHandReClassifications

Does not use any Matlab code.

### Support for compiled Matlab within specific scripts

If your cluster compute environment doesn't support the use of interpreted
MATLAB, your options are either to use compiled MATLAB or Octave.

#### hcp_fix, ReApplyFixPipeline

The `FSL_FIX_MCRROOT` environment variable in the `${FSL_FIXDIR}/settings.sh`
file must be set to the "root" of the directory containing the "MATLAB
Compiler Runtime" (MCR) version for the MATLAB release under which the FIX
distribution was compiled (i.e., 'R2014a' for FIX version 1.067; 'R2017b' for
FIX version 1.06.12 and later. Note that due to a bug in the compilation of
GIFTI I/O functionality, compiled Matlab mode is not functional for FIX
versions 1.068 - 1.06.11).
[Note that the `${FSL_FIXDIR}/settings.sh` file automatically determines the MCR version number].

#### hcp_fix_multi_run, ReApplyFixMultiRunPipeline

* First, `${FSL_FIXDIR}/settings.sh` must be set up correctly.
* Second, the `MATLAB_COMPILER_RUNTIME` environment variable must to set to
the directory containing the 'R2017b/v93' MCR, which is the version of the MCR
used to compile the MATLAB functions specific to the HCPpipelines (as opposed
to the FIX distribution).

i.e.,

	export MATLAB_COMPILER_RUNTIME=/export/matlab/MCR/R2017b/v93

#### PostFix

The `MATLAB_COMPILER_RUNTIME` environment variable must be set to the
directory containing the 'R2017b/v93' MCR (i.e., same as with
`hcp_fix_multi_run` and `ReApplyFixMultiRunPipeline`.


# Supplemental instructions for installing FIX

Some effort (trial and error) is required to install the versions of R packages specified on the [FIX User Guide] page, so below are instructions obtained from working installations of FIX.  Note that [FIX]'s minimum supported version of R is 3.3.0.

### Tested on 3.3.x, 3.4.x, and 3.5.x

```bash
#superuser permissions are required for most steps as written, you can use "sudo -s" to obtain a root-privileged shell

#PICK ONE:
#1) fedora/redhat/centos dependencies for R packages
yum -y groupinstall 'Development Tools'
yum -y install blas-devel lapack-devel qt-devel mesa-libGLU openssl-devel libssh-devel

#2) debian/ubuntu dependencies
apt-get update && apt-get install -y build-essential libblas-dev liblapack-dev qt5-default libglu1-mesa libcurl4-openssl-dev libssl-dev libssh2-1-dev --no-install-recommends

#R >= 3.3.0 must already be installed, if you have the R-recommended R packages installed you can probably skip "lattice" through "KernSmooth"
PACKAGES="lattice_0.20-38 Matrix_1.2-15 survival_2.43-3 MASS_7.3-51.1 class_7.3-14 codetools_0.2-16 KernSmooth_2.23-15 mvtnorm_1.0-8 modeltools_0.2-22 zoo_1.8-4 sandwich_2.5-0 strucchange_1.5-1 TH.data_1.0-9 multcomp_1.4-8 coin_1.2-2 bitops_1.0-6 gtools_3.8.1 gdata_2.18.0 caTools_1.17.1.1 gplots_3.0.1 kernlab_0.9-24 ROCR_1.0-7 party_1.0-25 e1071_1.6-7 randomForest_4.6-12"
MIRROR="http://cloud.r-project.org"

for package in $PACKAGES
do
    wget "$MIRROR"/src/contrib/Archive/$(echo "$package" | cut -f1 -d_)/"$package".tar.gz || \
        wget "$MIRROR"/src/contrib/"$package".tar.gz
    R CMD INSTALL "$package".tar.gz
done
```

<!-- References -->

[HCP]: http://www.humanconnectome.org
[Washington University]: http://www.wustl.edu
[FSL]: http://fsl.fmrib.ox.ac.uk/fsl/fslwiki
[FIX]: http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FIX
[FIX User Guide]: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FIX/UserGuide