#!/bin/bash

## If I want to pile more on later
FIRST_JOB=0
LAST_JOB=5

## NEVENTS only affects the GENIE jobs
## Default is 1000000, but for some energies, GENIE is very slow, so need to reduce the number
## (Increase the number of jobs to keep the same stats
NEVENTS=500000
NEVTTAG=500k

NU_PDG_ARR=( 14 -14 -12 12 16 -16 )

E_MONO_ARR=( 0.25 0.5 0.75 1 2 3 4 5 7.5 10 )

GEN_ARR=( GENIEv3_G18_10a_00_000 \
    	  GENIEv3_G18_10b_00_000 \
          GENIEv3_G18_10c_00_000 \
          GENIEv3_G18_10d_00_000 \
          GENIEv3_CRPA21_04a_00_000 \
	  GENIEv3_G21_11a_00_000 \
          GENIEv3_AR23_20i_00_000 \
	  NUWRO_SF ) #\
#          NEUT562 )

TARG="1000180400[1.00]"
SHORT_TARG="Ar40"

TARG="1000080160[0.8889],1000010010[0.1111]"
SHORT_TARG="H2O"

## Loop over templates
for GENERATOR in "${GEN_ARR[@]}"; do
    for E_MONO in "${E_MONO_ARR[@]}"; do
	for NU_PDG in "${NU_PDG_ARR[@]}"; do
	
	    OUTDIR="${CFS}/nuisance/MC_mono/${GENERATOR}"
	    
	    if [ ! -d "${OUTDIR}" ]; then
		mkdir -p ${OUTDIR}
	    fi

	    ## Let's not bother with nutau under threshold
	    if [[ "$NU_PDG" == "16" || "$NU_PDG" == "-16" ]]; then
		if (( $(echo "$E_MONO < 3.5" | bc -l) )); then
		    continue
		fi
	    fi
	    
	    TEMPLATE=batch_${GENERATOR}_TEMPLATE.sh
	    
	    for JOB in $(seq ${FIRST_JOB} ${LAST_JOB}); do
		
		printf -v PADJOB "%04d" $JOB
		
		OUTFILE="MONO_${NU_PDG}_${SHORT_TARG}_${E_MONO}GeV_${GENERATOR}_${NEVTTAG}_${PADJOB}.root"

		## Check if file has already been processed
		# OUTFILE_PATTERN=${OUTFILE//${NEVTTAG}/*}
		# if [ -f ${OUTDIR}/${OUTFILE/.root/_NUISFLAT.root} ]; then
		if [ -f ${OUTDIR}/MONO_${NU_PDG}_${SHORT_TARG}_${E_MONO}GeV_${GENERATOR}_*_${PADJOB}_NUISFLAT.root ]; then
		    continue
		fi;
		echo "Processing ${OUTFILE}"

		## Work around for nuwro and NEUT
		E_MONO_FIX=${E_MONO}
		if [[ "${GENERATOR}" == *"NEUT"* || "${GENERATOR}" == *"NUWRO"* ]]; then
		    E_MONO_FIX=$(echo "$E_MONO * 1000" | bc)
		fi;
		
		## Copy the template
		THIS_TEMP=${TEMPLATE/_TEMPLATE/_${NU_PDG}_${E_MONO}GeV_${PADJOB}}
		cp ${TEMPLATE} ${THIS_TEMP}
		
		## Set everything important...
		sed -i "s/__THIS_SEED__/${RANDOM}/g" ${THIS_TEMP}
		sed -i "s/__FILE_NUM__/${PADJOB}/g" ${THIS_TEMP}
		sed -i "s/__NU_PDG__/${NU_PDG}/g" ${THIS_TEMP}
		sed -i "s/__OUTDIR__/${OUTDIR//\//\\/}/g" ${THIS_TEMP}
		sed -i "s/__OUTFILE__/${OUTFILE}/g" ${THIS_TEMP}
		sed -i "s/__TARG__/${TARG}/g" ${THIS_TEMP}
		sed -i "s/__E_MONO__/${E_MONO_FIX}/g" ${THIS_TEMP}
                sed -i "s/__NEVENTS__/${NEVENTS}/g" ${THIS_TEMP}

		echo "Submitting ${THIS_TEMP}"
		
		## Submit the template
		sbatch ${THIS_TEMP}
		
		## No need to delete, so done
		rm ${THIS_TEMP}
	    done
	done
    done
done
