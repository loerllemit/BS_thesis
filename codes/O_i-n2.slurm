#!/bin/bash
## run this file using sbatch command in the Linux terminal
## e.g.:  sbatch O_i-n2.slurm
## see SlURM sbatch command online manual  for details

#SBATCH --job-name O_i-n2
#SBATCH --output O_i-n2.log
#SBATCH --ntasks=104        ## number of computing cores
#SBATCH --spread-job
#SBATCH --distribution=cyclic
#SBATCH --mem=180G
#SBATCH --partition=batch 
#SBATCH --qos=240c-1h_batch
#SBATCH --mail-user loerllemit@gmail.com
#SBATCH --mail-type ALL
#SBATCH --requeue
#SBATCH --verbose
ulimit -s unlimited

source ~/scratch1/intel/compilers_and_libraries_2019.0.117/linux/bin/compilervars.sh intel64
source ~/scratch1/intel/compilers_and_libraries_2019.0.117/linux/mkl/bin/mklvars.sh intel64
source ~/scratch1/intel/compilers_and_libraries_2019.0.117/linux/mpi/intel64/bin/mpivars.sh
export I_MPI_DEBUG=-5,pid,datetime,host,level

echo "SLURM_JOBID    = " $SLURM_JOBID
echo "SLURM_JOB_NAME = " $SLURM_JOB_NAME
echo "SLURM_NTASKS   = " $SLURM_NTASKS
echo "SLURM_NODELIST = " $SLURM_NODELIST
echo "SLURM_NNODES   = " $SLURM_NNODES
echo "SLURM_MEM_PER_NODE   = " $SLURM_MEM_PER_NODE
echo "SLURM_TASKS_PER_NODE = " $SLURM_TASKS_PER_NODE
echo "SLURMTMPDIR    = " $SLURMTMPDIR

######### QUANTUM ESPRESSO EXECUTABLES #######
path=/scratch1/christian.llemit/codes/ZnO/supercell 
prefix=O_i-n2
relaxpath=$path/relaxation
bandpath=$path/BANDS-$prefix
dospath=$path/DOS-$prefix
tempdir=/scratch1/christian.llemit/tmp/ZnO

## create file directory
mkdir -p $bandpath
mkdir -p $dospath

## create output directory
mkdir -p $tempdir/relax/$prefix/$prefix.save
mkdir -p $tempdir/$prefix/bands/$prefix.save
mkdir -p $tempdir/$prefix/dos/$prefix.save

relax=$relaxpath/relax.$prefix
scf=$bandpath/scf.$prefix
pw_bands=$bandpath/pw.bands.$prefix
bands=$bandpath/bands.$prefix
kresproj=$bandpath/kresprojwfc.$prefix
nscf=$dospath/nscf.$prefix
dos=$dospath/dos.$prefix
proj=$dospath/projwfc.$prefix
sumpdos_kres=$bandpath
sumpdos=$dospath

cat >>  $SLURM_JOB_NAME.log << EOL
Bin Library:
    $QE_PATH

Output file directory:
    $relax.out
    $scf.out
    ${pw_bands}.out
    $bands.out
    $kresproj.out
    $nscf.out
    $dos.out
    $proj.out
    $sumpdos/atom_***.dat

Temporary directory:
    $tempdir

Log file directory:
EOL

scontrol show jobid $SLURM_JOBID | grep -A4 "Command" >> $SLURM_JOB_NAME.log

echo "
=---------------------------------------------------------------=
                    Relaxation running
=---------------------------------------------------------------=
"
mpirun pw.x -nk 4 -ndiag 1  -i $relax.in > $relax.out

echo "
=---------------------------------------------------------------=
                    SCF running
=---------------------------------------------------------------=
"
mpirun pw.x -nk 4 -ndiag 1   -i $scf.in > $scf.out

echo "
=---------------------------------------------------------------=
                    BANDS-NSCF running
=---------------------------------------------------------------=
"
mpirun pw.x -nk 8 -ndiag 1 -i ${pw_bands}.in > ${pw_bands}.out

echo "
=---------------------------------------------------------------=
                    BANDS running
=---------------------------------------------------------------=
"
mpirun bands.x -nk 8 -ndiag 1 -i $bands.in > $bands.out

echo "
=---------------------------------------------------------------=
                    NSCF running
=---------------------------------------------------------------=
"
mpirun pw.x -nk 8 -ndiag 1  -i $nscf.in > $nscf.out

echo "
=---------------------------------------------------------------=
                    DOS running
=---------------------------------------------------------------=
"
mpirun dos.x -nk 8 -ndiag 1  -i $dos.in > $dos.out

echo "
=---------------------------------------------------------------=
                    PROJWFC running
=---------------------------------------------------------------=
"
mpirun projwfc.x -nk 8 -ndiag 1  -i $proj.in > $proj.out

echo "
=---------------------------------------------------------------=
                    SUMPDOS running
=---------------------------------------------------------------=
"
sumpdos.x $sumpdos/*\(Zn\)*      >  $sumpdos/atom_Zn_tot.dat
sumpdos.x $sumpdos/*\(Zn\)*\(s\) >  $sumpdos/atom_Zn_s.dat
sumpdos.x $sumpdos/*\(Zn\)*\(p\) >  $sumpdos/atom_Zn_p.dat
sumpdos.x $sumpdos/*\(Zn\)*\(d\) >  $sumpdos/atom_Zn_d.dat
sumpdos.x $sumpdos/*\(O\)*       >  $sumpdos/atom_O_tot.dat
sumpdos.x $sumpdos/*\(O\)*\(s\)  >  $sumpdos/atom_O_s.dat
sumpdos.x $sumpdos/*\(O\)*\(p\)  >  $sumpdos/atom_O_p.dat

echo "
=---------------------------------------------------------------=
                          END OF JOB
=---------------------------------------------------------------=
"

