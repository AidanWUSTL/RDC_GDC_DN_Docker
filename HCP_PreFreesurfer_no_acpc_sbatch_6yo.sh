#!/bin/bash

# create a submital script for each subject in the list
# this script assumes that no or wrong AP/PA spin echo field maps were collected and so uses bval = 5 instead

SUBJLIST=$1
WD=$PWD;

for Subject in `more ${SUBJLIST}`; do
	cd ${Subject}
# Start making a .sh file to submit to queue
	QUEUEFILE=${WD}/${Subject}/${Subject}_HCP_PreFreesurfer_no_acpc_sbatch.sh
	echo "#!/bin/bash" > ${QUEUEFILE}
	echo "#SBATCH --job-name=${Subject}_HCP_PreFreesurfer_sbatch_no_acpc" >> ${QUEUEFILE}
	echo "#SBATCH --time=3:0:0"  >> ${QUEUEFILE}
	echo "#SBATCH --nodelist=node[18]" >> ${QUEUEFILE}
	echo "#SBATCH --partition=tier2_cpu" >> ${QUEUEFILE}
	echo "#SBATCH --nodes=1" >> ${QUEUEFILE}
	echo "#SBATCH --account=christopher_smyser" >> ${QUEUEFILE}  #DO NOT NEED FOR RDC(free)


	echo "module load workbench/1.5.0"				>> ${QUEUEFILE}
	echo "module load fsl/6.0.4"					>> ${QUEUEFILE}
	echo "conda init bash"						>> ${QUEUEFILE}
	echo "conda activate python_383"				>> ${QUEUEFILE}
	#echo "source /export/anaconda/anaconda3/anaconda3-2020.07/bin/activate" 		>> ${QUEUEFILE}
	#echo "source activate python_383" 					>> ${QUEUEFILE}		# we want to be ABSOLUTELY sure my python comes first  : )  Thanks Sri!
	echo ""									>> ${QUEUEFILE}
	echo "echo ${PATH}"
	echo "" >> ${QUEUEFILE}
	echo "" >> ${QUEUEFILE}

	echo "Subject=${Subject}"						>> ${QUEUEFILE}
	Subject=${Subject}
	echo "pixdim=0.8"								>> ${QUEUEFILE}
	pixdim=0.8
	echo "SEUnwarpDir=y"							>> ${QUEUEFILE}	# in our protocol Rich told Shannon the T1 is collected AP, so y-  : ) # update ~2/10/2020 Mike Harms said this should be y because this only has to do with the
											# field maps themselves and the overall direction they were collected in, not the direction
											# the structural data were collected in.  So I guess they didn't do 2 variables (i.e. y/y-)
											# because in order for spin echo field maps to even work, you have to have pairs??
	SEUnwarpDir=y
	echo "GDCoeffs=/home/loseille/joerobotninjas/bin/HCPpipelines-4.1.3/global/config/coeff_AS82_Prisma.grad"	>> ${QUEUEFILE}
	GDCoeffs=/home/loseille/joerobotninjas/bin/HCPpipelines-4.1.3/global/config/coeff_AS82_Prisma.grad
	echo "DistortionCorrection=TOPUP"									>> ${QUEUEFILE}
	DistortionCorrection=TOPUP
	echo "UseJacobian=True"											>> ${QUEUEFILE}
	UseJacobian=True

	# get the T1/T2/SEFM locations and then use them in the file
	T1_loc=`find ./ -name "*T1w*json" -print | cut -d "." -f2`
	T2_loc=`find ./ -name "*T2w*json" -print | cut -d "." -f2`
	SEFM_PA=`find ./ -name "*DistortionMap*PA*json" -print | cut -d "." -f2 | head -1`			#  I am adding the "head" portion so I only grab the first one, I only downloaded the first set for this
												# purpose, but when I have to have specific bold runs with specific field maps then it is going to be a
												# a little different and will likely need to loop within a loop - TUR-DUCK-IN!!
	SEFM_AP=`find ./ -name "*DistortionMap*AP*json" -print | cut -d "." -f2 | head -1`

	echo "T1w=${WD}/${Subject}${T1_loc}.nii.gz"					>> ${QUEUEFILE}
	T1w=${WD}/${Subject}${T1_loc}.nii.gz
	echo "T2w=${WD}/${Subject}${T2_loc}.nii.gz"					>> ${QUEUEFILE}
	T2w=${WD}/${Subject}${T2_loc}.nii.gz
	echo "SEFM_Pos=${WD}/${Subject}${SEFM_PA}.nii.gz"					>> ${QUEUEFILE}
	SEFM_Pos=${WD}/${Subject}${SEFM_PA}.nii.gz
	echo "SEFM_Neg=${WD}/${Subject}${SEFM_AP}.nii.gz"					>> ${QUEUEFILE}
	SEFM_Neg=${WD}/${Subject}${SEFM_AP}.nii.gz

	es=`cat ${WD}"/"${Subject}${SEFM_PA}.json | grep EffectiveEchoSpacing | cut -d ":" -f2 | cut -d "," -f1 | cut -d " " -f2`
	echo "EchoSpacing=${es}"						>> ${QUEUEFILE}
	EchoSpacing=${es}

	t1wss=`cat ${WD}"/"${Subject}${T1_loc}.json | grep Dwell | cut -d ":" -f2 | cut -d "," -f1`
	t1wss=`printf '%0.08f' ${t1wss}`
	echo "T1samplespacing=${t1wss}"						>> ${QUEUEFILE}
	T1samplespacing=${t1wss}
	t2wss=`cat ${WD}"/"${Subject}${T2_loc}.json | grep Dwell | cut -d ":" -f2 | cut -d "," -f1`
	t2wss=`printf '%0.08f' ${t2wss}`
	echo "T2samplespacing=${t2wss}"						>> ${QUEUEFILE}
	T2samplespacing=${t2wss}

	echo ""									>> ${QUEUEFILE}

	#echo "module load workbench/1.5.0 fsl/6.0.4 python/3.8.3"				>> ${QUEUEFILE}
	#echo "source activate python_383"					>> ${QUEUEFILE}		# we want to be ABSOLUTELY sure my python comes first  : )  Thanks Sri!
	#echo ""									>> ${QUEUEFILE}
	#echo "echo ${PATH}"							>> ${QUEUEFILE}	

	export HCPPIPEDIR=/home/`whoami`/joerobotninjas/bin/HCPpipelines-4.1.3 
	export HCPPIPEDIR_Global=/home/`whoami`/joerobotninjas/bin/HCPpipelines-4.1.3/global/scripts
	echo "export HCPPIPEDIR=/home/`whoami`/joerobotninjas/bin/HCPpipelines-4.1.3" >> ${QUEUEFILE}
	echo "export HCPPIPEDIR_Global=/home/`whoami`/joerobotninjas/bin/HCPpipelines-4.1.3/global/scripts" >> ${QUEUEFILE}

	echo "source ${HCPPIPEDIR}/Examples/Scripts/SetUpHCPPipeline.sh" >> ${QUEUEFILE}

	echo ${HCPPIPEDIR_Templates}					>> ${QUEUEFILE}


	echo ""									>> ${QUEUEFILE}
	echo ""									>> ${QUEUEFILE}

	echo "TopUpConfig=${HCPPIPEDIR}/global/config/b02b0.cnf"						>> ${QUEUEFILE}
	TopUpConfig=${HCPPIPEDIR}/global/config/b02b0.cnf

	echo ""									>> ${QUEUEFILE}
	echo ""									>> ${QUEUEFILE}

	echo ""									>> ${QUEUEFILE}
	echo -e "${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline_neonate_no_acpc.sh --path=${WD} \
	--subject=${Subject} \
	--t1=${T1w} \
	--t2=${T2w} \
	--t1template=\${HCPPIPEDIR_Templates}/MNI152_T1_${pixdim}mm.nii.gz \
	--t1templatebrain=\${HCPPIPEDIR_Templates}/MNI152_T1_${pixdim}mm_brain.nii.gz \
	--t1template2mm=\${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz \
	--t2template=\${HCPPIPEDIR_Templates}/MNI152_T2_${pixdim}mm.nii.gz \
	--t2templatebrain=\${HCPPIPEDIR_Templates}/MNI152_T2_${pixdim}mm_brain.nii.gz \
	--t2template2mm=\${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz \
	--templatemask=\${HCPPIPEDIR_Templates}/MNI152_T1_${pixdim}mm_brain_mask.nii.gz \
	--template2mmmask=\${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz \
	--brainsize=150 \
	--fnirtconfig=${HCPPIPEDIR}/global/config/T1_2_MNI152_2mm.cnf \
	--fmapmag=NONE \
	--fmapphase=NONE \
	--fmapgeneralelectric=NONE \
	--echodiff=NONE \
	--SEPhaseNeg=${SEFM_Neg} \
	--SEPhasePos=${SEFM_Pos} \
	--seechospacing=${EchoSpacing} \
	--seunwarpdir=${SEUnwarpDir} \
	--t1samplespacing=${T1samplespacing} \
	--t2samplespacing=${T2samplespacing} \
	--unwarpdir=z \
	--gdcoeffs=${GDCoeffs} \
	--avgrdcmethod=${DistortionCorrection} \
	--topupconfig=\${TopUpConfig} \
	--usejacobian=${UseJacobian}" | sed -s "s/\t*//g;s/ \+/ /g" >> ${QUEUEFILE}
	echo ""									>> ${QUEUEFILE}

	echo ""
	echo "Submitting job to cluster for PreFreeSurferPipeline.sh without ACPC alignment subject " ${Subject}
	echo ""
	#chmod 777 ${QUEUEFILE}

	PFS=$(sbatch ${QUEUEFILE})

	cd ${WD}
done



