#!/bin/bash
#SBATCH --image=docker:wilkinsonnu/nuisance_project:genie_v3.2.0
#SBATCH --qos=shared
#SBATCH --constraint=cpu
#SBATCH --time=2880
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=4GB

## These change for each job
THIS_SEED=__THIS_SEED__
FILE_NUM=__FILE_NUM__
NU_PDG=__NU_PDG__
OUTDIR=__OUTDIR__
TARG=__TARG__
OUTFILE=__OUTFILE__

## Output file name
TUNE=G18_10X_00_000
NEVENTS=__NEVENTS__
E_MONO=__E_MONO__
INPUTS_DIR=${PWD}/MC_inputs

## Where to temporarily save files
TEMPDIR=${SCRATCH}/${OUTFILE/.root/}_${THIS_SEED}

echo "Moving to SCRATCH: ${TEMPDIR}"
mkdir ${TEMPDIR}
cd ${TEMPDIR}

## Get the splines that are now needed...
cp ${INPUTS_DIR}/${TUNE}_v320_splines.xml.gz .

## Get the noFSI override
cp -r ${INPUTS_DIR}/${TUNE}_CONFIG .

## Need to set the GXMLPATH I think
echo "Starting gevgen..."
shifter -V ${PWD}:/output --entrypoint gevgen -n ${NEVENTS} -t ${TARG} -p ${NU_PDG} \
	-xml-path ${TUNE}_CONFIG \
	--cross-sections ${TUNE}_v320_splines.xml.gz \
	--tune G18_10a_00_000 --seed ${THIS_SEED} \
	-e ${E_MONO} -o ${OUTFILE}

echo "Starting PrepareGENIE..."
shifter -V ${PWD}:/output --entrypoint PrepareGENIE -i $OUTFILE -m ${E_MONO} \
	-t $TARG -o ${OUTFILE/.root/_NUIS.root}

shifter -V ${PWD}:/output --entrypoint nuisflat -f GenericVectors -i GENIE:${OUTFILE/.root/_NUIS.root} -o ${OUTFILE/.root/_NUISFLAT.root} -q "nuisflat_SaveSignalFlags=false"
echo "Complete"

## Copy back the important files
cp ${TEMPDIR}/${OUTFILE/.root/_NUIS.root} ${OUTDIR}/.
cp ${TEMPDIR}/${OUTFILE/.root/_NUISFLAT.root} ${OUTDIR}/.

## Clean up
rm -r ${TEMPDIR}

