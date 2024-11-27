#!/bin/bash
#SBATCH --image=docker:wilkinsonnu/nuisance_project:genie_v340_geant4fsi
#SBATCH --qos=shared
#SBATCH --constraint=cpu
#SBATCH --time=1440
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
TUNE=G18_10d_00_000
NEVENTS=1000000
E_MONO=__E_MONO__
INPUTS_DIR=${PWD}/MC_inputs

## Where to temporarily save files
TEMPDIR=${SCRATCH}/${OUTFILE/.root/}_${THIS_SEED}

echo "Moving to SCRATCH: ${TEMPDIR}"
mkdir ${TEMPDIR}
cd ${TEMPDIR}

## Get the splines that are now needed...
cp ${INPUTS_DIR}/${TUNE}_v340_splines.xml.gz .

## Deal with the messenger issues...
cp -r ${INPUTS_DIR}/xml_override .

echo "Starting gevgen..."
shifter -V ${PWD}:/output --entrypoint /bin/sh -c "export GXMLPATH=xml_override; \
	gevgen -n ${NEVENTS} -t ${TARG} -p ${NU_PDG} \
	--cross-sections ${TUNE}_v340_splines.xml.gz \
	--tune ${TUNE} --seed ${THIS_SEED} \
	-e ${E_MONO} -o ${OUTFILE} &> /dev/null"

echo "Starting PrepareGENIE..."
shifter -V ${PWD}:/output --entrypoint /bin/sh -c "export GXMLPATH=xml_override; \ 
	PrepareGENIE -i $OUTFILE -m ${E_MONO} \
	-t $TARG -o ${OUTFILE/.root/_NUIS.root} &> /dev/null"

shifter -V ${PWD}:/output --entrypoint nuisflat -f GenericVectors -i GENIE:${OUTFILE/.root/_NUIS.root} -o ${OUTFILE/.root/_NUISFLAT.root} \
	-q "nuisflat_SaveSignalFlags=false" &> /dev/null
echo "Complete"

## Copy back the important files
cp ${TEMPDIR}/${OUTFILE/.root/_NUIS.root} ${OUTDIR}/.
cp ${TEMPDIR}/${OUTFILE/.root/_NUISFLAT.root} ${OUTDIR}/.

## Clean up
rm -r ${TEMPDIR}

