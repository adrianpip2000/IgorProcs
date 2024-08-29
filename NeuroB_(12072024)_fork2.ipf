///////////////////////////////////////////////////////////////////////////
//////////// *** Version history in JBS lab *** ///////////////////////////
///////////////////////////////////////////////////////////////////////////
// NeuroB_(27032024)_fork1.ipf --> NeuroB_(12072024)_fork2.ipf
// - Substantial modifications done by AdrianGR during summer of 2024
//
//
///////////////////////////////////////////////////////////////////////////


//    This file is part of the NeuroBunny Analysis Tools, Copyright (c) 2006-2009 Jens Weber 
//
//    NeuroBunny Analysis Tools is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
//    the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
//
//    NeuroBunny Analysis Tools are distributed in the hope that it will be useful but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// 	The Patchers Power Tools are copyright by Frank W�rriehausen (http://www.mpibpc.mpg.de/groups/neher/software/index.html);
//	The XMLutils are copyright by Andrew Nelson (http://motofit.sourceforge.net, GPLv2);
//	The tool has been rewritten, simplified and expanded by Jakob B. S�rensen.


#pragma rtGlobals=2		// Use modern global access method.
#pragma IgorVersion=7.0
#pragma ModuleName=NeuroBunny


Function NeuroBunnyInit()
	SetDataFolder root:Globals
	Variable/G gSTPfreq=50, gTrainStim=50, gTrainFreq=40, gRecStim=100, gRecFreq=40, gRecISI=400, gExponents=2, gWaveindex=0, gWaveindexB=0, gBLregions=1, gTrainAuto=66, gBackExtrN=20		
	Variable/G gTau1=0,gTau2=0,gTau3=0, gDeltaI=20, gDeltaIAP=5
	Variable/G gRescueN=0, gTrainN=0, gCellNum=0
	Variable/G gCursorA=0.0001, gCursorB=0.002, gCursorC, gCursorD
	Variable/G gFitweight=3
	Variable/G gAStime=1000, gASOffset=900, gASOffset2=100, gFilter=1000
	Variable/G gMiniRise=100e-6, gMiniTau1=200e-6, gMiniTau2=2e-3, gMiniAmplitude=-25e-12, gMiniAlpha=0.1
	Variable/G gSeriesTot=NaN, gSweepTot=NaN, gGroupTot=NaN, gGroupNum=1, gSeriesNum=1, gSweepNum=1, gNewFileFlag=1, gDatIndex=0, gNewSeriesFlag=1, gLoadOnlyFlag=1, gNewGroupFlag=1
	String/G gTheWave, gWaveList, gDatFileList, gDatFileName, gDatPath, gPulseNote, gProtocol, gSeriesPopList, gGroupPopList, gSweepPopList, gExpGroup="Ctrl", gNeuron, gInfoPath
	SetDataFolder root:
End

Function MyDFInit()
	SetDataFolder root:
	if( DataFolderExists("Globals") )
	else 
		NewDataFolder/O/S root:Globals
		SetDataFolder root:
	endif	
	SetDataFolder root:
	if( DataFolderExists("OrigData") )
	else 
		NewDataFolder/O/S root:OrigData
		SetDataFolder root:
	endif
	if( DataFolderExists("WorkData") )
	else 
		NewDataFolder/O/S root:WorkData
		NewDataFolder/O/S root:WorkData:integral
		NewDataFolder/O/S root:WorkData:fits
		SetDataFolder root:
	endif
	if( DataFolderExists("Results") )
		NewDataFolder/O/S root:Results:Backextr
	else 
		NewDataFolder/O/S root:Results
		NewDataFolder/O/S root:Results:Backextr
		NewDataFolder/O/S root:Results:integral
		NewDataFolder/O/S root:Results:integral:fit
		SetDataFolder root:
	endif
	if( DataFolderExists("Deconvolution") )
	else 		
		NewDataFolder/O/S root:Deconvolution
		NewDataFolder/O/S root:Deconvolution:rRate
		SetDataFolder root:
	endif
	if( DataFolderExists("PulseBrowser") )
	else 		
		NewDataFolder/O/S root:PulseBrowser
		SetDataFolder root:
	endif	

End


Menu "NeuroBunny"
	"Do electrophysiological Analysis"
	help={"Open the NeuroBunny ePhys Analysis Panel"}

End

Menu "NeuroBunny"
	Submenu "Special: Save or concat data"
		"Save", testSaveData(saveBool=1)
		"Concat data", testConcatData()
		"Concat data v2", testConcatData2()
	End
End


Menu "Graph"
	"Stack Axes"
	help= {"Stack all left axes in the current graph."}
End


Function SelectHEKAExperiments()

	MyDFInit()
	NeuroBunnyInit()
	
	SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList, gDatFileList=root:Globals:gDatFileList, gDatPath=root:Globals:gDatPath, gDatFileName=root:Globals:gDatFileName, gPulseNote=root:Globals:gPulseNote, gProtocol=root:Globals:gProtocol, gSeriesPopList=root:Globals:gSeriesPopList, gGroupPopList=root:Globals:gGroupPopList, gSweepPopList=root:Globals:gSweepPopList
	NVAR gSeriesTot=root:Globals:gSeriesTot, gGroupTot=root:Globals:gGroupTot, gSweepTot=root:Globals:gSweepTot, gGroupNum=root:Globals:gGroupNum, gSeriesNum=root:Globals:gSeriesNum, gSweepNum=root:Globals:gSweepNum, gLoadOnlyFlag=root:Globals:gLoadOnlyFlag
	String graphname="BrowseGraph", hostname="NBrowser"
	
	NewDataFolder/O/S root:IO
	NewPath/O/Q/Z/M="Select Folder with HEKA experiment files" Path_Experiment			// Ask for experiment directory
	if (V_Flag!=0)
		abort
	else
		PathInfo Path_experiment
		gDatPath=S_path
		gDatFileList=indexedfile(Path_Experiment,-1,".dat") //List of the ".dat" files in folder
		if (strlen(gDatFileList)==0)
			DoAlert 0,"No Experiment Files found! Aborting."
			abort
		endif
		gDatFileName=indexedfile(Path_Experiment,0,".dat") //filename of the first ".dat" of the folder
	endif
	gLoadOnlyFlag=0
	//LoadPulseBrowser()	
	LoadDatFile(gDatFileName)
End	

Function LoadDatFile(Filename)
	string filename
	
	SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList, gDatFileList=root:Globals:gDatFileList, gDatPath=root:Globals:gDatPath, gDatFileName=root:Globals:gDatFileName, gPulseNote=root:Globals:gPulseNote, gProtocol=root:Globals:gProtocol, gGroupPopList=root:Globals:gGroupPopList, gSeriesPopList=root:Globals:gSeriesPopList, gSweepPopList=root:Globals:gSweepPopList
	NVAR gDatIndex=root:Globals:gDatIndex, gSeriesTot=root:Globals:gSeriesTot, gGroupTot=root:Globals:gGroupTot, gSweepTot=root:Globals:gSweepTot, gGroupNum=root:Globals:gGroupNum, gSeriesNum=root:Globals:gSeriesNum, gSweepNum=root:Globals:gSweepNum, gNewFileFlag=root:Globals:gNewFileFlag, gNewSeriesFlag=root:Globals:gNewSeriesFlag, gNewGroupFlag=root:Globals:gNewGroupFlag
	String graphname="BrowseGraph", hostname="NBrowser"
	Variable i=1

	SetDataFolder root:PulseBrowser
	gTheWave=RemoveEnding(gDatFileName , ".dat")
	gTheWave=ReplaceString("-", gTheWave, "_") // converts to old igor naming convention
	gTheWave=ReplaceString(" ", gTheWave, "_") // converts to old igor naming convention
	
	Execute "bpc_LoadPulse/O/A="+num2str(gGroupNum)+"/B="+num2str(gSeriesNum)+"/C="+num2str(gSweepNum)+"/N="+gTheWave+" \""+gDatPath+gDatFileName+"\""
	print "bpc_LoadPulse/O/A="+num2str(gGroupNum)+"/B="+num2str(gSeriesNum)+"/C="+num2str(gSweepNum)+"/N="+gTheWave+" \""+gDatPath+gDatFileName+"\""
	gTheWave=gTheWave+"_"+num2str(gGroupNum)+"_"+num2str(gSeriesNum)+"_"+num2str(gSweepNum)
	if (waveexists($gTheWave)==0)
		DoAlert 0,"Houston, we have a wave loading problem. Please try again."
		abort
	endif
	gPulseNote=note($gTheWave)
	if (FindListItem(graphname,ChildWindowList(hostname))==-1)
		Display/W=(264,60,1280,555)/HOST=$hostname/N=$graphname/K=1/W=(2.25,38,954,425) $gTheWave
	else
		SetActiveSubWindow $(hostname+"#"+graphname)
		AppendToGraph $gTheWave
	endif
	
	if (gNewFileFlag==1)
		sscanf StringFromList(4,gPulseNote), "\rGroup:\t\t1 of %f", gGroupTot
		sscanf StringFromList(5,gPulseNote), "\rSeries:\t\t1 of %f", gSeriesTot
		sscanf StringFromList(6,gPulseNote), "\rSweep:\t\t1 of %f", gSweepTot
		sscanf StringFromList(11,gPulseNote), "\rStimulation:\t %s", gProtocol
			
		gGroupPopList=""
		do
			gGroupPopList += num2str(i)+" of "+num2str(gGroupTot)+";"
			i +=1
		while (i<=gGroupTot)
		i=1
		gSeriesPopList=""
		do
			gSeriesPopList += num2str(i)+" of "+num2str(gSeriesTot)+";"
			i +=1
		while (i<=gSeriesTot)
		i=1
		gSweepPopList=""
		do
			gSweepPopList += num2str(i)+" of "+num2str(gSweepTot)+";"
			i +=1
		while (i<=gSweepTot)
		ControlUpdate/W=$hostname popup_Group
		ControlUpdate/W=$hostname popup_Series
		ControlUpdate/W=$hostname popup_Sweep
	endif
	
	if (gNewSeriesFlag==1)
		sscanf StringFromList(6,gPulseNote), "\rSweep:\t\t1 of %f", gSweepTot
		sscanf StringFromList(11,gPulseNote), "\rStimulation:\t %s", gProtocol
	
		i=1
		gSweepPopList=""
		do
			gSweepPopList += num2str(i)+" of "+num2str(gSweepTot)+";"
			i +=1
		while (i<=gSweepTot)
		ControlUpdate/W=$hostname popup_Sweep
		abort
	endif	
	
	if (gNewGroupFlag==1)
		sscanf StringFromList(5,gPulseNote), "\rSeries:\t\t1 of %f", gSeriesTot
		sscanf StringFromList(6,gPulseNote), "\rSweep:\t\t1 of %f", gSweepTot
		sscanf StringFromList(11,gPulseNote), "\rStimulation:\t %s", gProtocol
		gSeriesNum=1
		gSweepNum=1

		i=1
		gSeriesPopList=""
		do
			gSeriesPopList += num2str(i)+" of "+num2str(gSeriesTot)+";"
			i +=1
		while (i<=gSeriesTot)
		i=1
		gSweepPopList=""
		do
			gSweepPopList += num2str(i)+" of "+num2str(gSweepTot)+";"
			i +=1
		while (i<=gSweepTot)
		abort
		ControlUpdate/W=$hostname popup_Series
		ControlUpdate/W=$hostname popup_Sweep
	endif
End


Function LoadselectedExperiments()
	String pathname, filename, SectionString
	SVAR gInfoPath=root:Globals:gInfoPath
	NVAR gLoadOnlyFlag=root:Globals:gLoadOnlyFlag

	if (gLoadOnlyFlag==1)
	NewPath/O/Q/Z/M="Select Folder containing the NB Info File" Path_Experiment			// Ask for infofile directory
		if (V_Flag!=0)
			abort
		endif
	endif
	
	PathInfo Path_experiment
	gInfoPath=S_Path+"neurobunny.xml"

// todo: read the sections.
//SectionString =  bpc_ProfileSectionList( ",", gInfoPath)
//print bpc_ProfileEntryList( "section4", ",", gInfoPath)
// 

	PauseUpdate; Silent 1		// building window...
	NewPanel/W=(320,57,981,717)/N=NeuroLoader
	ModifyPanel cbRGB=(56576,56576,56576)

	DrawText 18,55,"Protocols"
	DrawText 188,55,"Groups"
	DrawText 317,55,"Date"
	DrawText 487,55,"Experiments"
	DrawText 188,390,"Type"
	SetVariable setvar_file,pos={45,10},size={560,15},title=" "
	SetVariable setvar_file,fSize=9,fStyle=1,value= path,noedit= 1
	ListBox protocolbox,pos={11,70},size={160,565},frame=2
	ListBox protocolbox,listWave=root:protocolwave,selWave=root:protocolsw,mode= 4
	ListBox groupbox,pos={182,70},size={120,290},frame=2,listWave=root:groupwave
	ListBox groupbox,selWave=root:groupsw,mode= 4
	ListBox typebox,pos={182,400},size={120,80},frame=2,listWave=root:typewave
	ListBox typebox,selWave=root:typesw,mode= 4
	ListBox experimentbox,pos={483,70},size={160,560},listWave=root:experimentwave
	ListBox experimentbox,selWave=root:experimentsw,row= 1,mode= 4
	ListBox folderbox,pos={311,70},size={160,410},frame=2
	ListBox folderbox,listWave=root:culturewave,selWave=root:culturesw,row= 6
	ListBox folderbox,mode= 4
	Button button_Update,pos={266,500},size={115,20},proc=Proc_Loader,title="Update Selection"
	Button button_SelectAllDate,pos={219,529},size={100,20},proc=Proc_Loader,title="All Dates"
	Button button_SelNoneDate,pos={325,529},size={101,20},proc=Proc_Loader,title="Deselect Dates"
	Button button_SelectAllExp,pos={219,558},size={100,20},proc=Proc_Loader,title="All Experiments"
	Button button_SelNoneExp,pos={325,558},size={101,20},proc=Proc_Loader,title="Deselect Exp."
	Button button_ResetListBoxes,pos={257,604},size={61,20},proc=Proc_Loader,title="Reset"
	Button button_DoneLoad,pos={325,604},size={61,20},proc=Proc_Loader,title="Done"
End


Function DoElectrophysiologicalAnalysis()
// Init global Variables for Experiment properties first
MyDFInit()
NeuroBunnyInit()
// Create the Analysis Panel
NewPanel/W=(20,50,215,745) /N=NeuroBunny		
SetDrawEnv/W=NeuroBunny fname="Arial",fsize=11, save							
	DrawText/W=NeuroBunny 9,21,"Graph"
		Button ctrlPreviousGraph,pos={55,3},size={60,20},proc=proc_PreviousGraph,title="previous",win=NeuroBunny, fsize=10
		Button ctrlNextGraph,pos={116,3},size={60,20},proc=proc_NextGraph,title="next",win=NeuroBunny, fsize=10
	DrawText/W=NeuroBunny 9,44,"Trace"
		Button ctrlPreviousTrace,pos={55,27},size={60,20},proc=none,title="previous",win=NeuroBunny,disable=2, fsize=10
		Button ctrlNextTrace,pos={116,27},size={60,20},proc=none,title="next",win=NeuroBunny,disable=2, fsize=10
	DrawLine/W=NeuroBunny 5,50,190,50
		Button ctrlBaseline,pos={5,55},size={90,20},proc=proc_GaussFilter,title="GaussFilter",win=NeuroBunny, fsize=10
		Button ctrlArtifact,pos={100,55},size={90,20},proc=Proc_Artifact,title="Remove Artifact",win=NeuroBunny, fsize=10
		Button ctrlAmplitude,pos={5,80},size={90,20},proc=proc_Amplitude,title="Amplitude",win=NeuroBunny, fsize=10
		Button ctrlChargeTrans,pos={100,80},size={90,20},proc=proc_Area,title="Charge Transfer",win=NeuroBunny, fsize=10
//	DrawLine/W=NeuroBunny 5,105,190,105
	DrawLine/W=NeuroBunny 5,107,190,107
	DrawLine/W=NeuroBunny 5,109,190,109
	DrawLine/W=NeuroBunny 5,520,190,520
	DrawLine/W=NeuroBunny 5,645,190,645
//		Button ctrlFolder,pos={5,625},size={90,20},proc=proc_GaussFilter,title="GaussFilter",win=NeuroBunny, fsize=10
		Button ctrlAutoscale,pos={5,530},size={90,30},proc=procMenuNB,title="Autoscale",win=NeuroBunny, fsize=10
		Button ctrlBL1a,pos={5,565},size={90,20},proc=procMenuNB,title="Shift @ Start",win=NeuroBunny, fsize=10
		Button ctrlBL1b,pos={100,565},size={90,20},proc=procMenuNB,title="Shift [A,B]",win=NeuroBunny, fsize=10
		Button ctrlBLstartToA,pos={5,590},size={90,20},proc=procMenuNB,title="Shift [start,A]",win=NeuroBunny, fsize=10 //-AdrianGR
		Button ctrlBL2a,pos={5,615},size={90,20},proc=procMenuNB,title="Corr. Full Trace", fsize=10
		Button ctrlBL2b,pos={100,615},size={90,20},proc=procMenuNB,title="Corr. [A,B][C,D]", fsize=10
		Button ctrlResWave,pos={5,650},size={90,20},proc=proc_Init,title="Init",win=NeuroBunny, fsize=10, fColor=(51143,62708,65535)
		Button ctrlWvAverage,pos={100,650},size={90,20},proc=procMenuNB,title="Average Waves",win=NeuroBunny, fsize=10

//			TabControl ctrlATab,pos={5,113},size={241,15},tabLabel(3)="BL",proc=AnalysisTab,win=NeuroBunny,value=3			// 4th Tab, 1st row
//			Button ctrlBL2,pos={20,155},size={140,20},fColor=(228,228,0),proc=Proc_Baseline2R,title="Two-Region Baseline",win=NeuroBunny,disable=1, fsize=10
	
		TabControl ctrlATab,pos={5,113},size={241,15},tabLabel(2)="CC",proc=AnalysisTab,win=NeuroBunny,value=2			// 3rd Tab, 1st row, this is reserved for a new CC analysis
			Button ctrRinput,pos={20,155},size={140,20},fColor=(228,228,0),proc=proc_Rinput,title="Analyze Rinput",win=NeuroBunny,disable=1, fsize=10
			SetVariable setvarDeltaI,pos={20,185},size={110,15},title="Delta I (pA):",format="%g",limits={1,1000,0.1},value=root:Globals:gDeltaI,win=NeuroBunny, fsize=10, disable=1
			Button ctrRiplot,pos={140,185},size={50,20},fColor=(158,43,20),proc=proc_RiPlot,title="Plot",win=NeuroBunny,disable=1, fsize=10
			Button ctrAP,pos={20,225},size={140,20},fColor=(228,228,0),proc=proc_AP,title="Count APs",win=NeuroBunny,disable=1, fsize=10
			Button ctrAPplot,pos={140,255},size={50,20},fColor=(158,43,20),proc=proc_APPlot,title="Plot",win=NeuroBunny,disable=1, fsize=10
			SetVariable setvarAPDI,pos={20,255},size={110,15},title="Delta I (pA):",format="%g",limits={1,1000,0.1},value=root:Globals:gDeltaIAP,win=NeuroBunny, fsize=10, disable=1
			Button ctrAPAna,pos={20,295},size={140,20},fColor=(228,228,0),proc=proc_APAna,title="Analyze AP shape",win=NeuroBunny,disable=1, fsize=10
			Button ctrAPTab,pos={140,325},size={50,20},fColor=(158,43,20),proc=proc_APTab,title="Table",win=NeuroBunny,disable=1, fsize=10			
						
//			Button ctrlMiniTempl,pos={20,155},size={140,20},fColor=(228,228,0),proc=procTempl,title="Make Mini Template",win=NeuroBunny,disable=1, fsize=10
//			Button ctrlMiniCapt,pos={20,175},size={140,20},fColor=(228,228,0),proc=procCapt,title="Capture Minis from waves",win=NeuroBunny,disable=1, fsize=10
//			Button ctrlMiniExp,pos={20,195},size={140,20},fColor=(228,228,0),proc=procExp,title="Export ampl and time results",win=NeuroBunny,disable=1, fsize=10
//			Button ctrlMiniOffs,pos={20,235},size={140,20},fColor=(43,158,50),proc=procOffs,title="Remove offset",win=NeuroBunny,disable=1, fsize=10
//			Button ctrlMiniOffsRm,pos={20,255},size={140,20},fColor=(43,158,50),proc=procOffsRm,title="Undo remove offset",win=NeuroBunny,disable=1, fsize=10
//			Button ctrlMiniAverage,pos={20,295},size={140,20},fColor=(158,43,50),proc=procAverage,title="Average Waves",win=NeuroBunny,disable=1, fsize=10
					
		TabControl ctrlATab,pos={5,113},size={241,15},tabLabel(1)="Fitting",proc=AnalysisTab,win=NeuroBunny,value=1, fsize=10			// 2nd Tab, 1st row	
			Button ctrlExponents,pos={30,155},size={120,20},fColor=(228,228,0),proc=proc_FitDExp,title="Fit integrated E/IPSC",win=NeuroBunny,disable=1, fsize=10
			//SetVariable setvarWeight,pos={20,185},size={110,15},title="Weighting:",format="%g",limits={1,1000,0.1},value=root:Globals:gFitweight,win=NeuroBunny, fsize=10
			SetVariable setvarExponents,pos={20,205},size={100,15},title="No. of Exp:",format="%g",limits={1,2,1},value=root:Globals:gExponents,win=NeuroBunny,disable=1
				
		TabControl ctrlATab,pos={5,113},size={241,15},tabLabel(0)="PSCs",proc=AnalysisTab,win=NeuroBunny,value=0				//1st Tab, 1st row
			Button ctrlSTP,pos={30,155},size={120,20},fColor=(228,228,0),proc=proc_STP,title="STP",win=NeuroBunny, fsize=12,fstyle=001
				SetVariable setvarSTPfreq,pos={20,185},size={110,15},title="Frequency:",format="%g",limits={0.01,3000,0.1},value=root:Globals:gSTPfreq,win=NeuroBunny, fsize=10
				CheckBox checkAsyncSTP,pos={140, 185}, help={"Check if you are analysing asynchronous release"}, noproc, title="Async?",win=NeuroBunny, fsize=10
			Button ctrlTrains,pos={5,215},size={90,20},fColor=(43,158,50),proc=proc_Trains,title="Trains",win=NeuroBunny, fsize=12,fstyle=001			
				SetVariable setvarTrainStim,pos={10,240},size={90,15},title="# Stimuli:",format="%g",limits={1,200,1},value=root:Globals:gTrainStim,win=NeuroBunny, fsize=10				
				SetVariable setvarTrainFreq,pos={10,260},size={110,15},title="Frequency:",format="%g",limits={0.1,3000,0.1},value=root:Globals:gTrainFreq,win=NeuroBunny, fsize=10
				CheckBox checkAsyncTRAIN,pos={120, 260}, help={"Check if doing backextrapolation"}, noproc, title="BExtract?",win=NeuroBunny, value=0, fsize=10 //Changed value to 0 -AdrianGR
				SetVariable setvarBactExtrN,pos={10,280}, size={120,15},title="#N Backextr:",format="%g",limits={1,200,1},value=root:Globals:gBackExtrN,win=NeuroBunny, fsize=10
				CheckBox checkFitting,pos={120, 240}, help={"Check to enable fitting"}, noproc, title="Fitting?",win=NeuroBunny, value=0, fsize=10
				
			//Button ctrlTrainsAuto,pos={100,215},size={90,20},fColor=(43,158,50),proc=proc_TrainsAuto,title="Auto Trains",win=NeuroBunny,fsize=12,fstyle=001 					// Button for automatic multiple analysis
			//	SetVariable setvarTrainAuto,pos={100,240},size={80,15},title="# Auto:",format="%g",limits={1,200,1},value=root:Globals:gTrainAuto,win=NeuroBunny, fsize=10
				
			//	CheckBox checkFFTtrain,pos={140, 240}, help={"Check if you want to use FFT deconvolution"}, noproc, title="FFT?",win=NeuroBunny, fsize=10
			Button ctrlRecovery,pos={30,305},size={120,20},fColor=(158,43,20),proc=proc_Recovery,title="Recovery",win=NeuroBunny, fsize=12,fstyle=001
				SetVariable setvarRecStim,pos={30,330},size={100,15},title="# Stimuli:",format="%g",limits={1,200,1},value=root:Globals:gRecStim,win=NeuroBunny, fsize=10
				SetVariable setvarRecFreq,pos={20,350},size={110,15},title="Frequency:",format="%g",limits={1,3000,1},value=root:Globals:gRecFreq,win=NeuroBunny, fsize=10
				SetVariable setvarRecISI,pos={30,370},size={100,15},title="ISI (ms):",format="%g",limits={1,60000,1},value=root:Globals:gRecISI,win=NeuroBunny, fsize=10

		TabControl ctrlBTab,pos={5,128},size={241,15},tabLabel(0)="Async",proc=AnalysisTab,win=NeuroBunny,value=0, fsize=10			// 1st Tab, 2nd row
			Button ctrlASync,pos={20,155},size={140,20},fColor=(228,228,0),proc=proc_Async,title="Asynchronous Release",win=NeuroBunny,disable=1, fsize=10
				SetVariable setvarAStime,pos={20,185},size={150,15},title="Time after Stim (ms):",format="%g",limits={1,3000,1},value=root:Globals:gAStime,win=NeuroBunny,disable=1, fsize=10
				SetVariable setvarASOffset,pos={20,210},size={150,15},title="Offset [Start] (ms):   ",format="%g",limits={0,1000,1},value=root:Globals:gASOffset,win=NeuroBunny,disable=1, fsize=10
				SetVariable setvarASOffset2,pos={20,235},size={150,15},title="Offset [End] (ms):    ",format="%g",limits={1,3000,1},value=root:Globals:gASOffset2,win=NeuroBunny,disable=1, fsize=10

		TabControl ctrlBTab,pos={5,128},size={241,15},tabLabel(1)="Sucrose",proc=AnalysisTab,win=NeuroBunny,value=0, fsize=10			// 2nd Tab, 2nd row
			Button ctrlSucrose,pos={20,155},size={140,20},fColor=(228,228,0),proc=proc_Sucrose,title="Sucrose Pulse",win=NeuroBunny,disable=1, fsize=10
			Button ctrlSucPair1,pos={20,195},size={140,20},fColor=(43,158,50),proc=proc_Sucrose,title="Paired Sucrose: 1st",win=NeuroBunny,disable=1, fsize=10
			Button ctrlSucPair2,pos={20,215},size={140,20},fColor=(43,158,50),proc=proc_Sucrose,title="Paired Sucrose: 2nd",win=NeuroBunny,disable=1, fsize=10
			Button ctrlFilter,pos={20,305},size={140,20},fColor=(43,158,50),proc=proc_Sucrose,title="Filter trace",win=NeuroBunny,disable=1, fsize=10
			SetVariable setvarFilter,pos={20,285},size={150,15},title="Filter trace (Hz):",format="%g",limits={1,5000,1},value=root:Globals:gFilter,win=NeuroBunny,disable=1, fsize=10
	
	DrawLine/W=NeuroBunny 5,430,190,430
	DrawLine/W=NeuroBunny 5,432,190,432
			CheckBox checkFixCursor,pos={10, 445}, help={"Check if you want to fix cursor"}, proc=proc_checkFixCursors, title="fix cursors",win=NeuroBunny, fsize=10			
			Button ctrlForwA,pos={50,470},size={40,20},fColor=(20,43,158),proc=proc_ForwA,title="A right",win=NeuroBunny,disable=0, fsize=10
			Button ctrlBackwA,pos={10,470},size={40, 20},fColor=(20,43,158),proc=proc_BackwA,title="A left",win=NeuroBunny,disable=0, fsize=10
			Button ctrlForwB,pos={50,490},size={40,20},fColor=(20,43,158),proc=proc_ForwB,title="B right",win=NeuroBunny,disable=0, fsize=10
			Button ctrlBackwB,pos={10,490},size={40,20},fColor=(20,43,158),proc=proc_BackwB,title="B left",win=NeuroBunny,disable=0, fsize=10
			
			//Some extra functionality -AdrianGR
			CheckBox chk_IgnoreSavedCursors,pos={80, 445},value=1, help={"Check to ignore saved cursor positions"}, noproc, title="Ignore saved cursors",win=NeuroBunny, fsize=10
			Button button_RefreshCursors,pos={100,470},size={80,20},proc=proc_button_RefreshCursors,title="Refresh cursors",win=NeuroBunny,disable=2, fsize=10
			Button button_initRTSRpanel,pos={150,675},size={40,15},proc=proc_button_initRTSRpanel,title="RTSR",win=NeuroBunny,disable=0, fsize=10
End

Function AnalysisTab(name,tab)
	string name
	variable tab
	
	ControlInfo ctrlATab
	if (tab==0 && (cmpstr(name,"ctrlATab")==0))		//Activate controls for PSCs TabControl
		Button ctrlASync, disable=3
		SetVariable setvarAStime,disable=3
		SetVariable setvarASOffset,disable=3
		SetVariable setvarASOffset2,disable=3
		Button ctrlBL2, disable=3
		Button ctrlExponents,disable=3
		SetVariable setvarExponents,disable=3
		CheckBox checkAsyncSTP,disable=0
		Button ctrlSTP,disable=0
		SetVariable setvarSTPfreq,disable=0
		SetVariable setvarWeight, disable=3
		Button ctrlTrains,disable=0
		SetVariable setvarTrainStim,disable=0
		SetVariable setvarTrainFreq,disable=0
		SetVariable setvarBactExtrN, disable=0
		CheckBox checkAsyncTRAIN,disable=0
		CheckBox checkFitting,disable=0
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=0
		SetVariable setvarRecStim,disable=0
		SetVariable setvarRecFreq,disable=0
		SetVariable setvarRecISI,disable=0
		Button ctrlSucrose, disable=3
		Button ctrlSucPair1, disable=3
		Button ctrlSucPair2, disable=3
		SetVariable setvarFilter, disable=3
		Button ctrlFilter, disable=3
		Button ctrRinput, disable=3
		Button ctrAP, disable=3
		Button ctrAPAna, disable=3
		SetVariable setvarDeltaI, disable=3
		SetVariable setvarAPDI, disable=3
		Button ctrRiplot, disable=3
		Button ctrAPplot, disable=3
		Button ctrAPTab, disable=3
	elseif (tab==1 && (cmpstr(name,"ctrlATab")==0))		//Activate controls for Fitting tab [JBS]
		Button ctrlASync, disable=3
		SetVariable setvarAStime,disable=3
		SetVariable setvarASOffset,disable=3
		SetVariable setvarASOffset2,disable=3
		Button ctrlBL2, disable=3
		SetVariable setvarWeight, disable=0
		Button ctrlExponents,disable=0
		SetVariable setvarExponents,disable=0
		CheckBox checkAsyncSTP,disable=3
		Button ctrlSTP,disable=3
		SetVariable setvarSTPfreq,disable=3
		Button ctrlTrains,disable=3
		SetVariable setvarTrainStim,disable=3
		SetVariable setvarTrainFreq,disable=3
		SetVariable setvarBactExtrN, disable=3
		CheckBox checkAsyncTRAIN,disable=3
		CheckBox checkFitting,disable=3
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=3
		SetVariable setvarRecStim,disable=3
		SetVariable setvarRecFreq,disable=3
		SetVariable setvarRecISI,disable=3	
		Button ctrlSucrose, disable=3
		Button ctrlSucPair1, disable=3
		Button ctrlSucPair2, disable=3
		SetVariable setvarFilter, disable=3
		Button ctrlFilter, disable=3
		Button ctrRinput, disable=3
		Button ctrAP, disable=3
		Button ctrAPAna, disable=3
		SetVariable setvarDeltaI, disable=3
		SetVariable setvarAPDI, disable=3
		Button ctrRiplot, disable=3
		Button ctrAPplot, disable=3
		Button ctrAPTab, disable=3
	elseif (tab==2 && (cmpstr(name,"ctrlATab")==0))		//CC tab
		Button ctrlASync, disable=3
		SetVariable setvarAStime,disable=3
		SetVariable setvarASOffset,disable=3
		SetVariable setvarASOffset2,disable=3
		Button ctrlBL2, disable=3
		Button ctrlExponents,disable=3
		SetVariable setvarWeight, disable=3
		SetVariable setvarExponents,disable=3
		CheckBox checkAsyncSTP,disable=3
		Button ctrlSTP,disable=3
		SetVariable setvarSTPfreq,disable=3
		Button ctrlTrains,disable=3
		SetVariable setvarTrainStim,disable=3
		SetVariable setvarTrainFreq,disable=3
		SetVariable setvarBactExtrN, disable=3
		CheckBox checkAsyncTRAIN,disable=3
		CheckBox checkFitting,disable=3
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=3
		SetVariable setvarRecStim,disable=3
		SetVariable setvarRecFreq,disable=3
		SetVariable setvarRecISI,disable=3	
		Button ctrlSucrose, disable=3
		Button ctrlSucPair1, disable=3
		Button ctrlSucPair2, disable=3
		SetVariable setvarFilter, disable=3
		Button ctrlFilter, disable=3
		Button ctrRinput, disable=0
		Button ctrAP, disable=0
		Button ctrAPAna, disable=0
		SetVariable setvarDeltaI, disable=0
		SetVariable setvarAPDI, disable=0
		Button ctrRiplot, disable=0
		Button ctrAPplot, disable=0
		Button ctrAPTab, disable=0
	elseif (tab==3 && (cmpstr(name,"ctrlATab")==0))		
		Button ctrlASync, disable=3
		SetVariable setvarAStime,disable=3
		SetVariable setvarASOffset,disable=3
		SetVariable setvarASOffset2,disable=3
		Button ctrlBL2, disable=0
		Button ctrlExponents,disable=3
		SetVariable setvarExponents,disable=3
		CheckBox checkAsyncSTP,disable=3
		Button ctrlSTP,disable=3
		SetVariable setvarSTPfreq,disable=3
		Button ctrlTrains,disable=3
		SetVariable setvarTrainStim,disable=3
		SetVariable setvarTrainFreq,disable=3
		SetVariable setvarBactExtrN, disable=3
		CheckBox checkAsyncTRAIN,disable=3
		CheckBox checkFitting,disable=3
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=3
		SetVariable setvarRecStim,disable=3
		SetVariable setvarRecFreq,disable=3
		SetVariable setvarRecISI,disable=3	
		Button ctrlSucrose, disable=3
		Button ctrlSucPair1, disable=3
		Button ctrlSucPair2, disable=3
		SetVariable setvarFilter, disable=3
		Button ctrlFilter, disable=3
		Button ctrRinput, disable=3
		Button ctrAP, disable=3
		Button ctrAPAna, disable=3
		SetVariable setvarDeltaI, disable=3
		SetVariable setvarAPDI, disable=3
		Button ctrRiplot, disable=3
		Button ctrAPplot, disable=3
		Button ctrAPTab, disable=3
	elseif (tab==0 && (cmpstr(name,"ctrlBTab")==0))		
		Button ctrlASync, disable=0
//		SetVariable setvarAStime,disable=0
//		SetVariable setvarASOffset,disable=0
//		SetVariable setvarASOffset2,disable=0
		Button ctrlBL2, disable=3
		Button ctrlExponents,disable=3
		SetVariable setvarWeight, disable=3
		SetVariable setvarExponents,disable=3
		CheckBox checkAsyncSTP,disable=3
		Button ctrlSTP,disable=3
		SetVariable setvarSTPfreq,disable=3
		Button ctrlTrains,disable=3
		SetVariable setvarTrainStim,disable=3
		SetVariable setvarTrainFreq,disable=3
		SetVariable setvarBactExtrN, disable=3
		CheckBox checkAsyncTRAIN,disable=3
		CheckBox checkFitting,disable=3
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=3
		SetVariable setvarRecStim,disable=3
		SetVariable setvarRecFreq,disable=3
		SetVariable setvarRecISI,disable=3	
		Button ctrlSucrose, disable=3
		Button ctrlSucPair1, disable=3
		Button ctrlSucPair2, disable=3
		SetVariable setvarFilter, disable=3
		Button ctrlFilter, disable=3
		Button ctrRinput, disable=3
		Button ctrAP, disable=3
		Button ctrAPAna, disable=3
		SetVariable setvarDeltaI, disable=3
		SetVariable setvarAPDI, disable=3
		Button ctrRiplot, disable=3
		Button ctrAPplot, disable=3
		Button ctrAPTab, disable=3
	elseif (tab==1 && (cmpstr(name,"ctrlBTab")==0))		//sucrose tab?
		Button ctrlASync, disable=3
		SetVariable setvarAStime,disable=3
		SetVariable setvarASOffset,disable=3
		SetVariable setvarASOffset2,disable=3
		Button ctrlBL2, disable=3
		SetVariable setvarExponents,disable=3
		CheckBox checkAsyncSTP,disable=3
		Button ctrlSTP,disable=3
		SetVariable setvarSTPfreq,disable=3
		Button ctrlTrains,disable=3
		SetVariable setvarTrainStim,disable=3
		SetVariable setvarTrainFreq,disable=3
		SetVariable setvarBactExtrN, disable=3
		CheckBox checkAsyncTRAIN,disable=3
		CheckBox checkFitting,disable=3
		CheckBox checkFixCursor,disable=0
		CheckBox chk_IgnoreSavedCursors,disable=0
		CheckBox checkFFTtrain,disable=3
		Button ctrlRecovery,disable=3
		SetVariable setvarRecStim,disable=3
		SetVariable setvarRecFreq,disable=3
		SetVariable setvarRecISI,disable=3	
		SetVariable setvarWeight, disable=3
		Button ctrlSucrose, disable=0
		Button ctrlSucPair1, disable=0
		Button ctrlSucPair2, disable=0
		SetVariable setvarFilter, disable=0
		Button ctrlFilter, disable=0
		Button ctrRinput, disable=3
		Button ctrAP, disable=3
		Button ctrAPAna, disable=3
		SetVariable setvarDeltaI, disable=3
		SetVariable setvarAPDI, disable=3
		Button ctrRiplot, disable=3
		Button ctrAPplot, disable=3
		Button ctrAPTab, disable=3
	endif
End


Function setCursorsInit(String inWave)
	DFREF saveDFR = GetDataFolderDFR()				//Save initial data folder
	SetDataFolder root:Globals
	Variable/G gCursorA=0, gCursorB=0, gCursorC=pnt2x($inWave, numpnts($inWave)-200), gCursorD=pnt2x($inWave, numpnts($inWave)-100)
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A, $inWave, gCursorA
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 B, $inWave, gCursorB
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C, $inWave, gCursorC
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D, $inWave, gCursorD
	
	SetDataFolder saveDFR								//Go back to initial data folder
End

Function DisplayWaveListAnal(list)
	String list 								// A semicolon-separated list generated while initialization
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gWaveindex=root:Globals:gWaveindex
	
	SetDataFolder root:OrigData
		gTheWave = StringFromList(gwaveindex, list)	// Get the next wave name
		if (strlen(gTheWave) == 0)
			DoAlert 0,"No waves to show!"			// Ran out of waves
		endif
		
		update_Freq(gTheWave)
		
		KillWindow/Z Experiments
		Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		//gwaveindex = 0
		ModifyGraph/W=Experiments rgb=(0,39168,0)
		ShowInfo/W=Experiments
		setCursorsInit(gTheWave)
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1/P A,$gTheWave,0
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1/P B,$gTheWave,100
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1/P C,$gTheWave,numpnts($gTheWave)-200
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1/P D,$gTheWave,numpnts($gTheWave)-100
//		Cursor/C=(65535,33232,0)/H=1/S=1/L=1/P E,$gTheWave,numpnts($gTheWave)-1
	SetDataFolder root:
End

Function DisplayNextWave(list)
	String list 								// A semicolon-separated list generated while initialization
	SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
	NVAR gwaveindex=root:Globals:gwaveindex//, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
	Variable x0, x1, x2, x3
	
	ControlInfo /W=NeuroBunny checkFixCursor
	variable flag_checkFixCursor = V_Value
	if (V_Value==1)
		//Variable x0, x1, x2, x3
		x0=xcsr(A, "Experiments")
		x1=xcsr(B, "Experiments")
		x2=xcsr(C, "Experiments")
		x3=xcsr(D, "Experiments")
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	else
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD	// Original non-fixed cursor
	endif
	
	
	string LastWave=""
	SetDataFolder root:OrigData
	gwaveindex += 1
	LastWave=gTheWave		
	gTheWave = StringFromList(gwaveindex, gWaveList)	// Get the next wave name
	if (strlen(gTheWave) == 0)
		gTheWave=LastWave
		gwaveindex -= 1
		DoAlert 0,"Ran out of waves!"			// Ran out of waves
	else
		update_Freq(gTheWave)
		////DoWindow/K Experiments
		//KillWindow/Z Experiments
		//Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		//ModifyGraph/W=Experiments rgb=(0,39168,0)
		//ShowInfo/W=Experiments
		
		refreshCursors()
		//setCursorsInit(gTheWave)
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 A,$gTheWave,gCursorA
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 B,$gTheWave,gCursorB
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 C,$gTheWave,gCursorC
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 D,$gTheWave,gCursorD
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 E,$gTheWave,numpnts($gTheWave)-1
	endif
	SetDataFolder root:
End


Function DisplayPreviousWave(list)
	String list 								// A semicolon-separated list generated while initialization
	SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
	NVAR gwaveindex=root:Globals:gwaveindex//, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
	Variable x0, x1, x2, x3
	
	ControlInfo /W=NeuroBunny checkFixCursor
	variable flag_checkFixCursor = V_Value
	if (V_Value==1)
		//Variable x0, x1, x2, x3
		x0=xcsr(A, "Experiments")
		x1=xcsr(B, "Experiments")
		x2=xcsr(C, "Experiments")
		x3=xcsr(D, "Experiments")
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3		
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	else
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD	// Original non-fixed cursor
	endif
	
	
	string LastWave=""
	SetDataFolder root:OrigData
	gwaveindex -= 1
	LastWave=gTheWave		
	gTheWave = StringFromList(gwaveindex, gWaveList)	// Get the next wave name
	if (strlen(gTheWave) == 0)
		gTheWave=LastWave
		gwaveindex += 1
		DoAlert 0,"Ran out of waves!"			// Ran out of waves
	else
		update_Freq(gTheWave)
		////DoWindow/K Experiments
		//KillWindow Experiments
		//Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		//ModifyGraph/W=Experiments rgb=(0,39168,0)
		//ShowInfo/W=Experiments
		
		refreshCursors()
		//setCursorsInit(gTheWave)
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 A,$gTheWave,gCursorA
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 B,$gTheWave,gCursorB
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 C,$gTheWave,gCursorC
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 D,$gTheWave,gCursorD
	endif
	SetDataFolder root:
End


//Handles checking and setting of cursors -AdrianGR
//Using fixed cursors overrides saved cursors functionality
Function refreshCursors()
	SVAR gTheWave=root:Globals:gTheWave
	Variable x0, x1, x2, x3
	SetDataFolder root:OrigData
	
	ControlInfo/W=NeuroBunny checkFixCursor
	Variable flag_checkFixCursor = V_Value
	
	ControlInfo/W=NeuroBunny chk_IgnoreSavedCursors
	Variable flag_IgnoreSavedCursors = V_Value
	Variable cursorsFound, cursorsFoundIndex, curA, curB, curC, curD
	[cursorsFound, cursorsFoundIndex, curA, curB, curC, curD] = getSavedCursors(gTheWave)
	
	if(flag_checkFixCursor==1)
		NVAR gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		KillWindow/Z Experiments
		Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		ModifyGraph/W=Experiments rgb=(0,39168,0)
		ShowInfo/W=Experiments
		Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A, $gTheWave, gCursorA
		Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 B, $gTheWave, gCursorB
		Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C, $gTheWave, gCursorC
		Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D, $gTheWave, gCursorD
		print "Using fixed cursors instead of possible saved cursors."
	endif
	
	if(flag_checkFixCursor==0)
		if(cursorsFound==1 && flag_IgnoreSavedCursors==0)
			x0=curA
			x1=curB
			x2=curC
			x3=curD
			KillWindow/Z Experiments
			Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
			ModifyGraph/W=Experiments rgb=(0,39168,0)
			ShowInfo/W=Experiments
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A, $gTheWave, x0
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 B, $gTheWave, x1
			Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C, $gTheWave, x2
			Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D, $gTheWave, x3
			SetDataFolder root:
			Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
			//NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		elseif(cursorsFound==0 || (cursorsFound==1 && flag_IgnoreSavedCursors==1))
			KillWindow/Z Experiments
			//removeAllTraces("Experiments")
			//AppendToGraph/W=Experiments $gTheWave
			Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
			ModifyGraph/W=Experiments rgb=(0,39168,0)
			//DoWindow/F Experiments
			ShowInfo/W=Experiments
			SetDataFolder root:
			setCursorsInit(gTheWave)
			if(flag_IgnoreSavedCursors==0)
				print "Could not find saved cursors for this wave"
				CheckBox chk_IgnoreSavedCursors, win=NeuroBunny, value=1
			endif
			//NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		endif
	endif
		
	SetDataFolder root:
End
///////////////////////////////////////////


Function ForwCursorA()
	SVAR gTheWave=root:Globals:gTheWave

	Variable x0, x1, x2, x3

	SetDataFolder root:OrigData		
	x0=pnt2x($gTheWave,(pcsr(A, "Experiments")+1))
	x1=pnt2x($gTheWave,(pcsr(B, "Experiments")))
	x2=pnt2x($gTheWave,(pcsr(C, "Experiments")))
	x3=pnt2x($gTheWave,(pcsr(D, "Experiments")))
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,x0
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3

	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3		
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	endif
	
end

Function BackwCursorA()
	SVAR gTheWave=root:Globals:gTheWave

	Variable x0, x1, x2, x3

	SetDataFolder root:OrigData		
	x0=pnt2x($gTheWave,(pcsr(A, "Experiments")-1))
	x1=pnt2x($gTheWave,(pcsr(B, "Experiments")))
	x2=pnt2x($gTheWave,(pcsr(C, "Experiments")))
	x3=pnt2x($gTheWave,(pcsr(D, "Experiments")))
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,x0
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3

	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3		
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	endif
	
end

Function ForwCursorB()
	SVAR gTheWave=root:Globals:gTheWave

	Variable x0, x1, x2, x3

	SetDataFolder root:OrigData		
	x0=pnt2x($gTheWave,(pcsr(A, "Experiments")))
	x1=pnt2x($gTheWave,(pcsr(B, "Experiments")+1))
	x2=pnt2x($gTheWave,(pcsr(C, "Experiments")))
	x3=pnt2x($gTheWave,(pcsr(D, "Experiments")))
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,x0
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3

	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3		
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	endif
	
end

Function BackwCursorB()
	SVAR gTheWave=root:Globals:gTheWave

	Variable x0, x1, x2, x3

	SetDataFolder root:OrigData		
	x0=pnt2x($gTheWave,(pcsr(A, "Experiments")))
	x1=pnt2x($gTheWave,(pcsr(B, "Experiments")-1))
	x2=pnt2x($gTheWave,(pcsr(C, "Experiments")))
	x3=pnt2x($gTheWave,(pcsr(D, "Experiments")))
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,x0
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3

	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		SetDataFolder root:
		Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3		
		NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD							// Fixed cursors
	endif
	
end


Function BaselineStartToA()
	Variable Baseline_X0, Baseline_X1,leak
	
	Baseline_X1=xcsr(A,"Experiments")
	leak=baselinewave(waverefindexed("Experiments",0,1),0,Baseline_X1)
	print wavename("",0,1),"\tleak\t",leak
End

Function BaselineSelected()
	Variable Baseline_X0, Baseline_X1,leak
	
	Baseline_X0=xcsr(A,"Experiments")
	Baseline_X1=xcsr(B,"Experiments")
	leak=baselinewave(waverefindexed("Experiments",0,1),Baseline_X0,Baseline_X1)
	print wavename("",0,1),"\tleak\t",leak
End

Function BaselineSelectedFix()
	Variable leak
	
	leak=baselinewave(waverefindexed("Experiments",0,1),0,0.002)
	print wavename("",0,1),"\tleak\t",leak
End

Function BaselineAll()
	SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
	NVAR gWaveindex=root:Globals:gWaveindex
	Variable n=0
	string wavetemp
		
	SetDataFolder root:OrigData
	do
		wavetemp = StringFromList(n, gWaveList)	// Get the next wave name
		wave/Z w_temp= root:OrigData:$wavetemp
		if (strlen(wavetemp) == 0)
			break
		endif
		BaselineWave(w_temp,0.0001,0.002)
		n+=1
	while (n>0)
End

Function BaselineWave(w,x0,x1)
	wave w
	variable x0,x1
	variable leak
	
	leak=faverage(w,x0,x1)
	w=w-leak
	return leak
End

Function BaselineWaveTwoRegion(w)
	wave w
	variable p0,p1,p2,p3
	wave/Z w_coef
	

	p0=pcsr(A,"Experiments")
	p1=pcsr(B,"Experiments")
	p2=pcsr(C,"Experiments")
	p3=pcsr(D,"Experiments")

	Duplicate/O w,wavefortworegionbaseline,fit_wavefortworegionbaseline
	wavefortworegionbaseline[p1,p2]=NaN
	fit_wavefortworegionbaseline=0
	if ((p1-p0>0) && (p3-p2>0))	// ||		//changed by Jakob
		SetDataFolder root:			
		CurveFit/Q/N line wavefortworegionbaseline[p0,p3]
		wave W_coef=root:W_coef		//changed by Jakob
		fit_wavefortworegionbaseline=W_coef[0]+W_coef[1]*x
		w = w  - fit_wavefortworegionbaseline
	else
		DoAlert 0,"Adjust your cursors!"
		abort
	endif
//	Killwaves wavefortworegionbaseline,fit_wavefortworegionbaseline	
End

Function BaselineWaveTwoRegion2(w)
	wave w
	variable p0,p1,p2,p3
	wave/Z w_coef

	p0=leftx(w)
	p1=rightx(w)
	p2=(x2pnt(w,p0+0.002))
	p3=(x2pnt(w,p1-0.002))
		
	Duplicate/O w,wavefortworegionbaseline,fit_wavefortworegionbaseline
	wavefortworegionbaseline[p2,p3]=NaN
	fit_wavefortworegionbaseline=0
	SetDataFolder root:	
	CurveFit/Q/N line wavefortworegionbaseline
	wave W_coef=root:W_coef
	fit_wavefortworegionbaseline=W_coef[0]+W_coef[1]*x
	w=w-fit_wavefortworegionbaseline
End

Function IntegrateCursors()
	variable areatemp, n
	string nametemp

			nametemp=wavename("",0,1)
			if (Waveexists(root:WorkData:$nametemp)==0)
				Duplicate/O root:OrigData:$nametemp, root:WorkData:$nametemp
			endif
			Duplicate/O root:OrigData:$nametemp, root:WorkData:Integral:$nametemp
			wave w_temp=root:WorkData:Integral:$nametemp
			SetDataFolder root:Results
			if (WaveExists(Charge)==0)
				Make/N=(1,2)/T Charge
			endif
			wave/T w_results=root:Results:Charge
			n=DimSize(w_results,0)+1
			Redimension/N=(n,-1) w_results
			areatemp=area(w_temp, xcsr(A), xcsr(B))
			w_results[n][0] += nametemp
			w_results[n][1] +=num2str(areatemp)
			integrate/T w_temp/D=root:results:integral:$nametemp
			AppendToGraph/W=Experiments/R=right w_temp
			SetScale d 0,0,"C", w_temp
			SetAxis/A/R right
			print nametemp,"\tArea\t: ", areatemp
End

Function AsyncRelease()

	SVAR gTheWave=root:Globals:gTheWave
	String nametemp
	Variable x0, x1, I

			x0=xcsr(C,"Experiments")
			x1=xcsr(D,"Experiments")
			nametemp=wavename("",0,1)	//get wavename
			SetDataFolder root:workdata:integral
			if (WaveExists(AreaSummary)==0)
			Make/N=(1) AreaSummary
			Edit root:WorkData:integral:AreaSummary
			endif
			if (WaveExists(IntegralSummary)==0)
			Make/N=(1) IntegralSummary
			Edit root:WorkData:integral:IntegralSummary
			endif
			wave area_temp=root:workdata:integral:AreaSummary
			
			SetDataFolder root:OrigData
			duplicate/O/R=(x0, x1) $gTheWave root:WorkData:gTheWave
			display root:WorkData:gTheWave
			
			I=DimSize(area_temp,0)+1
			Redimension/N=(I,-1) area_temp
			area_temp[I][0]=area(root:workdata:gTheWave,x0,x1)
			
			Resample/RATE=2000 root:Workdata:gTheWave  // Downsampling  to prevent data overflow 
			integrate/T root:WorkData:gTheWave /D=root:workdata:integral:integral			// Get cumulative release after HFS
			Display root:workdata:integral:integral
			wave integral_temp=root:workdata:integral:Integral
			
			appendtotable root:workdata:integral:IntegralSummary integral_temp.id
			Rename ::WorkData:integral:integral,$nametemp; 


End

Function FilterTrace()
	NVAR gFilter=root:Globals:gFilter
	SVAR gTheWave=root:Globals:gTheWave
	Variable/G Hz
	Hz=gFilter
	
	SetDataFolder root:OrigData
//	Duplicate/O $gTheWave root:WorkData:$gTheWave
//	Display root:WorkData:$gTheWave
	
//	duplicate/O $gTheWave root:WorkData:gTheWave
	Resample/RATE=(Hz) root:OrigData:$gTheWave


End

Function ReleaseSucrose(Flag)
	Variable Flag
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
	Variable x0, x1, x2, x3, l
	String nametemp


	SetDataFolder root:OrigData
	Duplicate/O $gTheWave root:WorkData:$gTheWave
//	Display root:WorkData:$gTheWave
// Sophie can change the filtering
//	Resample/RATE=5e2 root:WorkData:$gTheWave

	wave w_temp=root:WorkData:$gTheWave			// Make references to used waves
	SetDataFolder root:Results
		if (WaveExists(Sucrose)==0)
			Make/N=(1,6) Sucrose
		endif
	wave w_results=root:Results:Sucrose
	nametemp=wavename("",0,1)	//get wavename
	
	if (Flag != 2)
		l=DimSize(w_results,0)+1
		Redimension/N=(l,-1) w_results
	elseif (Flag==2)
		l=DimSize(w_results,0)
	endif
	
	x0=xcsr(A,"Experiments")
	gCursorA=x0
	x1=xcsr(B,"Experiments")
	gCursorB=x1
	x2=xcsr(C,"Experiments")
	gCursorC=x2
	x3=xcsr(D,"Experiments")
	gCursorD=x3
	
//Results Order: Area complete,  Area sustained, "Real" Area; 4-7 same for 2nd pulse
	if (Flag==0)
		w_results[l][0]=area(w_temp, x0, x3)
		w_results[l][1]=area(w_temp, x2, x3)
		w_results[l][2]=area(w_temp, x0, x3)-(((x3-x0)/(x3-x2))*area(w_temp, x2, x3))
	elseif (Flag==1)
		w_results[l][0]=area(w_temp, x0, x3)
		w_results[l][1]=area(w_temp, x2, x3)
		w_results[l][2]=area(w_temp, x0, x3)-(((x3-x0)/(x3-x2))*area(w_temp, x2, x3))
	elseif (Flag==2)
		w_results[l][3]=area(w_temp, x0, x3)
		w_results[l][4]=area(w_temp, x2, x3)
		w_results[l][5]=area(w_temp, x0, x3)-(((x3-x0)/(x3-x2))*area(w_temp, x2, x3))
	endif

	duplicate/O/R=(x0,(x3+1)) w_temp, root:results:$nametemp
	integrate/T root:results:$nametemp			// Get cumulative release
	AppendToGraph/W=Experiments/R=right root:results:$nametemp
	SetAxis/A
	SetAxis/A/R right

End	

Function TauSelected()
	NVAR tau_average, K2
	NVAR tau_X0, tau_X1
	variable tau
	variable V_FitError=0
	
			Duplicate/O waverefindexed("",0,1) tempwave
			CurveFit/Q/Q/N exp  tempwave(tau_X0,tau_X1)
			print wavename("",0,1),"\tTau (s)\t",1/K2
End

Function  Amplitude()
	SVAR gTheWave=root:Globals:gTheWave
	Variable n
	NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB
	
	SetDataFolder root:Results
	if (WaveExists(Amplitudes)==0)
		Make/N=(1,2)/T Amplitudes
	endif
	wave/T w_results=root:Results:Amplitudes
	n=DimSize(w_results,0)+1
	Redimension/N=(n,-1) w_results
	SetDataFolder root:OrigData
	wavestats/Q/M=1/R=(xcsr(A,"Experiments"),xcsr(B,"Experiments")) $gTheWave
	gCursorA=xcsr(A,"Experiments")
	gCursorB=xcsr(B,"Experiments")
	w_results[n][0] += gTheWave
	w_results[n][1] += num2str(V_min)
	
End	


Function RiPlot()		//Programmed  by Jakob B. S�rensen in July 2021 to plot input resistance data

SetDataFolder root:Results:
If(Waveexists($"Vampl_exp")==0)
	DoAlert 0, "You have to analyze Rinput data before you can plot them"
	abort
endif
wave w_DeltaV=root:Results:Vampl_exp
wave w_DeltaI=root:Results:IDelta_exp
variable k, numtraces
numtraces=Dimsize(w_DeltaV,0)
Display Vampl_exp[1][] vs IDelta_exp[1][]
ModifyGraph mode=4
for (k=2;k<numtraces;k+=1)
  AppendToGraph Vampl_exp[k][] vs IDelta_exp[k][]
  ModifyGraph mode=4
  Label left "\\UV (\\F'Symbol'D\\F'Arial'V\\Bm\\M)"
  Label bottom "pA (\\F'Symbol'D\\F'Arial'I)"
endfor
SetDataFolder root:

End

Function RinputAna()		//Programmed by Jakob B. S�rensen in July 2021 to allow calculation of input resistance. 
SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
NVAR gDeltaI=root:Globals:gDeltaI
NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gWaveindex=root:Globals:gWaveindex
wave w_temp=root:OrigData:$gTheWave

variable x0, x1, VCursor, str, Runs, numtraces, n, swnum
string tempwave, wavebase, expwaves, list, firstsw

x0=xcsr(A, "Experiments")
x1=xcsr(B, "Experiments")
//SetDataFolder root:
//ControlInfo /W=NeuroBunny checkFixCursor
//	if (V_Value==1)
//		Variable/G gCursorA=x0, gCursorB=x1					// Fixed cursors 
//	endif

SetDataFolder root:OrigData
str=strsearch(gTheWave,"Rinput",0)
wavebase=gTheWave[0,str-1]		//wavebase contains the experiment number
print "wavebase ", wavebase
expwaves=Wavelist(wavebase+"*", ";", "")		//expwaves identifies the sweeps in the expeirments.
print "expwave =", expwaves
numtraces=ItemsInList(expwaves)
print "numtraces = ", numtraces				//numtraces are the number of sweeps in the experiments
firstsw=Stringfromlist(0,expwaves)
swnum= WhichListItem(firstsw, gWaveList)
if (swnum!=gWaveindex)						//this is a loop that resets the gWaveindex to the first sweep, if this is not already the case
	SetDataFolder root:globals
	gWaveindex=swnum-1					//gWaveindex is set to swnum-1, because it is incremented by one in DisplayNextWave
	print "cursors not on first sweep - replotting first sweep and calculating from there!"
	DisplayNextWave(gWaveList)
endif
	
SetDataFolder root:Results
	
	if (WaveExists('RiFirstSw')==0)		//Wave for saving experiment names
		Make/T/N=(1) 'RiFirstSw'
	endif
	if (WaveExists('Rinputs')==0)		//Wave for saving Rinput 
		Make/N=(1) 'Rinputs'
	endif
	if (WaveExists('Vrest')==0)		//Wave for saving resting membrane potential
		Make/N=(1) 'Vrest'
	endif
	if (WaveExists('RinputExp')==0)		//Wave for saving experiment names
		Make/T/N=(1) 'RinputExp'
	endif
	if (WaveExists('Vampl_exp')==0)		//Wave for saving Vmem values at each measurement 
		Make/N=(1,numtraces) 'Vampl_exp'
	endif
		if (WaveExists('IDelta_exp')==0)		//Wave for saving IDelta values at each measurement 
		Make/N=(1,numtraces) 'IDelta_exp'
	endif
	
	wave /T w_RifirstSw=root:Results:RiFirstSw
	wave w_resultsRin=root:Results:Rinputs
	wave w_resultsVres=root:Results:Vrest
	wave /T w_resultsExp=root:Results:RinputExp
	wave w_amplresults=root:Results:Vampl_exp
	wave w_currentampl=root:Results:IDelta_exp
	
	n=DimSize(w_resultsRin,0)+1
	Redimension/N=(n,-1) w_resultsRin, w_resultsVres,w_resultsExp, w_RiFirstSw
	Redimension/N=(n, numtraces) w_amplresults, w_currentampl
	w_resultsExp[n-1]=wavebase
	
for (Runs=0;Runs<numtraces;Runs+=1)
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave
	wave w_temp=root:WorkData:$gTheWave
	if(Runs==0)
		w_RifirstSw[n-1]=gTheWave
	endif
	print "gTheWave = ", gTheWave
	SetDataFolder root:WorkData
	VCursor=mean($gTheWave, x0, x1)
	print "VCursor =", VCursor
//	print "n = ", n
	print "Sweep no = ",Runs
	SetDataFolder root:Results
	Vampl_exp[n-1][Runs]=VCursor										//read off voltages
	IDelta_exp[n-1][Runs]=-((numtraces-1)*gDeltaI)+(Runs*gDeltaI)				//calculate injected currents
	SetDataFolder root:OrigData
	DisplayNextWave(gWaveList)
	
endfor

SetDataFolder root:Results
Vrest[n-1]=Vampl_exp[n-1][numtraces-1]		//last sweep is at I=0 injected current
for (Runs=0;Runs<numtraces;Runs+=1)
	Vampl_exp[n-1][Runs]-=Vrest[n-1]			//Subtracting resting membrane voltage so we get the voltage difference
endfor
CurveFit/Q/M=2/W=0 line, Vampl_exp[n-1][*]/X=IDelta_exp[n-1][*]/D
String Holding="W_coef"
Wave Coeff= $Holding
Rinputs[n-1]=Coeff[1]*1e12						//Resistance
SetDataFolder root:OrigData

end

Function APPlot()		//Programmed  by Jakob B. S�rensen in July 2021 to plot AP number

SetDataFolder root:Results:
If(Waveexists($"NumAP_exp")==0)
	DoAlert 0, "You have to count APs before you can plot them"
	abort
endif
wave w_NAP=root:Results:NumAP_exp
wave w_DeltaI=root:Results:IDelta_exp
variable k, numtraces
numtraces=Dimsize(w_NAP,0)
Display NumAP_exp[1][] vs IDelta_exp[1][]
ModifyGraph mode=4
for (k=2;k<numtraces;k+=1)
  AppendToGraph NumAP_exp[k][] vs IDelta_exp[k][]
  ModifyGraph mode=4
endfor
SetDataFolder root:

End

Function APCount()		//Programmed by Jakob B. S�rensen in July 2021 to allow rapidly counting the number of AP from a number of current clamp sweeps, with increasing current amplitudes.
SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
NVAR gDeltaIAP=root:Globals:gDeltaIAP
NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gWaveindex=root:Globals:gWaveindex
wave w_temp=root:OrigData:$gTheWave

variable x0, x1, str, Runs, numtraces, n, swnum, threshold=0, peaksfound, startP, endP
string tempwave, wavebase, expwaves, list, firstsw

x0=xcsr(A, "Experiments")
x1=xcsr(B, "Experiments")
SetDataFolder root:
ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		Variable/G gCursorA=x0, gCursorB=x1					// Fixed cursors 
	endif

SetDataFolder root:OrigData
str=strsearch(gTheWave,"AP",0)
wavebase=gTheWave[0,str-1]		//wavebase contains the experiment number
print "wavebase ", wavebase
expwaves=Wavelist(wavebase+"*", ";", "")		//expwaves identifies the sweeps in the expeirments.
print "expwave =", expwaves
numtraces=ItemsInList(expwaves)
print "numtraces = ", numtraces				//numtraces are the number of sweeps in the experiments
firstsw=Stringfromlist(0,expwaves)
swnum= WhichListItem(firstsw, gWaveList)
if (swnum!=gWaveindex)						//this is a loop that resets the gWaveindex to the first sweep, if this is not already the case
	SetDataFolder root:globals
	gWaveindex=swnum-1					//gWaveindex is set to swnum-1, because it is incremented by one in DisplayNextWave
	print "cursors not on first sweep - replotting first sweep and calculating from there!"
	DisplayNextWave(gWaveList)
endif
	
SetDataFolder root:Results
	if (WaveExists('APFirstSw')==0)		//Wave for saving experiment names
		Make/T/N=(1) 'APFirstSw'
	endif
	if (WaveExists('APExp')==0)		//Wave for saving experiment names
		Make/T/N=(1) 'APExp'
	endif
	if (WaveExists('NumAP_exp')==0)		//Wave for saving Number of APs at each sweep
		Make/N=(1,numtraces) 'NumAP_exp'
	endif
		if (WaveExists('IDelta_exp')==0)		//Wave for saving IDelta values at each sweep 
		Make/N=(1,numtraces) 'IDelta_exp'
	endif
	
	wave /T w_APfirstSw=root:Results:APFirstSw
	wave /T w_resultsAP=root:Results:APExp
	wave w_NAPresults=root:Results:NumAP_exp
	wave w_currentampl=root:Results:IDelta_exp
	
	n=DimSize(w_resultsAP,0)+1
	Redimension/N=(n,-1) w_resultsAP, w_APfirstSw
	Redimension/N=(n,numtraces) w_NAPresults, w_currentampl
	w_resultsAP[n-1]=wavebase
	

for (Runs=0;Runs<numtraces;Runs+=1)
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave
	wave w_temp=root:WorkData:$gTheWave
	if(Runs==0)
		w_APfirstSw[n-1]=gTheWave
	endif
	print "gTheWave = ", gTheWave
	SetDataFolder root:WorkData
	print "Sweep no = ",Runs
	startP=pcsr(A, "Experiments")
	endP=pcsr(B, "Experiments")
	peaksfound=0
	do
		FindPeak/B=(9)/M=(threshold)/P/Q/R=[startP,endP] $gTheWave
		if(V_Flag != 0)			//if a peak is found
			break
		endif
		peaksfound+=1
		startP=x2pnt($gTheWave, pnt2x($gTheWave, V_PeakLoc)+0.0014)		// AP peaks cannot be closer to each other than 1.4 ms. 
	while(peaksfound<100)
	print "number of peaks found = ", peaksfound
	w_NAPresults[n-1][Runs]=peaksfound
	w_currentampl[n-1][Runs]=(Runs+1)*gDeltaIAP	
	SetDataFolder root:OrigData
	DisplayNextWave(gWaveList)
endfor

end

Function APTab()		//programmed by Jakob B. S�rensen in July 2021 to allow tabulation of AP properties
SetDataFolder root:Results

If(Waveexists($"APAnaExp")==0)
	DoAlert 0, "You have to analyze some APs before you can tabulate their parameters"
	abort
endif
Edit APAnaExp,Thres,APovers,APampl,APhalfw,AHPampl,APrateup,APratedown,APAccept

SetDataFolder root:
end

Function APAna()		//Programmed by Jakob B. S�rensen in July 2021 to allow determination of AP properties from current clamp recording.
SVAR gTheWave=root:Globals:gTheWave, gWaveList=root:Globals:gWaveList
NVAR gDeltaIAP=root:Globals:gDeltaIAP
NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gWaveindex=root:Globals:gWaveindex
wave w_temp=root:OrigData:$gTheWave
wave /T w_exp=root:experimentwave

variable x0, x1, x2, x3, str, n, k, V_halfw
string wavebase, Diffwave, temstr, OKstring, NotOKstring

OKstring="OK"
NotOKstring="Invalid"

x0=xcsr(A, "Experiments")
x1=xcsr(B, "Experiments")
x2=xcsr(C, "Experiments")
x3=xcsr(D, "Experiments")

SetDataFolder root:OrigData
str=strsearch(gTheWave,"AP",0)
wavebase=gTheWave[0,str-1]		//wavebase contains the experiment number
print "wavebase ", wavebase

SetDataFolder root:Results
	if (WaveExists('APAnaExp')==0)		//Wave for saving experiment names
		Make/T/N=(1) 'APAnaExp'
	endif
	if (WaveExists('Thres')==0)		//Wave for saving voltage Threshold
		Make/N=(1) 'Thres'
	endif
	if (WaveExists('APovers')==0)		//Wave for saving AP overshoot
		Make/N=(1) 'APovers'
	endif
	if (WaveExists('APampl')==0)		//Wave for saving AP amplitude
		Make/N=(1) 'APampl'
	endif
	if (WaveExists('APhalfw')==0)		//Wave for saving AP halfwidth
		Make/N=(1) 'APhalfw'
	endif
	if (WaveExists('AHPampl')==0)		//Wave for saving After Hyperpolarization amplitude
		Make/N=(1) 'AHPampl'
	endif
	if (WaveExists('APrateup')==0)		//Wave for saving max rate of AP upstroke
		Make/N=(1) 'APrateup'
	endif
	if (WaveExists('APratedown')==0)		//Wave for saving max rate of AP downstroke
		Make/N=(1) 'APratedown'
	endif
	if(WaveExists('APValData')==0)	//Wave for saving Y-Data for plotting
		Make/N=(1,5) 'APValData'
	endif
		if(WaveExists('APXData')==0)	//Wave for saving X-data for plotting
		Make/N=(1,5) 'APXData'
	endif
	if (WaveExists('APAccept')==0)		//Wave for saving experiment names
		Make/N=(1) 'APAccept'
	endif

	wave /T w_exp=root:Results:APAnaExp
	wave w_Thres=root:Results:Thres
	wave w_APovers=root:Results:APovers	
	wave w_APampl=root:Results:APAmpl
	wave w_APhalfw=root:Results:APhalfw
	wave w_AHPAmpl=root:Results:AHPAmpl
	wave w_APrateup=root:Results:APrateup
	wave w_APratedown=root:Results:APratedown
	wave w_APValData=root:Results:APValData
	wave w_APXData=root:Results:APXData
	wave w_APAccept=root:Results:APAccept
		
	n=DimSize(w_exp,0)+1
	Redimension/N=(n,-1) w_exp, w_Thres, w_APovers, w_APampl, w_APhalfw, w_AHPAmpl, w_APrateup, w_APratedown, w_APAccept
	Redimension/N=(n,5) w_APValData, w_APXData
	w_exp[n-1]=gTheWave
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave
	wave w_temp=root:WorkData:$gTheWave
	print "gTheWave = ", gTheWave
	SetDataFolder root:WorkData
	Diffwave=gTheWave+"_D"
	print "Diffwave = ", Diffwave
	duplicate/O $gTheWave $Diffwave
	differentiate $Diffwave
	//bpc_FilterGauss(root:WorkData:$Diffwave,1000,0)
	//AppendToGraph/R/W=Experiments $Diffwave
	FindPeak/B=(9)/M=(0)/Q/R=(x0,x1) $gTheWave
	print "Found AP at ",V_PeakLoc
	print "AP amplitude is ", V_PeakVal
	w_APXData[n-1][0]=V_PeakLoc		//Storing position of peak and X-value
	w_APValData[n-1][0]=V_PeakVal
	w_APovers[n-1]=V_PeakVal
	FindLevel /EDGE=1/Q/R=(x0,V_PeakLoc) $Diffwave,10		//threshold is where the rate of voltage-increase passes 10 mV/ms
	if(V_flag==0)
		w_Thres[n-1]=w_temp(V_LevelX)
		w_APXData[n-1][1]=V_LevelX		//Storing position of threshold crossing and X-value
		w_APValData[n-1][1]=w_Thres[n-1]
		w_APampl[n-1]=w_APovers[n-1]-w_Thres[n-1]		//Amplitude from threshold to AP peak.
		V_halfw=0.5*(w_APovers[n-1]-w_Thres[n-1])+w_Thres[n-1]
		FindLevel /EDGE=1/Q/R=(w_APXData[n-1][1],V_PeakLoc) $gTheWave,V_halfw
		w_APXData[n-1][2]=V_LevelX		//Storing position of peak and X-value of halfpoint on the upslope
		w_APValData[n-1][2]=w_temp(V_LevelX)
		FindLevel /EDGE=2/Q/R=(w_APXData[n-1][0],x1) $gTheWave,V_halfw
		w_APXData[n-1][3]=V_LevelX		//Storing position of peak and X-value of halfpoint on the downslope
		w_APValData[n-1][3]=w_temp(V_LevelX)
		w_APhalfw[n-1]=w_APXData[n-1][3]-w_APXData[n-1][2]
		Wavestats /Q/R=(w_APXData[n-1][1],w_APXData[n-1][0]) $Diffwave
		w_APrateup[n-1]=V_max
		Wavestats /Q/R=(w_APXData[n-1][0],w_APXData[n-1][0]+w_APhalfw[n-1]) $Diffwave
		w_APratedown[n-1]=V_min
		if(x2>x1)							//if cursor C is localized to the right of cursor B, the afterhyperpolarization potential is determined, relative to threshold
			print "determining AHP "
			Wavestats /Q/R=(x1, x2) $gTheWave
			w_AHPAmpl[n-1]=mean($gTheWave,V_minloc-0.00025,V_minloc+0.00025)
			w_APValData[n-1][4]=w_AHPAmpl[n-1]
			w_AHPAmpl[n-1]-=w_Thres[n-1]				//AHP is determined relative to threshold!
			w_APXData[n-1][4]=V_minloc	//Storing position of minimum of AHP
			SetAxis/W=Experiments bottom x0-0.02, x2+0.02
		else
			print "NOT determining AHP "
			w_AHPAmpl[n-1]=NaN
			SetAxis/W=Experiments bottom x0-0.02, x1+0.02
		endif
		AppendToGraph/L/W=Experiments w_APValData[n-1][] vs w_APXData[n-1][]
		temstr=NameOfWave(w_APValData)
		ModifyGraph/W=Experiments mode($temstr)=3
		SetAxis/W=Experiments/A left
		Doalert 1, "Accept parameters?"
			w_APAccept[n-1]=V_flag
		else
		Abort "Cannot find AP threshold. Quitting..."
	endif
end



Function FitDExp()			// This Function programmed by Jakob B. S�rensen July 2014. Changed in April 2020 to allow fitting with single-exponential function.
	SVAR gTheWave=root:Globals:gTheWave
	Variable n
	NVAR gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gWeight=root:Globals:gFitweight, gWaveindex=root:Globals:gWaveindex, gExponentials=root:Globals:gExponents
	wave/Z/T experimentwave=root:experimentwave

	variable EndWeight, length, Dfit0, Amp1C, Amp2C
	SetDataFolder root:Results
		if (WaveExists(FitParameters)==0)
			Make/N=(1,10)/T FitParameters
			FitParameters[0][0] = "Wave"
			FitParameters[0][1] = "Total Charge"
			FitParameters[0][2] = "Amp1"
			FitParameters[0][3] = "Tau1"
			FitParameters[0][4] = "Amp2"
			FitParameters[0][5] = "Tau2"
			FitParameters[0][6] = "Amp1/(Amp1+Amp2)"
			FitParameters[0][7] = "FitStart"	
			FitParameters[0][8] = "Weighting"
			FitParameters[0][9] = "Chisquare"		
		endif
	wave/T w_results=root:Results:FitParameters

	n=DimSize(w_results,0)+1
	Redimension/N=(n,-1) w_results
	SetDataFolder root:WorkData:integral
	if(Waveexists($gTheWave)==0)
		DoAlert 0,"First, you have to press Charge Transfer, to integrate your reponse"
		abort
	endif
	Duplicate /O $gTheWave Weightf
	Weightf=1
	EndWeight= x2pnt($gTheWave,(xcsr(A, "Experiments")+(xcsr(B, "Experiments")/gWeight)))
	Weightf[pcsr(A, "Experiments"),EndWeight]=gWeight
	print "gExponentials =", gExponentials
	if(gExponentials==2)									//For double exponential fitting
		Make /O/T/N=(2) T_constraints
		T_Constraints[0]="K1 > 0"
		T_Constraints[1]="K3 > 0"
		CurveFit/NTHR=0/L=2000 dblexp_XOffset $gTheWave[pcsr(A, "Experiments"),pcsr(B, "Experiments")] /D /W=Weightf  /C=T_Constraints 
		gCursorA=xcsr(A,"Experiments")
		gCursorB=xcsr(B,"Experiments")
		String Holding="W_coef"
		Wave Coeff= $Holding
		//Correction for missing amplitude
		Dfit0=Coeff(1)/Coeff(2)+Coeff(3)/Coeff(4)
		Amp1C=Coeff(1)-(Coeff(0)+Coeff(1)+Coeff(3))*(Coeff(1)/Coeff(2))/Dfit0
		Amp2C=Coeff(3)-(Coeff(0)+Coeff(1)+Coeff(3))*(Coeff(3)/Coeff(4))/Dfit0
		//Report results
		w_results[n][0] += experimentwave[gWaveindex]
		w_results[n][1] += num2str(Coeff(0))
		w_results[n][2] += num2str(Amp1C)
		w_results[n][3] += num2str(Coeff(2))
		w_results[n][4] += num2str(Amp2C)
		w_results[n][5] += num2str(Coeff(4))
		w_results[n][6] += num2str(Coeff(1)/(Coeff(1)+Coeff(3)))
		w_results[n][7] += num2str(gCursorA)
		w_results[n][8] += num2str(gWeight)
		w_results[n][9] += num2str(V_chisq)
	endif
	if(gExponentials==1)									//For double exponential fitting
		Make /O/T/N=(1) T_constraints
		T_Constraints[0]="K1 > 0"
		CurveFit/NTHR=0/L=2000 exp_XOffset $gTheWave[pcsr(A, "Experiments"),pcsr(B, "Experiments")] /D /W=Weightf  /C=T_Constraints 
		gCursorA=xcsr(A,"Experiments")
		gCursorB=xcsr(B,"Experiments")
		String Holding1="W_coef"
		Wave Coeff1= $Holding1
		//Correction for missing amplitude
		Dfit0=Coeff1(1)/Coeff1(2)
		Amp1C=-Coeff1(0)
		//Report results
		w_results[n][0] += experimentwave[gWaveindex]
		w_results[n][1] += num2str(Coeff1(0))
		w_results[n][2] += num2str(Amp1C)
		w_results[n][3] += num2str(Coeff1(2))
		w_results[n][4] += ""
		w_results[n][5] += ""
		w_results[n][6] +=  num2str(1)
		w_results[n][7] += num2str(gCursorA)
		w_results[n][8] += num2str(gWeight)
		w_results[n][9] += num2str(V_chisq)
	endif
	SetDataFolder root:OrigData
	
End


Function Trains()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainStim=root:Globals:gTrainStim, TrainFreq=root:TrainFreq
	variable x0,dx,x1,freq, p1, p2
	variable i, j, k, nmax, n, ip1, ip2
	string activetrace, destwavename, syncdestwavename, asyncdestwavename, ipwavename
	variable fitmax
	wave/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants
	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=x1-x0
	p1=xcsr(C, "Experiments")
	p2=xcsr(D, "Experiments")

	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave					// Make a work copy of our wave
	wave/Z w_temp=root:WorkData:$gTheWave	
	ipwavename=gTheWave+"_IP"
	duplicate/O $gTheWave root:WorkData:$ipwavename
	duplicate/O/R=(x0,p2+gTrainStim/TrainFreq) $gTheWave root:WorkData:w_sync_raw	
	wave/Z w_interpolate=root:WorkData:$ipwavename	
	w_interpolate=NaN			
	ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)	
	AppendToGraph/C=(0,39168,0) w_temp							// Add the copied graph to see the changes
	j=0
	BlankArtifactInTrain(w_temp,x0,x1,TrainFreq,gTrainStim)			// Get rid of the Artifacts
	SetDataFolder root:WorkData
	Make/O/T/N=1 T_Constraints									// Make constraints for the fit
	T_Constraints[0] = {"K1 < 0"}
	destwavename="root:WorkData:fits:"+gTheWave+"_reconst"		// Make a destination wave for the fit
	duplicate/O w_temp $destwavename							// Make sure it has the same length as the Original Wave
	wave/Z DestWave=$destwavename
	DestWave=NaN
	CurveFit/Q/NTHR=1/ODR=0/N/X exp_XOffset w_temp(p1+j/TrainFreq,p2+j/TrainFreq) /C=T_Constraints /D=DestWave
	do
		PauseUpdate
//		destwavename="root:WorkData:fits:"+gTheWave+"exp"+num2str(j)		// Make a destination wave for the fit
//		CurveFit/Q/NTHR=1/ODR=0/N/X exp_XOffset w_temp(p1+j/TrainFreq,p2+j/TrainFreq) /C=T_Constraints /D=DestWave
		DestWave[x2pnt(DestWave, p1+j/TrainFreq), x2pnt(DestWave, x1+(j+1)/TrainFreq)]=W_coef[0]+W_coef[1]*exp(-(x-W_fitConstants[0])/W_coef[2])
//		AppendToGraph/W=Experiments DestWave
//		ModifyGraph rgb($destwavename)=(0,0,0)
//		ip1=x2pnt(w_interpolate, x1+(j+1)/TrainFreq)
//		ip2=x2pnt(w_interpolate, x1+(j+1)/TrainFreq)
//		w_interpolate[ip1,ip2]=W_coef[0]+W_coef[1]*exp(-(x-W_fitConstants[0])/W_coef[2])
//		if (w_interpolate[ip1]>0)
//			w_interpolate[ip1,ip2]=0
//		endif
		j += 1
	while (j<gTrainStim)
//	ipwavename=gTheWave+"_IPx"
//	interpolate2/T=1/Y=root:workdata:$ipwavename w_interpolate
//	wave/Z w_interpolated=root:workdata:$ipwavename
//	AppendToGraph w_interpolated
//	SetAxis/A
//	wave/Z w_sync=root:WorkData:w_sync_raw
//	w_sync=NaN
//	w_sync=w_temp-w_interpolated
//	i=numpnts(w_sync)
//	k=0
//	do
//		if (w_sync[k]>0)
//			w_sync[k]=0
//			w_interpolated[k]=w_interpolated[k]-w_sync[k]
//		endif
//	while (k<i)
//	syncdestwavename=gTheWave+"_sync"
//	asyncdestwavename=gTheWave+"_async"
//	integrate w_sync /D=root:results:$syncdestwavename
//	integrate w_interpolated /D=root:results:$asyncdestwavename
//	wave/Z w_result_sync=root:results:$syncdestwavename
//	wave/Z w_result_async=root:results:$asyncdestwavename
//	SetDataFolder root:Results
//	ResumeUpdate
//	Display/N=Release w_result_sync
//	ModifyGraph/W=Release rgb=(0,0,0)
//	AppendToGraph/W=Release w_result_async
//	ModifyGraph rgb($asyncdestwavename)=(0,52224,0)
//	SetAxis/A/R left 
	
End

Function Recovery()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gRecStim=root:Globals:gRecStim, gRecFreq=root:Globals:gRecFreq, gRecISI=root:Globals:gRecISI, gRescueN=root:Globals:gRescueN
	variable x0,dx,x1
	variable j, n
	string activetrace, destwavename
	variable  xfit, leak, amp, fitmax
	wave/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants

	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=x1-x0
	
	SetDataFolder root:Results
		if (WaveExists(RescueR)==0)
			Make/N=(1,101) RescueR
		endif
		SetDataFolder root:OrigData
		duplicate/O $gTheWave root:WorkData:$gTheWave
		wave w_temp=root:WorkData:$gTheWave
		ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
		AppendToGraph/C=(0,39168,0) w_temp
		wave w_results=root:Results:RescueR
		n=DimSize(w_results,0)+1
		Redimension/N=(n,-1) w_results
		j=0
		BlankArtifactInTrain(w_temp,x0,x1,gRecFreq, gRecStim)
		PauseUpdate
		wavestats/Q/M=1/R=(x0+dx+j/gRecFreq,x0-dx+(j+1)/gRecFreq) w_temp
		amp=V_min
//		xfit=V_minloc
		w_results[n][0] += (amp)
//		destwavename=gTheWave+"_exp_"+num2str(j)
//		duplicate/O w_temp $destwavename   //Create a template for the fit wave with corresponding X axis
//		wave DestWave=$destwavename
//		DestWave=NaN
//		CurveFit/Q/NTHR=1/ODR=2/N/X/K={xfit} exp_XOffset  w_temp(xfit,xfit+(1/gRecFreq)-dx) /D=DestWave
//		DestWave[x2pnt(DestWave, xfit), x2pnt(DestWave, x1+(j+1)/gRecFreq)]=W_coef[0]+W_coef[1]*exp(-(x-W_fitConstants[0])/W_coef[2])					
//		AppendToGraph DestWave
 		j=(gRecStim-1)
 //		wavestats/Q/M=1 DestWave
//		FitMax=V_Max
		wavestats/Q/M=1/R=(x0+dx+j/gRecFreq,x0-dx+(j+1)/gRecFreq) w_temp
		amp=V_min
		FitMax=faverage(w_temp,x0+dx+j/gRecFreq,x0-dx+(j+1)/gRecFreq)
		w_results[n][1] += (amp-FitMax)
		x0=x0+(26/1000)+gRecISI/1000		//add the ISI to the last Train Stimulus
		w_temp[x2pnt(w_temp,x0+j/gRecFreq),x2pnt(w_temp,0.000025+x0+j/gRecFreq+dx)]=w_temp[x2pnt(w_temp,x0+j/gRecFreq)-1] // interpolate Testpulse Artifact
		leak=faverage(w_temp,x0+j/gRecFreq,0.000025+x0+j/gRecFreq+dx)  // Get the actual baseline without the sustained component
		wavestats/Q/M=1/R=(x0+dx+j/gRecFreq,x0-(0.5*dx)+(j+1)/gRecFreq) w_temp
		w_results[n][2] += V_min-leak
		SetAxis/A
		ResumeUpdate
SetDataFolder root:
End


Function Trains_Charge()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainStim=root:Globals:gTrainStim, gTrainFreq=root:Globals:gTrainFreq, gBackExtrN=root:Globals:gBackExtrN
	variable x0,dx,x1,freq
	variable j, nmax, n
	variable Init_amp, Init_charge, baseline, Baseline_charge, amp, charge, areatemp, offset1, offset2, interval
	variable x2, y1, y2
	String nametemp, destwavename, Fitwave, CCwave, fitText

		
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=x1-x0
	
	variable cols=gTrainStim
	
	SetDataFolder root:Results	//make sure data folder exists	
	SetDataFolder root:Results
		if (WaveExists(TrainAmp_Csync)==0)
			Make/N=(1,cols) TrainAmp_Csync
		endif
		if (WaveExists(TrainAmp_CAsync)==0)
			Make/N=(1,cols) TrainAmp_CAsync
		endif
		if (WaveExists(TrainAmp_CAll)==0)
			Make/N=(1,cols) TrainAmp_CAll
		endif
		if (WaveExists(TrainAmp_CCum)==0)
			Make/N=(1,cols) TrainAmp_CCum
		endif
		if (WaveExists(TrainAmp_CSyncCum)==0)
			Make/N=(1,cols) TrainAmp_CSyncCum
		endif
		if (WaveExists(TrainAmp_CASyncCum)==0)
			Make/N=(1,cols) TrainAmp_CASyncCum
		endif
		if (WaveExists(TrainAmp_Csync_PPR)==0)
			Make/N=(1,cols) TrainAmp_Csync_PPR
		endif
		if (WaveExists(TrainAmp_CAsync_PPR)==0)
			Make/N=(1,cols) TrainAmp_CAsync_PPR
		endif
		if (WaveExists(TrainAmp_CAll_PPR)==0)
			Make/N=(1,cols) TrainAmp_CAll_PPR
		endif
		if (WaveExists(TrainAmp_CCum_PPR)==0)
			Make/N=(1,cols) TrainAmp_CCum_PPR
		endif
		if (WaveExists(TrainAmp_CSyncCum_PPR)==0)
			Make/N=(1,cols) TrainAmp_CSyncCum_PPR
		endif
		if (WaveExists(TrainAmp_CASyncCum_PPR)==0)
			Make/N=(1,cols) TrainAmp_CASyncCum_PPR
		endif
		
	SetDataFolder root:Results:Backextr		
		if (WaveExists(TrainBackextr_RRP)==0)
			Make/N=(1) TrainBackextr_RRP
		endif
		if (WaveExists(TrainBackextr_Prate)==0)
			Make/N=(1) TrainBackextr_Prate
		endif
		if (WaveExists(TrainBackextr_RelPr)==0)
			Make/N=(1) TrainBackextr_RelPr
		endif
		if (WaveExists(TrainBackextr_OK)==0)
			Make/T/N=(1) TrainBackextr_OK
		endif
			Fitwave=gTheWave+"_fit"
		Make/O/N=(2) $Fitwave
			CCwave=gTheWave+"_CC"
		Make/O/N=(gTrainStim) $CCwave
		SetDataFolder root:Results
		
		wave/Z w_temp=root:WorkData:$gTheWave									// Make references to used waves
		wave/Z w_results=root:Results:TrainAmp_Csync							//Charge, syncronous
		wave/Z w_Aresults=root:Results:TrainAmp_CAsync						//Charge, asyncronous
		wave/Z w_Allresults=root:Results:TrainAmp_CAll						//Charge, syncronous+asyncronous
		wave/Z w_Cumresults=root:Results:TrainAmp_CCum						//Cumulative charge, syncronous+asyncronous
		wave/Z w_SyncCumresults=root:Results:TrainAmp_CSyncCum				//Cumulative charge, syncronous
		wave/Z w_ASyncCumresults=root:Results:TrainAmp_CASyncCum			//Cumulative charge, asyncronous
		wave/Z w_resultsPPR=root:Results:TrainAmp_Csync_PPR					//PPR, Charge, syncronous
		wave/Z w_AresultsPPR=root:Results:TrainAmp_CAsync_PPR				//PPR, Charge, asyncronous
		wave/Z w_AllresultsPPR=root:Results:TrainAmp_CAll_PPR				//PPR, Charge, syncronous+asyncronous
		wave/Z w_CumresultsPPR=root:Results:TrainAmp_CCum_PPR				//PPR, Cumulative charge, syncronous+asyncronous
		wave/Z w_SyncCumresultsPPR=root:Results:TrainAmp_CSyncCum_PPR		//PPR, Cumulative charge, syncronous
		wave/Z w_ASyncCumresultsPPR=root:Results:TrainAmp_CASyncCum_PPR	//PPR, Cumulative charge, asyncronous
		wave/Z w_BExtrRRP=root:Results:Backextr:TrainBackextr_RRP
		wave/Z w_BExtrPrate=root:Results:Backextr:TrainBackextr_Prate
		wave/Z w_BExtrRelPr=root:Results:Backextr:TrainBackextr_RelPr
		wave/T/Z w_BExtrRelOK=root:Results:Backextr:TrainBackextr_OK
		wave/Z w_CCwave=root:Results:Backextr:$CCwave
		wave/Z w_fitwave=root:Results:Backextr:$Fitwave
		
		n=DimSize(w_results,0)+1
		Redimension/N=(n,-1) w_results, w_Aresults, w_Allresults, w_Cumresults, w_SyncCumresults, w_ASyncCumresults
		Redimension/N=(n,-1) w_resultsPPR, w_AresultsPPR, w_AllresultsPPR, w_CumresultsPPR, w_SyncCumresultsPPR, w_ASyncCumresultsPPR
		Redimension/N=(n,-1) w_BExtrRRP, w_BExtrPrate,  w_BExtrRelPr, w_BExtrRelOK
		j=0
		do
			PauseUpdate
				Init_charge=area(w_temp, x0+dx+j/gTrainFreq, x0+dx+(j+1)/gTrainFreq)
				x1=x0+dx+j/gTrainFreq
				x2=x0+dx+(j+1)/gTrainFreq
				y1=w_temp(x0+dx+j/gTrainFreq)
				y2=w_temp(x0+dx+(j+1)/gTrainFreq)
				Baseline_charge=0.5*(y1+y2)*(x2-x1)
			//	area(w_temp, x0+j/gTrainfreq,x0+dx+j/gTrainfreq)*interval
			//	print "BL_charge = ",Baseline_charge		
				charge=Init_charge-Baseline_charge
			//	print "charge = ",charge
				w_results[n-1][j] = (charge)
				w_Aresults[n-1][j] = (Baseline_charge)
				w_Allresults[n-1][j] = (charge)+(Baseline_charge)
				if(j==0)
					w_SyncCumresults[n-1][j] = w_results[n-1][j]
					w_ASyncCumresults[n-1][j] = w_Aresults[n-1][j]
					w_Cumresults[n-1][j] = (charge)+(Baseline_charge)
				else
					w_SyncCumresults[n-1][j] = w_results[n-1][j] + w_SyncCumresults[n-1][j-1]
					w_ASyncCumresults[n-1][j] = w_Aresults[n-1][j] + w_ASyncCumresults[n-1][j-1]
					w_Cumresults[n-1][j] = (charge)+(Baseline_charge) + w_Cumresults[n-1][j-1]
				endif
				//w_Cumresults[n-1][j]*=-1
				w_CCwave[j] = -w_Cumresults[n-1][j]
				j += 1
		while (j<gTrainStim)
		
		w_Cumresults[n-1][,*] *= -1
		w_SyncCumresults[n-1][,*] *= -1
		w_ASyncCumresults[n-1][,*] *= -1
		
		w_resultsPPR[n-1][1,*] = w_results[n-1][q] / w_results[n-1][q-1]
		w_AresultsPPR[n-1][1,*] = w_Aresults[n-1][q] / w_Aresults[n-1][q-1]
		w_AllresultsPPR[n-1][1,*] = w_Allresults[n-1][q] / w_Allresults[n-1][q-1]
		w_CumresultsPPR[n-1][1,*] = w_Cumresults[n-1][q] / w_Cumresults[n-1][q-1]
		w_SyncCumresultsPPR[n-1][1,*] = w_SyncCumresults[n-1][q] / w_SyncCumresults[n-1][q-1]
		w_ASyncCumresultsPPR[n-1][1,*] = w_ASyncCumresults[n-1][q] / w_ASyncCumresults[n-1][q-1]
		
		ControlInfo /W=NeuroBunny checkAsyncTRAIN
		if (V_Value==1)
			if(gTrainStim>(gBackExtrN+4))
				Display /N=Backextr w_CCwave
				SetAxis/A/E=1 left
				Curvefit line w_CCwave [gTrainStim-(gBackExtrN+1),gTrainStim-1]
				wave/Z W_coef=root:Results:W_coef
				w_BExtrRRP[n-1] +=W_coef[0]
				w_BExtrPrate[n-1] +=W_coef[1]*gTrainFreq
				w_BExtrRelPr[n-1] += w_CCwave[0]/W_coef[0]
				w_fitwave[0]=W_coef[0]
				w_fitwave[1]=W_coef[0]+(W_coef[1]*(gTrainStim-1))
				SetScale/P x 0,gTrainStim-1,"", w_fitwave
				ModifyGraph mode=0
				ModifyGraph lsize=1.0,rgb=(0,0,0)
				AppendtoGraph w_fitwave		
				ModifyGraph mode=4
				sprintf fitText, "RRP =%gC \rSusR=%gC/s \rRelProb =%g", W_coef[0], W_coef[1]*gTrainFreq, w_CCwave[0]/W_coef[0] 
				TextBox/C/N=FitResults fitText
				TextBox/C/N=FitResults/A=LT/X=58.25/Y=68.12
				Label bottom "# stimulation"
				Label left "\\EC"
				DoAlert 1, "Do you accept this backextrapolation?"
				if(V_flag==1)
					w_BExtrRelOK[n-1]="OK"
				else
					w_BExtrRelOK[n-1]="Bad"
				endif
				DoWindow/K Backextr
			endif
		else
			KillWaves w_CCwave, w_fitwave
		endif
End


Function/S get_protocolname(gTheWave_str)
	string gTheWave_str

	string p
	sscanf gTheWave_str, "%*[^_]%*[_]%[^_]", p
	return p

End

//New version to get protocolname using RegEx matching -AdrianGR
//RegEx pattern can be optionally supplied when calling, but note that there should only be one capture group in the pattern
Function/S get_protocolname2(gTheWave_str, [regExPattern])
	String gTheWave_str
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "^x[0-9]{1,2}X?(.+)_[0-9]{1,2}_[0-9]{1,2}_[0-9]{3}_[0-9]{1,2}_.+$"	//If RegEx pattern has not been supplied, default to this (made based on test string "x2X20Hz_50_9s_1_1_001_1_I-mon")
	endif
	string p
	
	SplitString/E=regExPattern gTheWave_str, p
	if(V_flag != 1)
		p = get_protocolname(gTheWave_str)								//If not exactly one match was found, default to old version of get_protocolname
	endif
	
	return p
End


// Save cursor positions to a wave. -AdrianGR
Function saveCursors(expNameRef, curA, curB, curC, curD, flag_Overwrite)
	String expNameRef
	Variable curA, curB, curC, curD, flag_Overwrite //Cursor positions input + flag for overwriting old positions if present
	String comboString = expNameRef+";"+num2str(curA)+";"+num2str(curB)+";"+num2str(curC)+";"+num2str(curD) //Make a list string
	Make/O/T/N=(1) tempCursorWave
	tempCursorWave[0] = comboString
	
	if(WaveExists(savedCursorPos)==0)
		Make/O/T/N=(0) savedCursorPos
	endif
	
	Variable found, foundWhere, curA_old, curB_old, curC_old, curD_old //The last four parameters are not used, but have to be declared
	//[found, foundWhere] = cursorSaveCheck(expNameRef) //Get info on whether these cursor positions have been previously saved
	[found, foundWhere, curA_old, curB_old, curC_old, curD_old] = getSavedCursors(expNameRef) //Get info on whether these cursor positions have been previously saved
	
	if(found==0) //Save cursor positions because it does not already exist
		Concatenate/NP=0/T {tempCursorWave}, savedCursorPos
	elseif(found==1 && flag_Overwrite==1) //Overwrite previously saved cursor positions
		savedCursorPos[foundWhere] = tempCursorWave[0]
	elseif(found==1 && flag_Overwrite==0) //Cursor positions previously saved, but not overwritten with new positions
		DoAlert 0, "Cursors have been previously saved, but overwrite flag was not set to 1, so new positions were not saved."
	else
		DoAlert 0, "Something went wrong when saving cursors"
	endif
	
	KillWaves tempCursorWave //Cleanup of temporary wave
End

// Retrieve saved cursor positions if they exist. -AdrianGR
Function [Variable flag_Found, Variable foundIndex, Variable curA, Variable curB, Variable curC, Variable curD] getSavedCursors (String inString)
	flag_Found = 0
	Wave/T/Z savedCursorPos = root:savedCursorPos
	Variable i = 0
	
	if(WaveExists(savedCursorPos)==0)
		//print("No cursors have been saved at all! Returning [0,-1,-1,-1,-1,-1]")
		return [0,-1,-1,-1,-1,-1]
	elseif(WaveExists(savedCursorPos)==1)
		for(i=0; i<DimSize(savedCursorPos, 0); i+=1)
			if(FindListItem(inString, savedCursorPos[i])>=0)
				flag_Found += 1
				foundIndex = i
			endif
		endfor
		
		if(flag_Found==1)
			curA = str2num(StringFromList(1,savedCursorPos[foundIndex]))
			curB = str2num(StringFromList(2,savedCursorPos[foundIndex]))
			curC = str2num(StringFromList(3,savedCursorPos[foundIndex]))
			curD = str2num(StringFromList(4,savedCursorPos[foundIndex]))
			return [flag_Found, foundIndex, curA, curB, curC, curD]
		elseif(flag_Found==0)
			return [0,-1,-1,-1,-1,-1]
		else
			DoAlert 0, "Something went wrong while checking if cursors have been saved."
			print("The string was found " + num2str(flag_Found) + " times, which should not happen")
		endif
	endif
End

Structure paramGuesses
	Variable K0g, K1g, K2g, K3g, K4g
EndStructure

Function/WAVE generateGuesses(inWave, fromX, toX, fitType, fitname)
	Wave inWave
	Variable fromX, toX
	String fitType, fitname
	Duplicate/O/R=(fromX,toX) inWave, tempWave
	tempWave = -tempWave
	STRUCT paramGuesses here
	
	strswitch(fitType)
		case "dblexp_XOffset":
			Make/O/D/N=(5) temp_kwCWave
			CurveFit/X=0/O/Q dblexp_XOffset, kwCWave=temp_kwCWave, tempWave
			print temp_kwCWave
			//temp_kwCWave = -temp_kwCWave
			here.K0g = temp_kwCWave[0]
			return temp_kwCWave
		break
	endswitch
End


Function Trains_Amp()
// Analysis Function for Trains. Modified version by Jakob 31-07-2014 to include amplitude to baseline and delays.
// Heavily modified by AdrianGR during summer of 2024.
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainfreq=root:Globals:gTrainfreq, gTrainStim=root:Globals:gTrainStim, gWaveindex=root:Globals:gWaveindex

	variable x0,x1,dx,x2
	variable j, nmax, n, m, amplitude, leak
	Variable V_FitOptions=4
	Variable V_FitMaxIters=80
	string activetrace, destwavename, fit_name
	variable amp, fitmax, xfit, baseline, Init_amp, Init_baseline
	Variable DoCharge=Nan
	variable/G cursorA_orig,cursorB_orig,cursorC_orig
	variable vmin_cache
	Variable a
	Variable recEnd
	
	variable post_pulse_baseline, V_avg, i_loc//, K0 //K0 should not be declared because it is a system variable! -AdrianGR
	
	//Section added to enable retrieval of saved cursor positions/saving new cursor positions -AdrianGR
	ControlInfo/W=NeuroBunny checkFixCursors
	Variable flag_checkFixCursors = V_Value
	ControlInfo/W=NeuroBunny chk_IgnoreSavedCursors
	Variable flag_IgnoreSavedCursors = V_Value
	Variable cursorsFound, cursorsFoundIndex, curA, curB, curC, curD
	[cursorsFound, cursorsFoundIndex, curA, curB, curC, curD] = getSavedCursors(gTheWave)
	
	if(cursorsFound==1 && flag_IgnoreSavedCursors==0 && flag_checkFixCursors==0)
		print("Saved cursors found. Will be used for analysis.")
		x0=curA
		x1=curB
		dx=curB-curA
		x2=curC
	elseif(cursorsFound==0 || flag_IgnoreSavedCursors==1 || flag_checkFixCursors==1)
		print("Using new (or fixed) cursors for analysis and saving them.")
		x0=xcsr(A, "Experiments")
		x1=xcsr(B, "Experiments")
		dx=xcsr(B, "Experiments")-xcsr(A, "Experiments")
		x2=xcsr(C, "Experiments")
		curD=xcsr(D, "Experiments")
		saveCursors(gTheWave,x0,x1,x2,curD,1)
	endif
	

	Variable cols = gTrainStim
	SetDataFolder root:Results
	if (WaveExists('TrainAmp_Sync')==0)		//Wave for saving Amplitudes to last level ('synchronous')
		Make/N=(1,cols) 'TrainAmp_Sync'
	endif
	if (WaveExists('TrainAmp_Sync_Norm')==0)		//Wave for saving Amplitudes to last level ('synchronous') - normalized
		Make/N=(1,cols) 'TrainAmp_Sync_Norm'
	endif
	if (WaveExists('TrainAmp_All')==0)		//Wave for saving Amplitudes to baseline ('all')
		Make/N=(1,cols) 'TrainAmp_All'
	endif
	if (WaveExists('TrainAmp_Delay')==0)		//Wave for saving Delays from start of artefact to max PSC amplitude
		Make/N=(1,cols) 'TrainAmp_Delay'
	endif
	if (WaveExists('TrainExperiments')==0)		//Wave for saving File name
		Make/T/N=(1) 'TrainExperiments'
	endif
	if (WaveExists('TrainExperiments_protocol')==0)		//Wave for saving protocol name
		Make/T/N=(1) 'TrainExperiments_protocol'
	endif
	if (WaveExists('TrainExperiments_folder')==0)		//Wave for saving file path -AdrianGR
		Make/T/N=(1) 'TrainExperiments_folder'
	endif
	if (WaveExists('TrainAmp_corrected')==0)		//Wave for saving Amplitudes calculated from decay fitting
		Make/N=(1,cols) 'TrainAmp_corrected'
	endif
	if (WaveExists('TrainAmp_fromInitBaseline')==0)		//Wave for saving amplitudes to level of end of previous pulse //-AdrianGR
		Make/N=(1,cols) 'TrainAmp_fromInitBaseline'
	endif
	if (WaveExists('TrainAmp_fromInitBaseline_Norm')==0)		//Wave for saving normalized amplitudes to level of end of previous pulse //-AdrianGR
		Make/N=(1,cols) 'TrainAmp_fromInitBaseline_Norm'
	endif
//	if (WaveExists('TrainAmp_ASyncAUC')==0)		//Wave for saving asyncronous AUC (aka. async. 'charge') for each pulse -AdrianGR
//		Make/N=(1,cols) 'TrainAmp_ASyncAUC'
//	endif
//	if (WaveExists('TrainAmp_ASyncLineX')==0)		//Wave for saving async. release X-coordinates -AdrianGR
//		Make/N=(1,cols+1) 'TrainAmp_ASyncLineX'
//	endif
//	if (WaveExists('TrainAmp_ASyncLineY')==0)		//Wave for saving async. release Y-coordinates -AdrianGR
//		Make/N=(1,cols+1) 'TrainAmp_ASyncLineY'
//	endif
//	if (WaveExists('TrainAmp_SyncAUC')==0)			//Wave for saving syncronous AUC (aka. sync. 'charge') for each pulse -AdrianGR
//		Make/N=(1,cols) 'TrainAmp_SyncAUC'
//	endif
//	if (WaveExists('TrainAmp_baselineX')==0)		//Wave for saving baseline X-coordinates -AdrianGR
//		Make/N=(1,cols+1) 'TrainAmp_baselineX'
//	endif
//	if (WaveExists('TrainAmp_baselineY')==0)		//Wave for saving baseline Y-coordinates -AdrianGR
//		Make/N=(1,cols+1) 'TrainAmp_baselineY'
//	endif
//	if (WaveExists('TrainAmp_ASyncAUC_cumulative')==0)	//Wave for saving cumulative async. AUC -AdrianGR
//		Make/N=(1,cols) 'TrainAmp_ASyncAUC_cumulative'
//	endif
//	if (WaveExists('TrainAmp_SyncAUC_cumulative')==0)	//Wave for saving cumulative sync. AUC -AdrianGR
//		Make/N=(1,cols) 'TrainAmp_SyncAUC_cumulative'
//	endif
	if (WaveExists('TrainAmp_CTimepoints')==0)			//Wave for saving timing of each stimulation -AdrianGR
		Make/D/N=(1,cols) 'TrainAmp_CTimepoints'
	endif
	if (WaveExists('TrainAmp_RecovAmpFrac')==0)	//Wave for saving ... -AdrianGR
		Make/N=(1,cols) 'TrainAmp_RecovAmpFrac'
	endif
	if (WaveExists('TrainExperiments_allInfo')==0)		//Wave for saving lots of info -AdrianGR
		Make/T/N=(1,1) 'TrainExperiments_allInfo'
	endif
	if (WaveExists('TrainAmp_All_PPR')==0)		//Wave for saving 'all' PPRs -AdrianGR
		Make/N=(1,cols) 'TrainAmp_All_PPR'
	endif
	if (WaveExists('TrainAmp_fromInitBaseline_PPR')==0)		//Wave for saving 'fromInitBaseline' PPRs -AdrianGR
		Make/N=(1,cols) 'TrainAmp_fromInitBaseline_PPR'
	endif
	if (WaveExists('TrainAmp_Sync_PPR')==0)		//Wave for saving sync PPRs -AdrianGR
		Make/N=(1,cols) 'TrainAmp_Sync_PPR'
	endif
	
	
	
	if(WaveExists(root:WorkData:W_coef)==0)	//Make coefficient wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_coef
	endif
	if(WaveExists(root:WorkData:W_fitConstants)==0)	//Make fitConstants wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_fitConstants
	endif
	
	
	wave/D/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants //Made into double precision waves as recommended in manual -AdrianGR
	wave/Z/T experimentwave=root:experimentwave
	wave/Z/T folder=root:Data:folder
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave
	wave w_temp=root:WorkData:$gTheWave
	ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
	AppendToGraph/C=(0,39168,0) w_temp
	
	wave w_resSync=root:Results:TrainAmp_Sync
	wave w_resSync_Norm=root:Results:TrainAmp_Sync_Norm
	wave w_resAll=root:Results:TrainAmp_All
	wave w_resDel=root:Results:TrainAmp_Delay
	wave w_resCorr=root:Results:TrainAmp_corrected
	wave /T w_resExp=root:Results:TrainExperiments
	wave /T w_resPro=root:Results:TrainExperiments_protocol
	wave /T w_resFolder=root:Results:TrainExperiments_folder
	
	//-AdrianGR
	Wave w_resFromInitBL = root:Results:TrainAmp_fromInitBaseline
	Wave w_resFromInitBL_Norm = root:Results:TrainAmp_fromInitBaseline_Norm
//	Wave w_resASyncAUC = root:Results:TrainAmp_ASyncAUC
//	Wave w_resASyncLineX = root:Results:TrainAmp_ASyncLineX
//	Wave w_resASyncLineY = root:Results:TrainAmp_ASyncLineY
//	Wave w_baselineX = root:Results:TrainAmp_baselineX
//	Wave w_baselineY = root:Results:TrainAmp_baselineY
//	Wave w_resSyncAUC = root:Results:TrainAmp_SyncAUC
//	Wave w_resASyncAUC_cumulative = root:Results:TrainAmp_ASyncAUC_cumulative
//	Wave w_resSyncAUC_cumulative = root:Results:TrainAmp_SyncAUC_cumulative
	Wave w_resCTimepoints = root:Results:TrainAmp_CTimepoints
	Wave w_resRecAF = root:Results:TrainAmp_RecovAmpFrac
	Wave/T w_resExpAll = root:Results:TrainExperiments_allInfo
	Wave w_resAllPPR = root:Results:TrainAmp_All_PPR
	Wave w_resFromInitBL_PPR = root:Results:TrainAmp_fromInitBaseline_PPR
	Wave w_resSyncPPR = root:Results:TrainAmp_Sync_PPR
	
	
	//Wave w_
	
	Variable avgT = 0.001	//define length of time interval for averaging, e.g. 2 ms -AdrianGR
	Variable avgT2 = avgT//was supposed to be slightly longer interval for initial and final baseline, but got too complicated, so is now just the same as avgT -AdrianGR
	
	n=DimSize(w_resSync,0)+1
	Redimension/N=(n,-1) w_resSync, w_resSync_Norm, w_resAll, w_resDel, w_resCorr
	Redimension/N=(n) w_resExp, w_resPro, w_resFolder
	//-AdrianGR
	Redimension/N=(n,-1) w_resFromInitBL, w_resFromInitBL_Norm//, w_resASyncAUC, w_resASyncLineX, w_resASyncLineY, w_baselineX, w_baselineY, w_resSyncAUC
//	Redimension/N=(n,-1) w_resASyncAUC_cumulative, w_resSyncAUC_cumulative
	Redimension/N=(n,-1) w_resCTimepoints, w_resRecAF, w_resSyncPPR
	Redimension/N=(n,-1) w_resAllPPR, w_resFromInitBL_PPR, w_resSyncPPR
	
	BlankArtifactInTrain(w_temp,x0,x1,gTrainfreq,gTrainStim,AverageT=avgT)
	n -= 1
	j=0
	
	SetDataFolder root:WorkData:
	
	WaveStats/Q/M=1/R=(pnt2x(w_temp, numpnts(w_temp)-1)-avgT2, pnt2x(w_temp,numpnts(w_temp)-1)) w_temp //Averaging over avgT2 to get final baseline (at end of wave) -AdrianGR
	post_pulse_baseline = V_avg
	print "post_pulse_baseline =	", post_pulse_baseline
	
	WaveStats/Q/M=1/R=(x0-avgT2, x0) w_temp	//Averaging over avgT2 to get initial baseline (just before train starts) -AdrianGR
	Init_baseline = V_avg
	print "Init_baseline =	", Init_baseline
	
	Variable x0_cache = x0
	Variable x1_cache = x1
	Variable j_cache = j
	
	//w_temp = w_temp-Init_baseline
	
	
	DeleteAnnotations/W=Experiments/A //Deletes any previous tags (or other annotations) on the graph -AdrianGR
	
	
	//NOTE! The do-while block is an absolute mess -AdrianGR
	do //DISABLED IN CONDITIONAL
		//break
		if (j>0)
			x0+=1/gTrainfreq
			//Cursor A $gTheWave x0
			x1+=1/gTrainfreq
			//Cursor B $gTheWave x1
		endif
		
		//WaveStats/Q/M=1/R=(x1,x0+(j+1)/gTrainfreq) w_temp
		WaveStats/Q/M=1/R=(x1,x0+1/gTrainfreq) w_temp
		Init_amp = V_min
		w_resAll[n][j] = Init_Amp - Init_baseline			//Save full amplitude to zero
		w_resDel[n][j] = V_minLoc - x0						//Save delay from start of artefact to peak 
		//wavestats/Q/M=1/R=(x0,x1) w_temp
		//baseline=V_min
		WaveStats/Q/M=1/R=(x0-avgT,x0) w_temp					//averaging over avgT (to calculate last sustained level) -AdrianGR
		baseline = V_avg
		amp = Init_amp - baseline									//Save evoked amplitude (relative to last sustained level).
		w_resSync[n][j] = amp
		
		//-AdrianGR //TODO: something wrong here?
		WaveStats/Q/R=(x0-avgT,x0) w_temp								//Getting average from final avgT of previous pulse
		Variable preStimBaseline = V_avg
		WaveStats/Q/R=(x1,x0+1/gTrainfreq) w_temp
//		w_resFromInitBL[n][j] = V_min - preStimBaseline	//Amplitude from baseline as defined above
//		w_resASyncLineX[n][j] = x0								//Saving X-coordinates for tonic release
//		w_resASyncLineY[n][j] = w_temp(x0)					//Saving Y-coordinates for tonic release
		//w_resASyncLineY[n][j] = mean(w_temp,x0-avgT,x0)	//TODO: not sure if it is reasonable to take an average instead(?) -AdrianGR
		
		
		if (j>0 && x2>0 && 1==0) //DISABLED FITTING SECTION BY REQUIRING 1==0 (just while testing) -AdrianGR
		
			//K0 = post_pulse_baseline //value to which decay is expected to plateau //used as initial guess? -AdrianGR
			fit_name="fit_pulse"+num2str(j)
			duplicate/O w_temp $fit_name
			
			print("\r\n*********** "+fit_name+" ***********")
			print "K0 before fit: ", K0
			
			Make/O/D/N=(5) guessWave
			guessWave[0] = post_pulse_baseline; guessWave[1] = -9e-10; guessWave[2] = 0.005; guessWave[3] = -3e-10; guessWave[4] = 0.05
			print guessWave
			
			wavestats/Q/M=1/R=(x1-1/gTrainfreq+0.0004,x0) w_temp // finetuning point!
			
			//guessWave[,*] = 
			Make/O/D/N=(5) ttt = generateGuesses(w_temp, V_minLoc,x0-0.0001, "dblexp_XOffset", fit_name)[p]
			guessWave[1]=-ttt[1]; guessWave[2]=ttt[2]; guessWave[3]=-ttt[3]; guessWave[4]=ttt[4]
			//guessWave[1]=temp_kwCWave[1]; guessWave[1]=temp_kwCWave[1]; guessWave[1]=temp_kwCWave[1]; guessWave[1]=temp_kwCWave[1]; 
			
			// Below. Maybe change from H="10000" to H="00000" because it doesn't make sense to hold K0 at post_pulse_baseline if that is just the "expected value to plateau"? -AdrianGR
			try
				print "K coeff before guess: ", K0, K1, K2, K3, K4
				//CurveFit/X=0/O/Q/H="10000" dblexp_XOffset w_temp(V_minLoc,x0-0.0001) /D=$fit_name
				print "K coeff initial guess: ", K0, K1, K2, K3, K4
				//K0 = post_pulse_baseline
				CurveFit/X=0/H="10000"/G dblexp_XOffset, kwCWave=guessWave, w_temp(V_minLoc,x0-0.0001) /D=$fit_name //;AbortOnRTE //just so any overshoot in artifact is not used
				print "K coeff after fit: ", K0, K1, K2, K3, K4
			catch //Catches abort errors (used together with ;AbortOnRTE on previous line) and handles them without aborting the fitting -AdrianGR
				if(V_AbortCode == -4) // -4 is due to AbortOnRTE
					//flag_abort = 1
					Variable CFerror = GetRTError(1)	// GetRTError(1) clears the error after fetching it
				endif
			endtry
			
			//print V_minLoc
			
			AppendToGraph/W=Experiments $fit_name
			
			WaveStats/Q/M=1/R=(x1,x0+1/gTrainfreq) w_temp
			w_resCorr[n][j] = V_min-(W_coef[0]+W_coef[1]*exp(-((x1)-W_fitConstants[0])/W_coef[2])+W_coef[3]*exp(-((x1)-W_fitConstants[0])/W_coef[4])) //Save amplitude from second pulse on based the predicted decay of the first pulse
			
			print "w_resCorr[n][j]", w_resCorr[n][j]
			
			x2+=1/gTrainfreq
			
		else
			w_resCorr[n][j] = (amp)
		endif
		//Tag/L=2/W=Experiments/A=MB $fit_name, 100, "\\Z05\\ON" //-AdrianGR
		j += 1
	while (j < gTrainStim && 1==0)
	
	
	
	//New section replacing the old one from above. Lacks fitting. -AdrianGR
	x0 = x0_cache; x1 = x1_cache										//Reset x0 and x1 (only necessary if they are changed before this section starts) -AdrianGR
	Variable x0a, x1a
	for (a=0; a<gTrainStim; a+=1)		
		x0a = x0 + a/gTrainfreq
		x1a = x1 + a/gTrainfreq
		if (a==0)
			WaveStats/Q/M=1/R=(x0a-avgT2,x0a) w_temp				//Average over avgT2 (only for first pulse) -AdrianGR
		else
			WaveStats/Q/M=1/R=(x0a-avgT,x0a) w_temp				//Average over avgT (to calculate last sustained level) -AdrianGR
		endif
		baseline = V_avg
		WaveStats/Q/M=1/R=(x1a,x0a+1/gTrainfreq) w_temp			//Get pulse minimum (peak) -AdrianGR
		Init_amp = V_min
		w_resAll[n][a] = Init_amp - Init_baseline			//Save full amplitude to zero
		w_resDel[n][a] = V_minLoc - x0a						//Save delay from start of artefact to peak 							
		w_resSync[n][a] = Init_amp - baseline				//Save evoked amplitude (relative to last sustained level).
		
		w_resFromInitBL[n][a] = Init_amp - Init_baseline	//Amplitude from baseline as defined above
		
		
		WaveStats/Q/M=1/R=(x0+(a+1)/gTrainfreq-avgT,x0+(a+1)/gTrainfreq) w_temp		//Calculate amplitude at end of pulse -AdrianGR
		recEnd = V_avg - baseline
		w_resRecAF[n][a] = recEnd / w_resSync[n][a]											//Calculate fractional recovery relative to pulse peak -AdrianGR
		
		
//		w_resASyncLineX[n][a] = x0a									//Save X-coordinates for async release -AdrianGR
//		w_resASyncLineY[n][a] = w_temp(x0a)							//Save Y-coordinates for async release -AdrianGR
//		if (a == gTrainStim-1)															//if-statement is necessary to also save last point -AdrianGR
//			w_resASyncLineX[n][a+1] = x0a+1/gTrainfreq
//			//w_resASyncLineY[n][a+1] = w_temp(x0a+1/gTrainfreq)
//			w_resASyncLineY[n][a] = mean(w_temp,x0a-avgT,x0a)		//TODO: would it be reasonable to take an average instead? -AdrianGR
//		endif
		
		//String tempCalc
		w_resCTimepoints[n][a] = x0a - x0 + 1/gTrainfreq			//Save timing of end of stimulation pulses relative to first pulse -AdrianGR
		//w_resCTimepoints[n][a] = str2num(tempCalc)
		
	endfor
	
	Wave w_resFromInitBL_Norm = normalize2DWave(w_resFromInitBL)
	Wave w_resSync_Norm = normalize2DWave(w_resSync)
	
	
	//Calculate PPRs ('paired-pulse ratios') -AdrianGR
	w_resAllPPR[n][1,*] = w_resAll[n][q] / w_resAll[n][q-1]
	w_resFromInitBL_PPR[n][1,*] = w_resFromInitBL[n][q] / w_resFromInitBL[n][q-1]
	w_resSyncPPR[n][1,*] = w_resSync[n][q] / w_resSync[n][q-1]
	
	
	// Fitting of each pulse (decay portion) and saving fit variables in multidimensional wave -AdrianGR
	ControlInfo/W=NeuroBunny checkFitting
	if(V_Value == 1)
		if(WaveExists(root:Results:TrainAmp_fitCoefs)==0)
			Make/D/N=(5,gTrainStim,n+1) root:Results:TrainAmp_fitCoefs
			Wave resCoefs = root:Results:TrainAmp_fitCoefs
			SetDimLabel 0, 0, y0, resCoefs
			SetDimLabel 0, 1, A1, resCoefs
			SetDimLabel 0, 2, tau1, resCoefs
			SetDimLabel 0, 3, A2, resCoefs
			SetDimLabel 0, 4, tau2, resCoefs
		else
			Wave/Z resCoefs = root:Results:TrainAmp_fitCoefs
			Redimension/N=(-1,-1,n+1) resCoefs
		endif
		dx = x1 - x0
		V_FitMaxIters = 100
		for(a=0; a<gTrainStim; a+=1)
			SetDataFolder root:WorkData
			fit_name = "fit_pulse"+num2str(a)
			print "\r\n", fit_name
			Duplicate/O w_temp, $fit_name
			Wave tempFitWave = $fit_name
			tempFitWave = NaN
			WaveStats/Q/M=1/R=(x0+dx+a/gTrainfreq,x0+(a+1)/gTrainfreq) w_temp
			Variable nudge = 0.0003		//Truncate start of fitting range by 300 us
			Make/D/O/N=(5) w_fitCoef
			//Make/T/O w_fitConstraintsWave={"K0 <"+num2str(post_pulse_baseline),"K0>"+num2str(1.1*w_temp(x0+(a+1)/gTrainfreq))}
			//Wave w_constr = w_fitConstraintsWave
			CurveFit/Q/N=1 dblexp_XOffset kwCWave=w_fitCoef, w_temp(V_minLoc+nudge,x0+(a+1)/gTrainfreq) /D=$fit_name ///C=w_constr
			
			if(a==0)
				resCoefs[,*][0][n] = w_fitCoef[p]
				SetDimLabel 2, n, $gTheWave, resCoefs
				SetDimLabel 1, a, $fit_name, resCoefs
			else
				//InsertPoints/M=1 INF, 1, resCoefs
				resCoefs[,*][a][n] = w_fitCoef[p]
				SetDimLabel 1, a, $fit_name, resCoefs
			endif
			AppendToGraph/W=Experiments $fit_name
		endfor
	endif
	
	
	
	//Doesn't work properly. This section should calculate AUCs/'charge', but old method (Trains_Charge()) is better atm. -AdrianGR
//	Duplicate/O w_temp, w_temp2														//Duplicate wave so we can subtract Init_baseline
//	w_temp2 = w_temp2 - Init_baseline												//Subtract Init_baseline
//	//Duplicate/O/RMD=[n][,*] w_resASyncLineX, w_tempASyncX
//	//Duplicate/O/RMD=[n][,*] w_resASyncLineY, w_tempASyncY
//	x0 = x0_cache; x1 = x1_cache														//Reset x0 and x1 (only necessary if they are changed before this section starts) -AdrianGR
//	for (a=0; a<gTrainStim; a+=1)
//		//break
//		Duplicate/O/RMD=[n][a,a+1] w_resASyncLineX, w_tempASyncX
//		Duplicate/O/RMD=[n][a,a+1] w_resASyncLineY, w_tempASyncY
//		//w_tempASyncY = w_tempASyncY - Init_baseline
//		Make/O/D/N=(2) w_tempX
//		w_tempX[0] = x1+a/gTrainfreq
//		w_tempX[1] = x0+(a+1)/gTrainfreq
//		Variable syncPlusASyncArea = area(w_temp2, w_tempX[0], w_tempX[1])
//		Make/O/D/N=(2) w_tempY
//		w_tempY[0] = interp(w_tempX[0], w_tempASyncX, w_tempASyncY)
//		w_tempY[1] = w_tempASyncY[0][a+1]
//		w_tempY = w_tempY - Init_baseline
//		Variable ASyncArea = areaXY(w_tempX, w_tempY, w_tempX[0], w_tempX[1])
//		
//		w_resASyncAUC[n][a] = abs(ASyncArea)
//		w_resSyncAUC[n][a] = abs(syncPlusASyncArea - ASyncArea)
//	endfor
//	KillWaves w_tempASyncX, w_tempASyncY, w_tempX, w_tempY
//	
//	
//	w_resASyncAUC_cumulative[n][0] = w_resASyncAUC[n][0]
//	//w_resASyncAUC_cumulative[n][1,*] = w_resASyncAUC[n][q] + w_resASyncAUC_cumulative[n][q-1]	//this line does the same as the for-loop below -AdrianGR
//	Variable h
//	for(h=1; h<DimSize(w_resASyncAUC,1); h+=1)
//		w_resASyncAUC_cumulative[n][h] = w_resASyncAUC[n][h] + w_resASyncAUC_cumulative[n][h-1]
//	endfor
//	w_resSyncAUC_cumulative[n][0] = w_resSyncAUC[n][0]
//	//w_resSyncAUC_cumulative[n][1,*] = w_resSyncAUC[n][q] + w_resSyncAUC_cumulative[n][q-1]		//this line does the same as the for-loop below -AdrianGR
//	for(h=1; h<DimSize(w_resSyncAUC,1); h+=1)
//		w_resSyncAUC_cumulative[n][h] = w_resSyncAUC[n][h] + w_resSyncAUC_cumulative[n][h-1]
//	endfor
//	
//	//print "Total asynchronous release AUC:\t", w_resASyncAUC_cumulative[n][INF]
//	//print "Total synchronous release AUC:\t", w_resSyncAUC_cumulative[n][INF]
//	
//	
//	w_baselineX[n][,*] = w_resASyncLineX[n][q]
//	w_baselineY[n][,*] = Init_baseline
//	AppendToGraph/W=Experiments/C=(0,55555,55555) w_baselineY[n][,*] vs w_baselineX[n][,*] //In effect shows Init_baseline on graph -AdrianGR
//	
//	AppendToGraph/W=Experiments/C=(0,0,55555) w_resASyncLineY[n][,*] vs w_resASyncLineX[n][,*] //-AdrianGR
	
	
	print "n =	", n
	
	//Saving stuff in block below doesn't work properly because it doesn't take into account if there are multiple sweeps -AdrianGR
	//w_resExp[n]=experimentwave[gWaveindex]			//Save experiment name for future reference
	//w_resPro[n]=get_protocolname2(gTheWave)			//Save name of the protocol of the analyzed series
	//w_resFolder[n]=folder[gWaveindex]
	
	//New block for saving info stuff (old block above). Not certain it works on data from Pulse software -AdrianGR
	Wave/T w_extractedInfo = extractWaveListInfo()
	w_resExp[n] = w_extractedInfo[%exper][gWaveindex]
	w_resPro[n] = w_extractedInfo[%protocol][gWaveindex]
	w_resFolder[n] = w_extractedInfo[%folder][gWaveindex]
	Make/T/O/N=(DimSize(w_extractedInfo,1),DimSize(w_extractedInfo,0)) w_extractedInfo_T
	w_extractedInfo_T[][] = w_extractedInfo[q][p]
	Redimension/N=(n+1,DimSize(w_extractedInfo,0)) w_resExpAll
	for(a=0; a<DimSize(w_extractedInfo,0); a+=1)
		String dimLabel2 = GetDimLabel(w_extractedInfo,0,a)
		SetDimLabel 1, a, $dimLabel2, w_extractedInfo_T
		SetDimLabel 1, a, $dimLabel2, w_resExpAll
	endfor
	for(a=0; a<DimSize(w_extractedInfo,1); a+=1)
		String dimLabel3 = GetDimLabel(w_extractedInfo,1,a)
		SetDimLabel 0, a, $dimLabel3, w_extractedInfo_T
	endfor
	w_resExpAll[n][] = w_extractedInfo_T[gWaveindex][q]
	
//	ControlInfo /W=NeuroBunny checkAsyncTRAIN
//		if (V_Value==1)
		Trains_Charge()
//		endif
	
	//Calculating and saving RTSR data ('recovery of total syncronous release') -AdrianGR
	if(WaveExists(root:WorkData:RTSR_data))
		Wave CSyncCum = root:Results:TrainAmp_CSyncCum
		SetDataFolder root:WorkData
		Wave RTSRp = RTSR_params
		Wave RTSRy = RTSR_data
		Wave RTSRx = RTSRdelay_data
		Wave/T RTSRinfo = RTSRinfo
		Variable includeInRTSR = RTSRp[0]
		Variable RTSRnum = RTSRp[1]
		Variable RTSRdelNum = RTSRp[2]
		Variable RTSRdel = RTSRp[4+RTSRdelNum]
		Variable RTSR_P = RTSRp[3]
		
		if(DimSize(RTSRy,1) < RTSRnum+1)
			Redimension/N=(-1,RTSRnum+1,-1) RTSRy, RTSRx
			RTSRy[][RTSRnum][] = RTSRy==0 ? NaN : RTSRy			//Shorthand way to say 'if value is zero, set to NaN, else leave as is'
			RTSRx[][RTSRnum][] = RTSRx==0 ? NaN : RTSRx
		endif
		if(includeInRTSR == 1)
			RTSRy[RTSRdelNum][RTSRnum][RTSR_P] = CSyncCum[n][INF]
			RTSRy[RTSRdelNum][RTSRnum][0] = NaN
		endif
		if(includeInRTSR == 1 && RTSR_P == 2)
			RTSRy[RTSRdelNum][RTSRnum][0] = RTSRy[RTSRdelNum][RTSRnum][2] / RTSRy[RTSRdelNum][RTSRnum][1]
			RTSRx[RTSRdelNum][RTSRnum] = RTSRdel
			String dimLabel = w_extractedInfo[%folderLast]+"_"+w_extractedInfo[%fileName]//+"_"+w_extractedInfo[%DayMonth]
			SetDimLabel 1, RTSRnum, $dimLabel, RTSRy, RTSRx
			Make/O/N=(DimSize(RTSRy,1),DimSize(RTSRy,0)) root:Results:TrainAmp_RTSRy/WAVE=w_resRTSRy
			w_resRTSRy[][] = RTSRy[q][p][0]
			//Duplicate/O/RMD=[,*][,*][0] RTSRy, root:Results:TrainAmp_RTSRy
			//Redimension/N=(-1,-1,0) root:Results:TrainAmp_RTSRy
			Make/O/N=(DimSize(RTSRx,1),DimSize(RTSRx,0)) root:Results:TrainAmp_RTSRx/WAVE=w_resRTSRx
			w_resRTSRx[][] = RTSRx[q][p]
			//Duplicate/O RTSRx, root:Results:TrainAmp_RTSRx
			Redimension/N=(RTSRnum+1,DimSize(w_resExpAll,1)) RTSRinfo
			RTSRinfo[RTSRnum][] = w_resExpAll[n][q]
			Duplicate/O RTSRinfo, root:Results:TrainAmp_RTSRinfo
		endif
	else
		print "RTSR calculations not performed, likely because necessary waves were not created first."
	endif
	
	
	
	
	ResumeUpdate
//	SetAxis/A
	SetDataFolder root:
		
	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		Variable/G gCursorA=x0, gCursorB=x1					// Fixed cursors 
	endif
	
	
//	if(1==0) //DISABLED
//		SetDataFolder root:Results:
//		transposeWaveMake(TrainAmp_All)
//		String refWaveList = "root:Results:TrainAmp_All;root:Results:TrainAmp_corrected;root:Results:TrainAmp_Delay;root:Results:TrainAmp_fromInitBaseline;root:Results:TrainAmp_Sync;root:Results:TrainAmp_CAll;root:Results:TrainAmp_CCum;root:Results:TrainAmp_CSync;root:Results:TrainAmp_CSyncCum;root:Results:TrainAmp_CASync;root:Results:TrainAmp_CASyncCum"
//		Make/O/WAVE refWave = ListToWaveRefWave(refWaveList)
//		
//		Concatenate/O/NP=1 {refWave}, w_resSummaryTest
//	endif
	
	
	
	
	if(dimsize(root:Results:TrainAmp_All,1)==2)
	
		SetDataFolder root:Results:
	
		Make/O/N=(dimsize(TrainAmp_All,0),0) Empty_Col
		concatenate/NP=1/O {TrainAmp_All,Empty_Col,TrainAmp_CAll,Empty_Col,TrainAmp_CAsync,Empty_Col,TrainAmp_CCum,Empty_Col,TrainAmp_corrected,Empty_Col,TrainAmp_Csync,Empty_Col,TrainAmp_Sync,Empty_Col,TrainAmp_Delay}, TrainAmp_result_summary
	
		TrainAmp_result_summary=abs(TrainAmp_result_summary)
	
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P1_cache
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P2_cache
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P3_cache

		for (i_loc=2;i_loc<=(dimsize(TrainAmp_result_summary,1))-3;i_loc+=3) //paired pulse ratio tables

			P2_cache=TrainAmp_result_summary[p][i_loc-1]
			P1_cache=TrainAmp_result_summary[p][i_loc-2]
	
			P3_cache=P2_cache/P1_cache
	
			TrainAmp_result_summary[][i_loc]=P3_cache[p]
	
		endfor
	
		concatenate/NP=1/O {TrainExperiments, TrainExperiments_protocol}, TrainAmp_result_strings
	
		Edit/K=0 root:Results:TrainAmp_result_summary
	
		ModifyTable title[1]="P1_All"
		ModifyTable title[4]="P1_CAll"
		ModifyTable title[7]="P1_CAsync"
		ModifyTable title[10]="P1_CCum"
		ModifyTable title[13]="P1_decay_corrected"
		ModifyTable title[16]="P1_Csync"
		ModifyTable title[19]="P1_Sync"
		ModifyTable title[22]="P1_Delay"
		
		ModifyTable title[2]="P2_All"
		ModifyTable title[5]="P2_CAll"
		ModifyTable title[8]="P2_CAsync"
		ModifyTable title[11]="P2_CCum"
		ModifyTable title[14]="P2_decay_corrected"
		ModifyTable title[17]="P2_Csync"
		ModifyTable title[20]="P2_Sync"
		ModifyTable title[23]="P2_Delay"
		
		ModifyTable title[3]="PPR_All"
		ModifyTable title[6]="PPR_CAll"
		ModifyTable title[9]="PPR_CAsync"
		ModifyTable title[12]="PPR_CCum"
		ModifyTable title[15]="PPR_decay_corrected"
		ModifyTable title[18]="PPR_Csync"
		ModifyTable title[21]="PPR_Sync"
		
		Edit/K=0 root:Results:TrainAmp_result_strings
		
		ModifyTable title[1]="Name"
		ModifyTable title[2]="Protocol"
	
		SetDataFolder root:
	
	endif
	
End


Function Trains_Amp_old()
// Analysis Function for Trains. Modified version by Jakob 31-07-2014 to include amplitude to baseline and delays.
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainfreq=root:Globals:gTrainfreq, gTrainStim=root:Globals:gTrainStim, gWaveindex=root:Globals:gWaveindex

	variable x0,x1,dx,x2
	variable j, nmax, n, m, amplitude, leak
	Variable V_fitOptions=4
	string activetrace, destwavename, fit_name
	variable amp, fitmax, xfit, baseline, Init_amp, Init_baseline
	Variable DoCharge=Nan
	variable/G cursorA_orig,cursorB_orig,cursorC_orig
	variable vmin_cache
	
	variable post_pulse_baseline, V_avg, i_loc, K0 //K0 should not be declared because it is a system variable! (??) -AdrianGR
	
	//Section added to enable retrieval of saved cursor positions/saving new cursor positions -AdrianGR
	ControlInfo/W=NeuroBunny chk_IgnoreSavedCursors
	variable flag_IgnoreSavedCursors = V_Value
	variable cursorsFound, cursorsFoundIndex, curA, curB, curC, curD
	[cursorsFound, cursorsFoundIndex, curA, curB, curC, curD] = getSavedCursors(gTheWave)
	
	if(cursorsFound==1 && flag_IgnoreSavedCursors==0)
		print("Saved cursors found. Will be used for analysis.")
		x0=curA
		x1=curB
		dx=curB-curA
		x2=curC
	elseif(cursorsFound==0 || flag_IgnoreSavedCursors==1)
		print("Using new cursors for analysis and saving them.")
		x0=xcsr(A, "Experiments")
		x1=xcsr(B, "Experiments")
		dx=xcsr(B, "Experiments")-xcsr(A, "Experiments")
		x2=xcsr(C, "Experiments")
		curD=xcsr(D, "Experiments")
		saveCursors(gTheWave,x0,x1,x2,curD,1)
	endif
	

	variable cols=gTrainStim
	SetDataFolder root:Results
	if (WaveExists('TrainAmp_Sync')==0)		//Wave for saving Amplitudes to last level ('synchronous')
		Make/N=(1,cols) 'TrainAmp_Sync'
	endif
	if (WaveExists('TrainAmp_All')==0)		//Wave for saving Amplitudes to baseline ('all')
		Make/N=(1,cols) 'TrainAmp_All'
	endif
	if (WaveExists('TrainAmp_Delay')==0)		//Wave for saving Delays from start of artefact to max PSC amplitude
		Make/N=(1,cols) 'TrainAmp_Delay'
	endif
	if (WaveExists('TrainExperiments')==0)		//Wave for saving File name
		Make/T/N=(1) 'TrainExperiments'
	endif
	if (WaveExists('TrainExperiments_protocol')==0)		//Wave for saving protocol name
		Make/T/N=(1) 'TrainExperiments_protocol'
	endif
	if (WaveExists('TrainAmp_corrected')==0)		//Wave for saving Amplitudes calculated from decay fitting
		Make/N=(1,cols) 'TrainAmp_corrected'
	endif
	
	if(WaveExists(root:WorkData:W_coef)==0) //Make coefficient wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_coef
	endif
	if(WaveExists(root:WorkData:W_fitConstants)==0) //Make fitConstants wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_fitConstants
	endif
	wave/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants
	wave/Z/T experimentwave=root:experimentwave
	
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave
	wave w_temp=root:WorkData:$gTheWave
	ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
	AppendToGraph/C=(0,39168,0) w_temp
	
	wave w_resultsSync=root:Results:TrainAmp_Sync
	wave w_resultsAll=root:Results:TrainAmp_All
	wave w_resultsDel=root:Results:TrainAmp_Delay
	wave w_resultsCorr=root:Results:TrainAmp_corrected
	wave /T w_resultsExp=root:Results:TrainExperiments
	wave /T w_resultsPro=root:Results:TrainExperiments_protocol
	
	n=DimSize(w_resultsSync,0)+1
	Redimension/N=(n,-1) w_resultsSync, w_resultsAll, w_resultsDel, w_resultsCorr
	Redimension/N=(n) w_resultsExp, w_resultsPro
	
	BlankArtifactInTrain(w_temp,x0,x1,gTrainfreq, gTrainStim)
	n -= 1
	j=0
	
	SetDataFolder root:WorkData:
	
	wavestats/Q/M=1/R=[numpnts(w_temp)-2001,numpnts(w_temp)-1] w_temp
	post_pulse_baseline=V_avg
	print "post_pulse_baseline =", post_pulse_baseline
	
	wavestats/Q/M=1/R=(x0,x1) w_temp
	Init_baseline=V_min
	print "Init_baseline = ",Init_baseline
	
//	Variable V_FitQuitReason //0=normal, 1=iteration limit reached, 2=user stopped fit, 3=limit of passes without decreasing chi2 reached -AdrianGR
	Variable V_FitMaxIters = 80 //Increased from default (40) because some fits terminated before finished -AdrianGR
//	String errorSummary = "Error summary after fitting:"
//	String errorSummaryNone = errorSummary
//	Variable V_FitError
//	String currentError
	
	
	DeleteAnnotations/W=Experiments/A //Deletes any previous tags (or other annotations) on the graph -AdrianGR
	
	do	
		if (j>0)
			x0+=1/gTrainfreq
			//Cursor A $gTheWave x0
			x1+=1/gTrainfreq
			//Cursor B $gTheWave x1
		endif
		
		
		wavestats/Q/M=1/R=(x1,x0+(j+1)/gTrainfreq) w_temp
		vmin_cache=V_minloc
		Init_amp=V_min-Init_baseline
		w_resultsAll[n][j] += (Init_Amp)					//Save full amplitude to zero
		w_resultsDel[n][j] += V_minloc-(x0)	//Save delay from start of artefact to peak 
		wavestats/Q/M=1/R=(x0,x1) w_temp
		baseline=V_min
		amp=Init_amp-baseline						//Save evoked amplitude (to last sustained level).
		w_resultsSync[n][j] += (amp)
		
		
//		Variable flag_abort = 0
//		Variable flag_error = 0
//		Variable flag_quit = 0
//		Variable quitReason = 0
//		V_FitError = 0
//		Variable CFError //temporary declaration - remove later -AdrianGR
	
		if (j>0 && x2>0)
		
			K0 = post_pulse_baseline //value to which decay is expected to plateau //used as initial guess? -AdrianGR
			fit_name="fit_pulse"+num2str(j)
			duplicate/O w_temp $fit_name
			
			print("\r*********** "+fit_name+" ***********")
			print "K0 before fit: ", K0
			
			wavestats/Q/M=1/R=(x1-1/gTrainfreq+0.0004,x0) w_temp // finetuning point!
			// Below. Maybe change from H="10000" to H="00000" because it doesn't make sense to hold K0 at post_pulse_baseline if that is just the "expected value to plateau"? -AdrianGR
			try
				print "K coeff before guess: ", K0, K1, K2, K3, K4
				//CurveFit/X=0/O/Q/H="10000"/G dblexp_XOffset w_temp(V_minLoc,x0-0.0001) /D=$fit_name
				print "K coeff initial guess: ", K0, K1, K2, K3, K4
				//K0 = post_pulse_baseline
				CurveFit/X=0/H="10000"/NTHR=0 dblexp_XOffset w_temp(V_minLoc,x0-0.0001) /D=$fit_name //;AbortOnRTE //just so any overshoot in artifact is not used
				print "K coeff after fit: ", K0, K1, K2, K3, K4
			catch //Catches abort errors (used together with ;AbortOnRTE on previous line) and handles them without aborting the fitting -AdrianGR
				if(V_AbortCode == -4) // -4 is due to AbortOnRTE
					//flag_abort = 1
					Variable CFerror = GetRTError(1)	// GetRTError(1) clears the error after fetching it
				endif
			endtry
			
			//CurveFit/X=0/H="10000"/NTHR=0 dblexp_XOffset  w_temp(V_minLoc,x0-0.0001) /D=$fit_name //Is this how it was in the original code?
			print "V_minLoc = ", V_minLoc
//			if(V_FitQuitReason != 0 && V_FitError != 0)
//				flag_quit = 1
//				flag_error = 1
//			elseif(V_FitQuitReason != 0)
//				//quitReason = V_FitQuitReason
//				flag_quit = 1
//			elseif(V_FitError != 0)
//				//quitReason = V_FitQuitReason
//				flag_error = 1
//			endif
			
//			if(flag_abort == 1)
//				print "flag_abort ", flag_abort
//				currentError = "\tCurveFit aborted: "+fit_name
//				currentError = currentError + "\r\t\tError message: "+GetErrMessage(CFerror)+")"
//				currentError = currentError + "\r\t\tV_FitError = "+num2str(V_FitError)+" ("+helper_VFitErrorCode(V_FitError)+")"
//				currentError = currentError + "\r\t\tV_FitQuitReason = "+num2str(V_FitQuitReason)+" ("+helper_VFitQuitReason(V_FitQuitReason)+")"
//				//errorSummary = errorSummary + currentError
//			elseif(flag_quit == 1 && flag_error == 1)
//				print "flag_quit ", flag_quit
//				currentError = "\tCurveFit quit/error: "+fit_name
//				currentError = currentError + "\r\t\tV_FitError = "+num2str(V_FitError)+" ("+helper_VFitErrorCode(V_FitError)+")"
//				currentError = currentError + "\r\t\tV_FitQuitReason = "+num2str(V_FitQuitReason)+" ("+helper_VFitQuitReason(V_FitQuitReason)+")"
//				//errorSummary = errorSummary + currentError
//			elseif(flag_quit == 1)
//				print "flag_quit ", flag_quit
//				currentError = "\tCurveFit quit: "+fit_name
//				currentError = currentError + "\r\t\tV_FitError = "+num2str(V_FitError)+" ("+helper_VFitErrorCode(V_FitError)+")"
//				currentError = currentError + "\r\t\tV_FitQuitReason = "+num2str(V_FitQuitReason)+" ("+helper_VFitQuitReason(V_FitQuitReason)+")"
//				//errorSummary = errorSummary + currentError
//			elseif(flag_error == 1)
//				print "flag_quit ", flag_quit
//				currentError = "\tCurveFit error: "+fit_name
//				currentError = currentError + "\r\t\tV_FitError = "+num2str(V_FitError)+" ("+helper_VFitErrorCode(V_FitError)+")"
//				currentError = currentError + "\r\t\tV_FitQuitReason = "+num2str(V_FitQuitReason)+" ("+helper_VFitQuitReason(V_FitQuitReason)+")"
//				//errorSummary = errorSummary + currentError
//			endif
			
//			if(flag_quit == 1 || flag_abort == 1 || flag_error == 1)
//				errorSummary = errorSummary + "\r" + currentError// + "\r\t\tK0 = "+num2str(K0)
//			endif
			
			//Reset flags
//			flag_abort = 0
//			flag_error = 0
//			flag_quit = 0
//			quitReason = 0
//			V_FitError = 0
//			V_FitQuitReason = 0
			
			//print V_minLoc
			
			AppendToGraph/W=Experiments $fit_name
			
			//Create tag arrows, with different color if there was an error during the fitting -AdrianGR
//			if(flag_abort == 1)
//				Tag/L=2/W=Experiments/A=MT/F=0/B=1/H=0/X=0/Y=-10/O=90/P=20/G=(65535,32768,32768) $fit_name, V_minLoc, "\\Z10\\ON" //-AdrianGR
//			elseif(flag_quit == 1)
//				Tag/L=2/W=Experiments/A=MT/F=0/B=1/H=0/X=0/Y=-10/O=90/P=20/G=(20000,32768,100) $fit_name, V_minLoc, "\\Z10\\ON" //-AdrianGR
//			else
//				Tag/L=2/W=Experiments/A=MT/F=0/B=1/H=0/X=0/Y=-10/O=90/P=20/G=(0,0,0) $fit_name, V_minLoc, "\\Z10\\ON" //-AdrianGR
//			endif
			
			WaveStats/Q/M=1/R=(x1,x0+1/gTrainfreq) w_temp
			w_resultsCorr[n][j] = V_min-(W_coef[0]+W_coef[1]*exp(-((x1)-W_fitConstants[0])/W_coef[2])+W_coef[3]*exp(-((x1)-W_fitConstants[0])/W_coef[4])) //Save amplitude from second pulse on based the predicted decay of the first pulse
			
			print "w_resultsCorr[n][j]", w_resultsCorr[n][j]
			
			
			x2+=1/gTrainfreq
			
		else
	
			w_resultsCorr[n][j] = (amp)
			
		endif
		
		//Tag/L=2/W=Experiments/A=MB $fit_name, 100, "\\Z05\\ON" //-AdrianGR
		
		j += 1
	while (j<(gTrainStim))
	
//	if (cmpstr(errorSummary, errorSummaryNone)==0)
//		print("\r" + errorSummary + "\rNo errors.")
//	else
//		print("\r" + errorSummary)
//	endif
	
	//print n
	w_resultsExp[n]=experimentwave[gWaveindex]			//Save experiment name for future reference
	w_resultsPro[n]=get_protocolname(gTheWave)			//Save name of the protocol of the analyzed series

//	ControlInfo /W=NeuroBunny checkAsyncTRAIN
//		if (V_Value==1)
		Trains_Charge()
//		endif
	ResumeUpdate
//	SetAxis/A
	SetDataFolder root:
		
	ControlInfo /W=NeuroBunny checkFixCursor
	if (V_Value==1)
		Variable/G gCursorA=x0, gCursorB=x1					// Fixed cursors 
	endif
	

	
	if(dimsize(root:Results:TrainAmp_All,1)==2)
	
		SetDataFolder root:Results:
	
		Make/O/N=(dimsize(TrainAmp_All,0),0) Empty_Col
		concatenate/NP=1/O {TrainAmp_All,Empty_Col,TrainAmp_CAll,Empty_Col,TrainAmp_CAsync,Empty_Col,TrainAmp_CCum,Empty_Col,TrainAmp_corrected,Empty_Col,TrainAmp_Csync,Empty_Col,TrainAmp_Sync,Empty_Col,TrainAmp_Delay}, TrainAmp_result_summary
	
		TrainAmp_result_summary=abs(TrainAmp_result_summary)
	
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P1_cache
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P2_cache
		Make/O/N=(dimsize(TrainAmp_All,0)+1,1) P3_cache

		for (i_loc=2;i_loc<=(dimsize(TrainAmp_result_summary,1))-3;i_loc+=3) //paired pulse ratio tables

			P2_cache=TrainAmp_result_summary[p][i_loc-1]
			P1_cache=TrainAmp_result_summary[p][i_loc-2]
	
			P3_cache=P2_cache/P1_cache
	
			TrainAmp_result_summary[][i_loc]=P3_cache[p]
	
		endfor
	
		concatenate/NP=1/O {TrainExperiments, TrainExperiments_protocol}, TrainAmp_result_strings
	
		Edit/K=0 root:Results:TrainAmp_result_summary
	
		ModifyTable title[1]="P1_All"
		ModifyTable title[4]="P1_CAll"
		ModifyTable title[7]="P1_CAsync"
		ModifyTable title[10]="P1_CCum"
		ModifyTable title[13]="P1_decay_corrected"
		ModifyTable title[16]="P1_Csync"
		ModifyTable title[19]="P1_Sync"
		ModifyTable title[22]="P1_Delay"
		
		ModifyTable title[2]="P2_All"
		ModifyTable title[5]="P2_CAll"
		ModifyTable title[8]="P2_CAsync"
		ModifyTable title[11]="P2_CCum"
		ModifyTable title[14]="P2_decay_corrected"
		ModifyTable title[17]="P2_Csync"
		ModifyTable title[20]="P2_Sync"
		ModifyTable title[23]="P2_Delay"
		
		ModifyTable title[3]="PPR_All"
		ModifyTable title[6]="PPR_CAll"
		ModifyTable title[9]="PPR_CAsync"
		ModifyTable title[12]="PPR_CCum"
		ModifyTable title[15]="PPR_decay_corrected"
		ModifyTable title[18]="PPR_Csync"
		ModifyTable title[21]="PPR_Sync"
		
		Edit/K=0 root:Results:TrainAmp_result_strings
		
		ModifyTable title[1]="Name"
		ModifyTable title[2]="Protocol"
	
		SetDataFolder root:
	
	endif
	
End

// -AdrianGR
Function/S helper_VFitErrorCode(errorCode)
	Variable errorCode
	String errorCodeList = "Any error;Singular matrix;Out of memory;Function returned NaN or INF;Function requested stop;Reentrant curve fitting"
	if(0 <= errorCode <= 5)
		return StringFromList(errorCode,errorCodeList)
	else
		print "Invalid error code"
	endif
End

// -AdrianGR
Function/S helper_VFitQuitReason(quitCode)
	Variable quitCode
	String quitCodeList = "Terminated normally;Iteration limit reached;User terminated fit;Limit of passes without decreasing chi2 reached"
	if(0 <= quitCode <= 3)
		String ret = StringFromList(quitCode,quitCodeList)
		return ret
	else
		print "Invalid quit code"
	endif
End


Function Trains_Amp_Auto()
// Analysis Function for automated train analysis. 
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainfreq=root:Globals:gTrainfreq, gTrainStim=root:Globals:gTrainStim, gWaveindex=root:Globals:gWaveindex, gTrainAuto=root:Globals:gTrainAuto
	wave/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants
	wave/Z/T experimentwave=root:experimentwave
	variable x0,x1,dx
	variable j, nmax, n, m, amplitude, leak, Runs
	Variable V_fitOptions=4
	string activetrace, destwavename, list
	variable amp, fitmax, xfit, baseline, Init_amp, Init_baseline
	Variable DoCharge=Nan
	
	for (Runs=0;Runs<gTrainAuto;Runs+=1)
	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=xcsr(B, "Experiments")-xcsr(A, "Experiments")
	
print "gTheWave = ", gTheWave

	variable cols=gTrainStim
	SetDataFolder root:Results
		if (WaveExists('TrainAmp_Sync')==0)		//Wave for saving Amplitudes to last level ('synchronous')
			Make/N=(1,cols) 'TrainAmp_Sync'
		endif
		if (WaveExists('TrainAmp_All')==0)		//Wave for saving Amplitudes to baseline ('all')
			Make/N=(1,cols) 'TrainAmp_All'
		endif
		if (WaveExists('TrainAmp_Delay')==0)		//Wave for saving Delays from start of artefact to max PSC amplitude
			Make/N=(1,cols) 'TrainAmp_Delay'
		endif
		if (WaveExists('TrainExperiments')==0)		//Wave for saving Delays from start of artefact to max PSC amplitude
			Make/T/N=(1) 'TrainExperiments'
		endif
		SetDataFolder root:OrigData
		duplicate/O $gTheWave root:WorkData:$gTheWave
		wave w_temp=root:WorkData:$gTheWave
		ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
		AppendToGraph/C=(0,39168,0) w_temp
		
		wave w_resultsSync=root:Results:TrainAmp_Sync
		wave w_resultsAll=root:Results:TrainAmp_All
		wave w_resultsDel=root:Results:TrainAmp_Delay
		wave /T w_resultsExp=root:Results:TrainExperiments
		n=DimSize(w_resultsSync,0)+1
		Redimension/N=(n,-1) w_resultsSync, w_resultsAll, w_resultsDel
		Redimension/N=(n) w_resultsExp
		
		BlankArtifactInTrain(w_temp,x0,x1,gTrainfreq, gTrainStim)
		n -= 1
		j=0
		SetDataFolder root:WorkData:
		
		wavestats/Q/M=1/R=(x0+j/gTrainfreq,x0+dx+j/gTrainfreq) w_temp
		Init_baseline=V_min
		
		do				
				wavestats/Q/M=1/R=(x0+dx+j/gTrainfreq,x0-dx+(j+1)/gTrainfreq) w_temp
				Init_amp=V_min-Init_baseline
				w_resultsAll[n][j] += (Init_Amp)					//Save full amplitude to zero
				w_resultsDel[n][j] += V_minloc-(x0+j/gTrainfreq)	//Save delay from start of artefact to peak 
				wavestats/Q/M=1/R=(x0+j/gTrainfreq,x0+dx+j/gTrainfreq) w_temp
				baseline=V_min
				amp=Init_amp-baseline						//Save evoked amplitude (to last sustained level).
				w_resultsSync[n][j] += (amp)
			j += 1
		while (j<(gTrainStim))
	print n
	w_resultsExp[n]=experimentwave[gWaveindex]			//Save experiment name for future reference

	ControlInfo /W=NeuroBunny checkAsyncTRAIN
		if (V_Value==1)
		Trains_Charge()
		endif
	ResumeUpdate
//	SetAxis/A
	SetDataFolder root:
	
	Variable/G gCursorA=x0, gCursorB=x1					// Fixed cursors 
	
	DisplayNextWave(list)
	
	endfor
		
End

Function STP()
// Analysis Function for Trains of 5 stimuli. Decays are fittet to extrapolate the baseline, especially for high-frequency stimulations. // procedure corrected and changed by Jakob B. S�rensen on 23. May 2021.
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gSTPfreq=root:Globals:gSTPfreq
	wave/Z W_coef=root:WorkData:W_coef, W_fitConstants=root:WorkData:W_fitConstants
	variable x0,x1,dx
	variable j, nmax, n, m, amplitude, leak
	Variable V_fitOptions=4
	string activetrace, destwavename
	variable amp, fitmax, xfit
	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=xcsr(B, "Experiments")-xcsr(A, "Experiments")
	
	SetDataFolder root:Results
		if (WaveExists('STP_R')==0)
			Make/N=(1,6) 'STP_R'
		endif
		SetDataFolder root:OrigData
		duplicate/O $gTheWave root:WorkData:$gTheWave
		wave w_temp=root:WorkData:$gTheWave
		ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
		AppendToGraph/C=(0,39168,0) w_temp
		wave w_results=root:Results:STP_R
		n=DimSize(w_results,0)+1
		Redimension/N=(n,-1) w_results
		BlankArtifactInTrain(w_temp,x0,x1,gSTPfreq, 5)
		n -= 1
		j=0
		destwavename=gTheWave+"STP"+num2str(j)		// Make a destination wave for the fit
		print "destwavename = ",destwavename
		duplicate/O w_temp root:WorkData:fits:$destwavename								// Make sure it has the same length as the Original Wave
		wave DestWave=root:WorkData:fits:$destwavename
		DestWave=NaN
		AppendToGraph DestWave
		SetDataFolder root:WorkData:
		Make/O/N=3 W_coef, W_fitConstants
		W_coef=0
		do
			PauseUpdate
			if (j==0)				// First EPSC begins at the Baseline, so it can be measured directly without baseline adjustment
				wavestats/M=1/R=(x0+dx+j/gSTPfreq,x0+(j+1)/gSTPfreq) w_temp
				amp=V_min
				xfit=V_minloc
				w_results[n][j] += (amp)
				SetDataFolder root:WorkData:
				CurveFit/NTHR=1/ODR=2/N/X/K={xfit} exp_XOffset  w_temp(xfit,x0+(j+1)/gSTPfreq) 			// Fit the EPSC decay
				print "W_coef[0] = ", W_coef[0]
				print "W_fitConstants[0] =", W_fitConstants[0]
				DestWave[x2pnt(DestWave, xfit), x2pnt(DestWave, x0+((j+2)/gSTPfreq))]=W_coef[0]+W_coef[1]*exp(-(x-W_fitConstants[0])/W_coef[2])	// Draw the fit into the DestWave
				print "EPSC #",num2str(j+1)
				printf "Ampl_Abs: %g, Baseline: Zero\r", amp	
 			else
				SetDataFolder root:WorkData:
				wavestats/Q/M=1/R=(x0+dx+j/gSTPfreq,x0+(j+1)/gSTPfreq) w_temp
				amp=V_min
				xfit=V_minloc
				w_results[n][j] += amp-DestWave(V_minloc)
				print "EPSC #",num2str(j+1)
				printf "Ampl_Abs: %g, Baseline: %g\r", amp, DestWave(V_minloc)
				CurveFit/Q/NTHR=1/ODR=2/N/X/K={xfit} exp_XOffset  w_temp(xfit,x0+(j+1)/gSTPfreq) /D=DestWave
				SetDataFolder root:WorkData:fits:
				print "W_coef[0] = ", W_coef[0]
				print "W_fitConstrants[0] =", W_fitConstants[0]
				DestWave[x2pnt(DestWave, xfit), x2pnt(DestWave, x0+((j+2)/gSTPfreq))]=W_coef[0]+W_coef[1]*exp(-(x-W_fitConstants[0])/W_coef[2])					
			endif
			j += 1
		while (j<5)
	ResumeUpdate
	SetAxis/A
	SetDataFolder root:
End


Function STP_Async()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gSTPfreq=root:Globals:gSTPfreq
	variable x0,x1,x2, dx
	variable j, nmax, n, m, amplitude, leak, charge
	string activetrace, destwavename, nametemp
	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=xcsr(B, "Experiments")-xcsr(A, "Experiments")
	x2=xcsr(C, "Experiments")
//	offset1=xcsr(C, "Experiments")
//	offset2=xcsr(D, "Experiments")
	
	SetDataFolder root:Results
		if (WaveExists('aSTP_R')==0)
			Make/N=(1,3) 'aSTP_R'
		endif
		nametemp=wavename("",0,1)	//get wavename
		SetDataFolder root:OrigData
		duplicate/O $gTheWave root:WorkData:$gTheWave
		wave w_temp=root:WorkData:$gTheWave
		ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
		AppendToGraph/C=(0,39168,0) w_temp
		wave w_results=root:Results:aSTP_R
		n=DimSize(w_results,0)+1
		Redimension/N=(n,-1) w_results
		BlankArtifactInTrain(w_temp,x0,x1,gSTPfreq, 5)
		n -= 1
		j=0
		SetDataFolder root:WorkData:
		PauseUpdate
//		wavestats/Q/M=1/R=(x0+dx,x0-dx+(3*((5)/gSTPfreq))) w_temp
//		charge=area(w_temp, x0+dx+j/gSTPfreq, x0-dx+(3*((5)/gSTPfreq)))
		wavestats/Q/M=1/R=(x1+j/gSTPfreq,x0+(j+1)/gSTPfreq) w_temp
		charge=area(w_temp, x1+j/gSTPfreq, x0+(j+1)/gSTPfreq)
		w_results[n][0] += (charge)
		w_results[n][1] += (V_min)
		w_results[n][2] += (V_minloc)
		ResumeUpdate
		SetAxis/A
End

function normalize_STP()
variable i,l

SetDataFolder root:Results
wave STP_R
Duplicate/O STP_R, STP_Normalized

for (i=0;i<=4;i+=1)

	STP_Normalized[][i]/=STP_R[p][0]

endfor
end

//Function ReleaseFFT ()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainStim=root:Globals:gTrainStim, gTrainFreq=root:Globals:gTrainFreq
	NVAR gMiniRise=root:Globals:gMiniRise, gMiniTau1=root:Globals:gMiniTau1, gMiniTau2=root:Globals:gMiniTau2, gMiniAmplitude=root:Globals:gMiniAmplitude, gMiniAlpha=root:Globals:gMiniAlpha
	variable result, i, Iamp
	variable x0, x1, dx
	variable rise=gMiniRise, Tau1=gMiniTau1, Tau2=gMiniTau2, rel=gMiniAlpha, amp=gMiniAmplitude, cut=1000
	string destwavename
	
	
	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=x1-x0

	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave					// Make a work copy of our wave
	wave/Z w_temp=root:WorkData:$gTheWave	

	SetDataFolder root:WorkData
	Make/O/N=6/D dc_Params={100e-6,200e-6,2e-3,0.1,-30e-12,1000}		// Make parameter Wave for deconvolution and give some defaults
	
	DoAlert 2, "Do you want to fit a Mini first?"
	if (V_Flag==1)		//	Yes pressed
		FitMini()	
	elseif (V_Flag==2)	//	No pressed
	endif

	Prompt rise, "Rise time (s):"
	Prompt Tau1, "Fast decay (s):"
	Prompt Tau2, "Slow decay (s):"
	Prompt rel, "Relative amount of slow decay (%):"
	Prompt amp, "Amplitude (A):"
	Prompt cut, "Gauss Filter Cut-Off (Hz):"
	DoPrompt "Enter mEPSC properties", rise, Tau1, Tau2, rel, amp, cut	// Prompt for the Mini Properties
	dc_Params={rise, Tau1, Tau2, rel, amp, cut}
	
	i=0
	do
		w_temp[x2pnt(w_temp,x0+i/gTrainfreq),x2pnt(w_temp,0.000025*i+x1+i/gTrainfreq)]=(w_temp((0.000025*i+x1+i/gTrainfreq))-w_temp((x0+i/gTrainfreq)))/((0.000025*i+x1+i/gTrainfreq)-(x0+i/gTrainfreq))*(x-(x0+i/gTrainfreq))+w_temp((x0+i/gTrainfreq))  // interpolate aritfacts
		i += 1
	while (i<gTrainStim)
	
	DeletePoints 0,200,w_temp					// Delete Testpulse
	InsertPoints 0,200,w_temp						// Fill in zero for deleted Testpulse
	destwavename="root:Deconvolution:d_"+gTheWave
	duplicate/O w_temp $destwavename
	wave/Z Deconvolution=$destwavename
	SetScale d 0,0,"Vesicles/ms",Deconvolution
	
	bpc_DeconvolveFFT(w_temp,dc_Params,Deconvolution,0)				// Calculate Vesicular Release Rate
	result=bpc_DeconvolveFFT(w_temp,dc_Params,Deconvolution,0)
	print imag(RESULT)
	print real(RESULT)
	Smooth/B=16 8,Deconvolution
	
	ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
	AppendToGraph/C=(0,39168,0) w_temp
	AppendToGraph/C=(0,15000,39168)/R Deconvolution
	
	destwavename="root:Deconvolution:rRate:"+gTheWave+"INT"
	Integrate/T Deconvolution/D=$destwavename
	AppendToGraph/C=(50000,0,0)/R $destwavename
	destwavename="root:Deconvolution:d_"+gTheWave
	SetDataFolder root:Deconvolution
	ModifyGraph/Z lsize($destwavename)=1.5
End


Function ReleaseSumIntegral()
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainStim=root:Globals:gTrainStim, gTrainFreq=root:Globals:gTrainFreq
	variable result, i
	variable x0, x1, dx
	string destwavename
	
	SetDataFolder root:OrigData
	duplicate/O $gTheWave root:WorkData:$gTheWave					// Make a work copy of our wave
	wave/Z w_temp=root:WorkData:$gTheWave	
	SetDataFolder root:WorkData

	x0=xcsr(A, "Experiments")
	x1=xcsr(B, "Experiments")
	dx=x1-x0
	
	i=0
	do
		w_temp[x2pnt(w_temp,x0+i/gTrainFreq),x2pnt(w_temp,0.000025*i+x1+i/gTrainFreq)]=(w_temp((0.000025*i+x1+i/gTrainFreq))-w_temp((x0+i/gTrainfreq)))/((0.000025*i+x1+i/gTrainFreq)-(x0+i/gTrainFreq))*(x-(x0+i/gTrainFreq))+w_temp((x0+i/gTrainFreq))  // interpolate aritfacts
		i += 1
	while (i<gTrainStim)
	
	wavestats/Q/M=1/R=(x0+dx,x0-dx+1/gTrainfreq) w_temp
	w_temp=w_temp/V_min*(-1)

	DeletePoints 0,200,w_temp					// Delete Testpulse
	InsertPoints 0,200,w_temp						// Fill in zero for deleted Testpulse

	ModifyGraph/W=Experiments lsize=1.0,rgb=(52224,52224,52224)
	AppendToGraph/C=(0,39168,0) w_temp

	destwavename="root:WorkData:"+gTheWave+"INT"
	Integrate/T w_temp/D=$destwavename
	AppendToGraph/C=(50000,0,0)/R $destwavename
	SetAxis/A/R right
	
	
End


Function InterpolateArtifact(w,x0,x1)
	wave w
	variable x0,x1
	variable p0, p1
	variable y, extrapolate
	
	p0=x2pnt(w,x0)
	p1=x2pnt(w,x1)
	w[p0,p1]=(w(x1)-w(x0))/(x1-x0)*(x-x0)+w(x0)
End


Function BlankArtifactInTrain(w,x0,x1,freq,num_stim,[AverageT]) //Added AverageT as optional parameter -AdrianGR
	wave w
	variable x0,x1 //x-coordinates of first artifact
	variable freq,num_stim
	variable AverageT
	if (ParamIsDefault(AverageT))
		AverageT = 0.001
	endif
	variable i, TempAverage
	
	for(i=0; i<num_stim; i+=1)
		//WaveStats/Q/M=1/R=(x0+i/freq-AverageT,x0+i/freq) w
		//TempAverage = V_avg
		TempAverage = mean(w, x0+i/freq-AverageT, x0+i/freq)
		w[x2pnt(w, x0+i/freq), x2pnt(w, x1+i/freq)] = TempAverage
	endfor
	
//	i=0
//	do
//		TempAverage = mean(w, x0+i/freq-AverageT,pnt2x(w,x2pnt(w,x0+i/freq)-1)) 	//Added by Jakob to average over 1 ms
////		w[x2pnt(w,x0+i/freq),x2pnt(w,0.000025*i+x1+i/freq)]=w[x2pnt(w,x0+i/freq)-1]
//		w[x2pnt(w,x0+i/freq),x2pnt(w,0.000025*i+x1+i/freq)]=TempAverage
//		i += 1
//	while (i<num_stim)
End


Function RemTestPulse(w)
	string w
	string x
	
	x="f_"+w
	wave s=$x
	Deletepoints 0, 200, s
End

Function FilterFolder()
	String wavenow
	Variable n=0
	SVAR gWaveList=root:Globals:gWaveList
	
	wavenow = StringFromList(n, gWaveList)	// Get the first wave name
	Do
		if (strlen(wavenow) == 0)
			DoAlert 0,"Ran out of waves!"			// Ran out of waves
			break
		else
			wavenow = StringFromList(n, gWaveList)	// Get the next wave name
//			Deletepoints 0, 200, root:OrigData:$wavenow				// Delete the test pulse
//			RemTestPulse(wavenow)					// Delete the test pulse
			//bpc_FilterGauss(root:OrigData:$wavenow,500,0)			// Gauss filter the waves at 1kHz
			n+=1	
		endif
	While(1)
End
	
Function/S WavesAverage(baseName, destName)
	String baseName // name for source wave
	String destName // name for destination wave
	String wn // contains the name of a particular wave
	String wl // contains a list of wave names
	Variable index=0
// get list of waves whose names start with baseName
	wl = WaveList(baseName+"*", ";", "")
// Make destination wave based on the first source wave
	wn = StringFromList(0, wl)
	Duplicate/O $wn, $destName
	WAVE dest = $destName // create wave reference for destination
	dest = 0
	do
		wn = StringFromList(index, wl) // get next wave
		if (strlen(wn) == 0) // no more names in list?
			break // break out of loop
		endif
		WAVE source = $wn // create wave reference for source
		dest += source // add source to dest
		index += 1
	while (1) // do unconditional loop
	dest /= index // divide by number of waves
	return GetWavesDataFolder(dest,2)// string is full path to wave
End	

Function/S BuildFolderList()
	String fl, ft
	Variable i, n, m, fn, tfn
	
 	fn=CountObjects(":",4)
 	n=0
 	fl="root:;"
 	ft=GetDataFolder(1)
 	do
		SetDataFolder GetIndexedObjName(":",4,n)
		fl +=GetDataFolder(1)+";"
		SetDataFolder root:
		n+=1
 	while (n+1<fn)
	m=itemsinlist(fl)
 	i=1
	do
		SetDataFolder stringfromlist(i,fl)
		ft=GetDataFolder(1)
		n=0
			do
				fn=CountObjects(ft,4)
				SetDataFolder GetIndexedObjName(":",4,n)
				fl +=GetDataFolder(1)+";"
				SetDataFolder ft
				n += 1
			while (n<fn)
		i += 1
	while (i<m)
	return fl
  End

Function stackaxes()
// Align and stack the left axes in a graph
// James Allan, APRG, UMIST
// james.allan@physics.org
	string axeslist=sortlist(axislist("")),leftlist="",axis
	variable sep=10,n,i,pos=nan,a1,a2,b1,b2
	prompt sep,"Percentage Separation"
	n=itemsinlist(axeslist)
	for (i=0;i<n;i+=1)
		axis=stringfromlist(i,axeslist)
		if (stringmatch(stringbykey("AXTYPE",axisinfo("",axis)),"left"))
			leftlist+=axis+";"
		endif
	endfor
	n=itemsinlist(leftlist)
	if (n>0)
		doprompt "Stack Left Axes", sep
		if (!v_flag)
			sep/=100
			a1=n+(sep*n)-sep
			for (i=0;i<n;i+=1)
				a2=(sep+1)*(n-i-1)
				axis=stringfromlist(i,leftlist)
				b1=a2/a1
				if (b1<0)
					b1=0
				endif
				b2=(a2+1)/a1
				if (b2>1)
					b2=1
				endif
				ModifyGraph axisEnab($axis)={b1,b2}
				ModifyGraph freePos($axis)=0
				if (numtype(pos)!=0)
					pos=numberbykey("lblPos(x)",axisinfo("",axis),"=")
				else
					ModifyGraph lblPos($axis)=pos
				endif
			endfor
		endif
	endif
End

Function alignaxes(axis1,axis2)
// Align axis 2 with axis 1
// James Allan, APRG, UMIST
// james.allan@physics.org
	string axis1, axis2
	string axlist=axislist("")
	if (strsearch(axlist,axis1,0)>-1 && strsearch(axlist,axis2,0)>-1)
		execute ("modifygraph axisEnab("+axis2+")="+stringbykey("axisEnab(x)",axisinfo("", axis1),"="))
	endif
End
//******************************************************************************************************************
//CUSTOM FIT FUNCTIONS 

Function ExpLine_Xoffset(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ variable result
	//CurveFitDialog/ if(x<x0)
	//CurveFitDialog/ result=B*x+C
	//CurveFitDialog/ else
	//CurveFitDialog/ result = A*(1-exp(-(x-x0)/Tau))+B*x+C
	//CurveFitDialog/ endif
	//CurveFitDialog/ f(x)=result
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = C
	//CurveFitDialog/ w[3] = x0
	//CurveFitDialog/ w[4] = Tau

	variable result
	if(x<w[3])
	result=w[1]*x+w[2]
	else
	result = w[0]*(1-exp(-(x-w[3])/w[4]))+w[1]*x+w[2]
	endif
	return result
End

Function dblExpLine_Xoffset(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ variable result
	//CurveFitDialog/ if(x<x0)
	//CurveFitDialog/ result=B*x+C
	//CurveFitDialog/ else
	//CurveFitDialog/ result = A1*(1-exp(-(x-x0)/gTau1))+ A2*(1-exp(-(x-x0)/gTau2))+B*x+C
	//CurveFitDialog/ endif
	//CurveFitDialog/ f(x) = result
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = A1
	//CurveFitDialog/ w[1] = gTau1
	//CurveFitDialog/ w[2] = A2
	//CurveFitDialog/ w[3] = gTau2
	//CurveFitDialog/ w[4] = B
	//CurveFitDialog/ w[5] = C
	//CurveFitDialog/ w[6] = x0

	variable result
	if(x<w[6])
	result=w[4]*x+w[5]
	else
	result = w[0]*(1-exp(-(x-w[6])/w[1]))+ w[2]*(1-exp(-(x-w[6])/w[3]))+w[4]*x+w[5]
	endif
	return result
End

Function tplExpLine_Xoffset(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ variable result
	//CurveFitDialog/ if(x<x0)
	//CurveFitDialog/ result=B*x+C
	//CurveFitDialog/ else
	//CurveFitDialog/ result = A1*(exp(-(x-x0)/gTau1))+ A2*(exp(-(x-x0)/gTau2))+A3*(exp(-(x-x0)/gTau3))+B*x+C
	//CurveFitDialog/ endif
	//CurveFitDialog/ f(x) = result
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = A1
	//CurveFitDialog/ w[1] = gTau1
	//CurveFitDialog/ w[2] = A2
	//CurveFitDialog/ w[3] = gTau2
	//CurveFitDialog/ w[4] = A3
	//CurveFitDialog/ w[5] = gTau3
	//CurveFitDialog/ w[6] = B
	//CurveFitDialog/ w[7] = C
	//CurveFitDialog/ w[8] = x0

	variable result
	if(x<w[8])
	result=w[6]*x+w[7]
	else
	result = w[0]*(1-exp(-(x-w[8])/w[1]))+ w[2]*(1-exp(-(x-w[8])/w[3]))+ w[4]*(1-exp(-(x-w[8])/w[5]))+w[6]*x+w[7]
	endif
	return result
End



Function TwoPoints(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = ((y2-y1)/(x2-x1))*(x-x1)+y1
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = x1
	//CurveFitDialog/ w[1] = x2
	//CurveFitDialog/ w[2] = y1
	//CurveFitDialog/ w[3] = y2

	return ((w[3]-w[2])/(w[1]-w[0]))*(x-w[0])+w[2]
End

Function/D Mini (FitPars, x)
	wave/D FitPars
	Variable/D x
			//Makes a mini; 
	//FitPars[0] = risetime
	//FitPars[1] = Tau1
	//FitPars[2] = Tau2
	//FitPars[3] = alpha
	//FitPars[4] = ampl
	//FitPars[5] = t_0

//	if (CheckWave( "Deconmini", NameOfWave( FitPars ) ))
//		return 0
//	endif

	Variable result
	result = -exp(-(x-FitPars[5] )/FitPars[0]) + (1-FitPars[3] )*exp(-(x-FitPars[5] )/FitPars[1] ) 
	result += FitPars[3] *exp(-(x-FitPars[5] )/FitPars[2] )	//this is  like the usual mini, butt not scaled to peakamp =1
	result *=  FitPars[4]
	return result
end //Function DeconMini


// GUI Functions

//BUTTON PROCS
Function none()
End

Function procAddSweep (ctrlTempl) : ButtonControl
	String ctrlTempl
	//AddSweep()
End
	
Function proc_NextGraph (ctrlName) : Buttoncontrol
	String ctrlName
	SVAR gWaveList=root:Globals:gWaveList
	DisplayNextWave(gWaveList)
End

Function proc_PreviousGraph (ctrlName) : Buttoncontrol
	String ctrlName
	SVAR gWaveList=root:Globals:gWaveList
	DisplayPreviousWave(gWaveList)
End

Function proc_Gaussfilter (ctrlName) : Buttoncontrol
	String ctrlName	
	SVAR gTheWave=root:Globals:gTheWave
	//bpc_FilterGauss(root:OrigData:$gTheWave,1000,0)
End

Function proc_Init (ctrlName) : Buttoncontrol
	String ctrlName
	String objName
	SVAR gWaveList=root:Globals:gWaveList, gTheWave=root:Globals:gTheWave
	Variable index = 0
	SetDataFolder root:
		do
			objName = GetIndexedObjName("root:OrigData", 1, index)
			if (strlen(objName) == 0)
				break
			endif
			if (index==0)
				gWaveList=objName
			else
				gWaveList=gWaveList+";"+objName
			endif
			index += 1
		while(1)
	DisplayWaveListAnal(gWaveList)
	Button button_RefreshCursors, win=NeuroBunny, disable=0
	//End
End

Function Proc_Baseline(ctrlName) : ButtonControl
	String ctrlName
	BaselineSelected()
End

Function procMenuNB(ctrlName) : ButtonControl
	String ctrlName
	
	strswitch(ctrlName)
		case "ctrlBL2b":
			ControlInfo $ctrlName
			BaselineWaveTwoRegion(waverefindexed("Experiments",0,1))
			break	
		case "ctrlBL2a":
			ControlInfo $ctrlName
			BaselineWaveTwoRegion2(waverefindexed("Experiments",0,1))
			break	
		case "ctrlBL1a":
			ControlInfo $ctrlName
			BaselineSelectedFix()
			break	
		case "ctrlBL1b":
			ControlInfo $ctrlName
			BaselineSelected()
			break	
		case "ctrlWvAverage":
			ControlInfo $ctrlName
			String bn, fn, fl
			Prompt bn, "Average Waves beginning with?"
			fl=BuildFolderList()
			Prompt fn, "Folder",popup,fl
			DoPrompt "Neurobunny needs to know...", bn, fn
			SetDataFolder fn
			WavesAverage(bn, "wAverage")
			break
		case "ctrlAutoscale":
			SetAxis /Z/A left
 			SetAxis /Z/A bottom
 			SetAxis /Z/A/R right
			break
		case "ctrlBLstartToA":
			BaselineStartToA()
			break
	endswitch
End		
	
Function Proc_Area(ctrlName) : ButtonControl
	String ctrlName
	integrateCursors()
End


Function Proc_Amplitude(ctrlName) : ButtonControl
	String ctrlName
	Amplitude()
End

Function Proc_Trains(ctrlName) : ButtonControl
	String ctrlName
//	ControlInfo /W=NeuroBunny checkAsyncTRAIN
//	if (V_Value==0)
//		ControlInfo /W=NeuroBunny checkFFTtrain
//		if (V_Value==0)
			Trains_Amp()
//		elseif (V_Value==1)
//			ReleaseFFT()
//		endif
//	elseif (V_Value==1)
//		Trains_Async()
//	endif	
End

Function Proc_TrainsAuto(ctrlName) : ButtonControl
	String ctrlName
			Trains_Amp_Auto()
End

Function Proc_Recovery(ctrlName) : ButtonControl
	String ctrlName
	Recovery()
End
	
Function Proc_STP(ctrlName) : ButtonControl
	String ctrlName
	ControlInfo /W=NeuroBunny checkAsyncSTP
	if (V_Value==0)
		STP()
	elseif (V_Value==1)
		STP_Async()
	endif
End

Function Proc_Artifact(ctrlName) : ButtonControl
	string ctrlName
			interpolateArtifact(waverefindexed("",0,1),xcsr(A, "Experiments"),xcsr(B, "Experiments"))
			print wavename("",0,1)," Artifact Interpolated"
End

Function proc_Async(ctrlName) : ButtonControl
	string ctrlName
	AsyncRelease()
End

Function proc_FitDExp(ctrlName) : ButtonControl
	string ctrlName
	FitDExp()
End

Function proc_Rinput(ctrlName) : ButtonControl
	string ctrlName
	RinputAna()
End

Function proc_RiPlot(ctrName) : ButtonControl
	string ctrName
	RiPlot()
End

Function proc_APPlot(ctrName) : ButtonControl
	string ctrName
	APPlot()
End


Function proc_AP(ctrlName) : ButtonControl
	string ctrlName
	APCount()
End

Function proc_APAna(ctrlName) : ButtonControl
	string ctrlName
	APAna()
End

Function proc_APTab(ctrlName) : ButtonControl
	string ctrlName
	APTab()
End


Function proc_ForwA(ctrlName) : ButtonControl
	string ctrlName
	ForwCursorA()
End

Function proc_BackwA(ctrlName) : ButtonControl
	string ctrlName
	BackwCursorA()
End

Function proc_ForwB(ctrlName) : ButtonControl
	string ctrlName
	ForwCursorB()
End

Function proc_BackwB(ctrlName) : ButtonControl
	string ctrlName
	BackwCursorB()
End

// -AdrianGR
Function proc_button_RefreshCursors(ctrlName) : ButtonControl
	String ctrlName
	refreshCursors()
End

Function proc_checkFixCursors(CB_Struct) : CheckBoxControl
	STRUCT WMCheckBoxAction &CB_Struct
	
	
	switch(CB_Struct.eventCode)
		case 2:
			if(CB_Struct.checked == 1)
				CheckBox chk_IgnoreSavedCursors, disable=2
			else
				CheckBox chk_IgnoreSavedCursors, disable=0
			endif
	endswitch
	
	return 0
End


Function procPopMenuNBB(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR gGroupNum=root:Globals:gGroupNum, gSeriesNum=root:Globals:gSeriesNum, gSweepNum=root:Globals:gSweepNum, gNewFileFlag=root:Globals:gNewFileFlag, gNewGroupFlag=root:Globals:gNewGroupFlag, gNewSeriesFlag=root:Globals:gNewSeriesFlag
	SVAR gProtocol=root:Globals:gProtocol, gExpGroup=root:Globals:gExpGroup, gNeuron=root:Globals:gNeuron, gDatFileName=root:Globals:gDatFileName, gTheWave=root:Globals:gTheWave
	String hostname="NBrowser"
	
	strswitch(ctrlName)
		case "popup_Group":
			ControlInfo $ctrlName
			gGroupNum = V_Value
			gNewFileFlag=0
			gNewGroupFlag=1
			gNewSeriesFlag=0
			gSeriesNum=1
			gSweepNum=1
			SetDataFolder root:PulseBrowser
			RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
			KillWaves/A/Z
			SetDataFolder root:
			LoadDatFile(gDatFileName)
			break
		case "popup_Series":
			ControlInfo $ctrlName
			gSeriesNum = V_Value
			gNewFileFlag=0
			gNewGroupFlag=0
			gNewSeriesFlag=1
			gSweepNum=1
			SetDataFolder root:PulseBrowser
			RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
			KillWaves/A/Z
			SetDataFolder root:
			LoadDatFile(gDatFileName)
			break
		case "popup_Sweep":
			ControlInfo $ctrlName
			gSweepNum = V_Value
			gNewFileFlag=0
			gNewGroupFlag=0
			gNewSeriesFlag=0
			SetDataFolder root:PulseBrowser
			RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
			KillWaves/A/Z
			SetDataFolder root:
			LoadDatFile(gDatFileName)
			break		
		case "popup_Type":
			ControlInfo $ctrlName
			gNeuron=S_Value
			gNewFileFlag=0
			gNewGroupFlag=0
			gNewSeriesFlag=0
			break
		case "popup_ExpGroup":
			ControlInfo $ctrlName
			gExpGroup=S_Value
			gNewFileFlag=0
			gNewGroupFlag=0
			gNewSeriesFlag=0
			break
	endswitch
End

Function proc_Sucrose(ctrlName) : ButtonControl
	String ctrlName
	Variable popNum
	
	String popStr
	strswitch(ctrlName)
		case "ctrlSucrose":
			ControlInfo $ctrlName
			ReleaseSucrose(0)
			break
		case "ctrlSucPair1":
			ControlInfo $ctrlName
			ReleaseSucrose(1)
			break
		case "ctrlSucPair2":
			ControlInfo $ctrlName
			ReleaseSucrose(2)
			break
		case "ctrlFilter":
			FilterTrace()
			break
		endswitch
End

Function procArrowsNBB(ctrlName) : ButtonControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR gGroupNum=root:Globals:gGroupNum, gSeriesNum=root:Globals:gSeriesNum, gSweepNum=root:Globals:gSweepNum, gNewFileFlag=root:Globals:gNewFileFlag, gDatIndex=root:Globals:gDatIndex, gSeriesTot=root:Globals:gSeriesTot, gGroupTot=root:Globals:gGroupTot, gSweepTot=root:Globals:gSweepTot, gNewSeriesFlag=root:Globals:gNewSeriesFlag, gNewGroupFlag=root:Globals:gNewGroupFlag
	SVAR gProtocol=root:Globals:gProtocol, gExpGroup=root:Globals:gExpGroup, gNeuron=root:Globals:gNeuron, gDatFileName=root:Globals:gDatFileName, gDatPath=root:Globals:gDatPath, gTheWave=root:Globals:gTheWave, gDatFileList=root:Globals:gDatFileList
	String hostname="NBrowser"
	
	strswitch(ctrlName)
		case "button_GroupNext":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=0
			gNewGroupFlag=1
			gSeriesNum=1
			gSweepNum=1
			if (gGroupNum<gGroupTot)
				gGroupNum=gGroupNum+1
				PopupMenu popup_Group,mode=gGroupNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)	
			else
				DoAlert 0,"No more Groups in this file."
			endif		
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			break
		case "button_GroupPrevious":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=0
			gNewGroupFlag=1
			gSeriesNum=1
			gSweepNum=1
			if (gGroupNum>1)
				gGroupNum=gGroupNum-1
				PopupMenu popup_Group,mode=gGroupNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more Groups in this file."
			endif			
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_SerieNext":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=1
			gNewGroupFlag=0
			gSweepNum=1
			if (gSeriesNum<gSeriesTot)
				gSeriesNum=gSeriesNum+1
				PopupMenu popup_Series,mode=gSeriesNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more Series in this Group."
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_SeriePrevious":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=1
			gNewGroupFlag=0
			gSweepNum=1
			if (gSeriesNum>1)
				gSeriesNum=gSeriesNum-1
				PopupMenu popup_Series,mode=gSeriesNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more Series in this Group."
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_SweepNext":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=0
			gNewGroupFlag=0
			if (gSweepNum<gSweepTot)
				gSweepNum=gSweepNum+1
				PopupMenu popup_Sweep,mode=gSweepNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more Sweeps in this Series."
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_SweepPrevious":
			ControlInfo $ctrlName
			gNewFileFlag=0
			gNewSeriesFlag=0
			gNewGroupFlag=0
			if (gSweepNum>1)
				gSweepNum=gSweepNum-1
				PopupMenu popup_Sweep,mode=gSweepNum
				SetDataFolder root:PulseBrowser
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more Sweeps in this Series."
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_FilePrevious":
			ControlInfo $ctrlName
			if (gDatIndex>0)
				gNewFileFlag=1
				gNewSeriesFlag=0
				gNewGroupFlag=0
				gGroupNum=1
				gSeriesNum=1
				gSweepNum=1
				gDatIndex=gDatIndex-1
				NewPath/O thePath gDatPath
				gDatFileName=indexedfile(thePath,gDatIndex,".dat")
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				SetDataFolder root:PulseBrowser
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)			
			else
				DoAlert 0,"No more files available"
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_FileNext":
			ControlInfo $ctrlName
			if ((gDatIndex+1)<ItemsInList(gDatFileList))
				gNewFileFlag=1
				gNewGroupFlag=0
				gNewSeriesFlag=0
				gGroupNum=1
				gSeriesNum=1
				gSweepNum=1
				gDatIndex=gDatIndex+1
				NewPath/O thePath gDatPath
				gDatFileName=indexedfile(thePath,gDatIndex,".dat")
				RemoveFromGraph/Z/W=NBrowser#BrowseGraph $gTheWave
				SetDataFolder root:PulseBrowser
				KillWaves/A/Z
				SetDataFolder root:
				LoadDatFile(gDatFileName)	
			else
				DoAlert 0,"No more files available"
			endif
			PopupMenu popup_Group,mode=gGroupNum
			PopupMenu popup_Series,mode=gSeriesNum
			PopupMenu popup_Sweep,mode=gSweepNum
			break
		case "button_ZoomOut":
			ControlInfo $ctrlName
			gNewFileFlag=0
			SetAxis/W=NBrowser#BrowseGraph/A
			break
		case "button_AllSweeps":
			ControlInfo $ctrlName
			gNewFileFlag=0
			break
		case "button_AddExpGroup":
			ControlInfo $ctrlName
			gNewFileFlag=0
			break
		case "button_Done":
			ControlInfo $ctrlName
			gNewFileFlag=0
			KillWindow NBrowser	
			DoAlert 1,"Continue with loading experiments?"
			if (V_Flag==1)
				LoadselectedExperiments()
			elseif (V_Flag==2)
				abort
			endif
			break
	endswitch            
End


// Extract frequency information from string -AdrianGR
// Optionally supply quiet level (1: prints if not able to extract info, 2: does not print at all)
// Optionally supply typeMsg, which is inserted into print message
Function getStringFreq(inString, [quiet, typeMsg])
	String inString
	Variable quiet
	String typeMsg
	if(ParamIsDefault(typeMsg))
		typeMsg = ""
	endif
	
	String regExPattern = "([0-9]{1,3})(.?)([Hh]z)" //Matches e.g. "20Hz", "20 Hz", "200_hz" etc.
	String outFreq = ""
	
	SplitString/E=regExPattern inString, outFreq
	if(V_flag==3)
		if(quiet!=1)
			print("Extracted "+typeMsg+"frequency is: "+outFreq+" Hz")
		endif
		return str2num(outFreq)
	else
		if(quiet<2)
			print("Could not extract "+typeMsg+"frequency, defaulted to 50 Hz")
		endif
		return 50
	endif
End

// Set gTrainFreq and gRecFreq based on extracted frequency from getStringFreq -AdrianGR
Function update_Freq(String inWaveStr)
	NVAR gTrainFreq = root:Globals:gTrainFreq
	NVAR gRecFreq = root:Globals:gRecFreq
	gTrainFreq = getStringFreq(inWaveStr, typeMsg="train ")
	gRecFreq = getStringFreq(inWaveStr, quiet=1, typeMsg="gRecFreq ")
End

Function ExportWaves()
	String SavePath
//	Prompt SavePath, "Data Folder:"		// Set prompt for path
//	DoPrompt "Have you choosen the right datafolder to export the waves from?", SavePath
//	if (V_Flag!=0)
//		abort
//	endif

	SaveData/I/D=1/L=1
End


// Creates transposed wave (with suffix _T) of input wave -AdrianGR
Function transposeWaveMake(inWave)
	Wave inWave
	Variable rows = DimSize(inWave,1) 					//Number of columns in inWave -> rows in outWave
	Variable cols = DimSize(inWave,0)					//Number of rows in inWave -> columns in outWave
	String outWaveName = NameOfWave(inWave)+"_T"
	Make/O/N=(rows,cols) $outWaveName/WAVE=w
	//Wave outWave = $outWaveName
	w[][] = inWave[q][p]									//Transpose
End

// Returns transposed wave of input wave -AdrianGR
Function/WAVE transposeWave(inWave)
	Wave inWave
	Variable rows = DimSize(inWave,1) 					//Number of columns in inWave -> rows in outWave
	Variable cols = DimSize(inWave,0)					//Number of rows in inWave -> columns in outWave
	//String outWaveName = NameOfWave(inWave)+"_T"
	//Make/O/N=(rows,cols) $outWaveName
	//Wave outWave = $outWaveName
	//outWave[][] = inWave[q][p]
	
	Make/FREE/O/N=(rows,cols) outWave
	outWave[][] = inWave[q][p]							//Transpose
	
	return outWave
End

//testing -AdrianGR
Function testFunc69()
	Make/WAVE/O/N=(3) w_testRef2
	w_testRef2[0] = root:Results:TrainAmp_CASync
	w_testRef2[1] = root:Results:TrainAmp_CSync
	w_testRef2[2] = root:Results:TrainAmp_Delay
	Make/WAVE/O/N=(3) w_testRef2T
	w_testRef2T = transposeWaveRefWaves(w_testRef2)
	
	Wave mordi = w_testRef2[2]
	print mordi[1][2]
	Wave mordi = w_testRef2T[2]
	print NameOfWave(mordi), mordi[1][2]
End

//Does not work properly at this point -AdrianGR
Function/WAVE transposeWaveRefWaves(inRefWave)
	Wave/WAVE inRefWave
	//Duplicate inRefWave, $"inRefWave_dup"
	Variable numWaves = DimSize(inRefWave,0)
	Variable rows, cols
	String TWaveName
	
	Make/WAVE/O/N=(numWaves) tempRefWave
	
	Variable i
	for(i=0; i<numWaves; i+=1)
		TWaveName = NameOfWave(inRefWave[i])+"_T"
		Wave tempWave = inRefWave[i]
		rows = DimSize(tempWave,1)
		cols = DimSize(tempWave,0)
		
		Make/O/N=(rows,cols) $TWaveName///WAVE=w
		Wave w = $TWaveName
		w[][] = tempWave[q][p]
		tempRefWave[i] = w
		print w[0][0], w[0][1], w[0][2], "at i=", i
		WaveClear w
	endfor
	
	//print "numWaves=", numWaves, "i=", i
	
	//Make/O tempRefWave2
	//tempRefWave2[] = tempRefWave[p]
	//Wave bingo
	//bingo = tempRefWave[2]
	//print bingo[1][2]
	
	//Variable rows = DimSize(tempWave,1) 					//Number of columns in inWave -> rows in outWave
	//Variable cols = DimSize(tempWave,0)					//Number of rows in inWave -> columns in outWave
	//String outWaveName = NameOfWave(inWave)+"_T"
	//Make/O/N=(rows,cols) $outWaveName
	//Wave outWave = $outWaveName
	//outWave[][] = inWave[q][p]
	
	//Make/FREE/O/N=(rows,cols) outWave
	//outWave[][] = inRefWave[q][p]							//Transpose
	
	return tempRefWave
End

Function/WAVE mTransp(inWave)
	Wave/WAVE inWave
	Variable rows = DimSize(inWave, 1)
	Variable cols = DimSize(inWave, 0)
	
	Make/FREE/O/N=(rows,cols) outWave
	
	Variable i, j
	for(i=0; i<rows; i+=1)
		for(j=0; j<cols; j+=1)
			outWave[i][j] = inWave[j][i]
		endfor
	endfor
		
	return outWave
End

//Testing -AdrianGR
Function testTranspose()
	SetDataFolder root:Results:
	Concatenate/O/NP=1 {transposeWave(TrainAmp_CSyncCum), transposeWave(TrainAmp_CASyncCum)}, w_resSummaryTest
	
End

Function testnothingAtAll()
SetDataFolder root:Results:
		
		//String refWaveList = "TrainAmp_All;TrainAmp_corrected;TrainAmp_Delay;TrainAmp_fromInitBaseline;TrainAmp_Sync;TrainAmp_CAll;TrainAmp_CCum;TrainAmp_CSync;TrainAmp_CSyncCum;TrainAmp_CASync;TrainAmp_CASyncCum"
		String refWaveList = "root:Results:TrainAmp_All;root:Results:TrainAmp_corrected"
		Make/WAVE/O/N=(2) refWave = ListToWaveRefWave(refWaveList)
		
		Variable i=0
		for(i=0; i<numpnts(refWave); i+=1)
			transposeWaveMake(refWave[i])
		endfor
		
		//Concatenate/O/NP=1 {refWave}, w_resSummaryTest
End

Function testNormalizeSomeMoreWaves(waveStr)
	String waveStr
	DFREF baseDir = root:imported:concat
	SetDataFolder baseDir
	String folderList = "grouped_9s;grouped_5s;grouped_3s;grouped_1s"
	String prefixList = "Het_;KO_;KO213_;"
	
	Variable i,j,k
	for(i=0; i<ItemsInList(folderList,";"); i+=1)
		SetDataFolder baseDir:$StringFromList(i,folderList,";")
		for(j=0; j<ItemsInList(prefixList,";"); j+=1)
			String tempWaveName = StringFromList(j,prefixList,";") + waveStr
			Wave tempWave = $tempWaveName
			normalize2DWave(tempWave,normIndex=0,outWaveName=tempWaveName+"_NormV2")
		endfor
	endfor
	SetDataFolder baseDir
End

// Function to normalize a wave -AdrianGR
// Optional parameters can be supplied, otherwise it defaults to normalizing rows relative to first column and naming new wave with suffix "_Norm"
// Returns reference to the newly created normalized wave
Function/WAVE normalize2DWave(inWave, [normDim, outWaveName, normIndex])
	Wave inWave
	Variable normDim										//Which dimension to normalize along
	String outWaveName
	Variable normIndex									//Which row/column index to normalize relative to
	if(ParamIsDefault(normDim))						//Default to normalizing along rows if normDim has not been supplied
		normDim = 0
	endif
	if(ParamIsDefault(outWaveName))					//Default name is to add "_Norm" as suffix to the name of the input wave
		outWaveName = NameOfWave(inWave)+"_Norm"
	endif
	if(ParamIsDefault(normIndex))						//Default to normalizing relative to first row/column
		normIndex = 0
	endif
	
	DFREF saveDFR = GetDataFolderDFR()				//Save initial data folder
	SetDataFolder GetWavesDataFolder(inWave,1)		//Set data folder to that of the input wave
	Duplicate/O inWave, $outWaveName					//Make a duplicate in that same folder
	Wave outWave = $outWaveName						//Create reference to the duplicate
	SetDataFolder saveDFR								//Go back to initial data folder
	
	switch(normDim)
		case 0:
			outWave[][] = inWave[p][q]/inWave[p][normIndex]		//Does normalization along rows
			break
		case 1:
			outWave[][] = inWave[p][q]/inWave[normIndex][q]		//Does normalization along columns
			break
		default:
			DoAlert 0, "Could not normalize wave!"
			outWave = NaN
	endswitch
	
	return outWave
End


Function testShowResults()
	DFREF saveDFR = GetDataFolderDFR()				//Save initial data folder
	
	SetDataFolder root:Results
	Make/WAVE/O resultsWaveRefWave = {TrainAmp_CASyncCum, TrainAmp_CASync, TrainAmp_CSyncCum, TrainAmp_CSync, TrainAmp_Sync_Norm, TrainAmp_Sync, TrainAmp_fromInitBaseline_Norm, TrainAmp_fromInitBaseline}
	Wave/WAVE resWRW = resultsWaveRefWave
	
	Variable i
	for(i=0; i<numpnts(resWRW); i+=1)
		Edit/K=1 resWRW[i]
	endfor
	
//	Edit/K=1 root:Results:TrainAmp_CASyncCum
//	Edit/K=1 root:Results:TrainAmp_CASync
//	Edit/K=1 root:Results:TrainAmp_CSyncCum
//	Edit/K=1 root:Results:TrainAmp_CSync
//	Edit/K=1 root:Results:TrainAmp_Sync_Norm
//	Edit/K=1 root:Results:TrainAmp_Sync
//	Edit/K=1 root:Results:TrainAmp_fromInitBaseline_Norm
//	Edit/K=1 root:Results:TrainAmp_fromInitBaseline
	
	SetDataFolder saveDFR								//Go back to initial data folder
End

//Just for testing purposes -AdrianGR
Function displayGraphV1(inWave, [rowStart, rowEnd])
	Wave inWave
	Variable rowStart, rowEnd
	if(ParamIsDefault(rowStart))
		rowStart = 0
	endif
	if(ParamIsDefault(rowEnd))
		rowEnd = DimSize(inWave,0)
	endif
	
	//KillWindow/Z dGraphV1
	Display/N=dGraphV1
	
	Variable i
	for(i=rowStart; i<=rowEnd; i+=1)
		AppendToGraph inWave[i][,*]
	endfor
	
	ModifyGraph mode=3
	
	ModifyGraph/Z rgb[0]=(0,0,0)
	ModifyGraph/Z rgb[1]=(3,52428,1)
	ModifyGraph/Z rgb[2]=(1,12815,52428)
	ModifyGraph/Z rgb[3]=(52428,1,41942)
	ModifyGraph/Z rgb[4]=(65535,21845,0)
	Legend ""
End

//Just for testing purposes -AdrianGR
Function displayGraphV2(inWave, [rowStart, rowEnd])
	Wave inWave
	Variable rowStart, rowEnd
	if(ParamIsDefault(rowStart))
		rowStart = 0
	endif
	if(ParamIsDefault(rowEnd))
		rowEnd = DimSize(inWave,0)
	endif
	
	//NewLayout/K=1/N=aLayout
	
	
	//KillWindow/Z dGraphV1
	Display/N=dGraphV1
	
	Variable i
	for(i=rowStart; i<=rowEnd; i+=1)
		AppendToGraph inWave[i][,*]
	endfor
	
	ModifyGraph mode=3
	
	ModifyGraph/Z rgb[0]=(0,0,0)
	ModifyGraph/Z rgb[1]=(3,52428,1)
	ModifyGraph/Z rgb[2]=(1,12815,52428)
	ModifyGraph/Z rgb[3]=(52428,1,41942)
	ModifyGraph/Z rgb[4]=(65535,21845,0)
	Legend ""
	
	//AppendLayoutObject/W=aLayout graph dGraphV1
	//TileWindows
End

//TODO: fix this -AdrianGR
Function/WAVE extractWaveStrInfo(inString, [regExPattern])
	String inString
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "^(x[0-9]{1,2}.+)_([0-9]{1,2})_([0-9]{1,2})_([0-9]{3})_([0-9]{1,2})_(.+)$"	//If RegEx pattern has not been supplied, default to this (made based on test string "x0X20Hz_50_9s_1_1_001_1_I-mon")
	endif
	String proStr, grStr, serStr, swStr, trStr, trNameStr
	Variable sweepOutInt
	
	SplitString/E=(regExPattern) inString, proStr, grStr, serStr, swStr, trStr, trNameStr
	if(V_flag != 6)
		print "Error in extractWaveStrInfo(), only matched: ", V_flag
	endif
	
	Make/O/T tempWaveExtract = {proStr, grStr, serStr, swStr, trStr, trNameStr}
	Wave/T tempWaveExtract
	
	return tempWaveExtract
	
	//return sweepOutInt
End

Function/S get_singleRegExMatch(inString, regExPattern)
	String inString
	String regExPattern
	String outStr
	Variable sweepOutInt
	
	SplitString/E=(regExPattern) inString, outStr
	if(V_flag < 1)
		print "No RegEx match!"
	endif
	
	return outStr
End

Function/S getPMDatFileName(inWaveNameStr, [regExPattern])
	String inWaveNameStr
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "PMDatFile.(c[0-9]{1,2}).dat"
	endif
	Wave leWave = root:OrigData:$inWaveNameStr
	String noteStr = note(leWave)
	String noteStr2 = StringFromList(1, noteStr,";")
	String strOut
	
	SplitString/E=regExPattern noteStr2, strOut
	
	return strOut
End

Function/S getPMSweepTimeDate(inWaveNameStr, [regExPattern])
	String inWaveNameStr
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "PMSweepTime.....(\\w{3})\s(\\d{1,2})\\s(\\d{4})"
	endif
	Wave leWave = root:OrigData:$inWaveNameStr
	String noteStr = note(leWave)
	String noteStr2 = StringFromList(3, noteStr,";")
	String strOutMonth, strOutDay, strOutYear
	
	SplitString/E=regExPattern noteStr2, strOutMonth, strOutDay, strOutYear
	
	String strOut = strOutDay + strOutMonth
	
	return strOut
End

Function getPMcapacitance(inWaveNameStr, [regExPattern])
	String inWaveNameStr
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "PMCm.([0-9].[0-9]{1,6}e.?[0-9]{3}).*"
	endif
	Wave leWave = root:OrigData:$inWaveNameStr
	String noteStr = note(leWave)
	String noteStr2 = StringFromList(15, noteStr,";")
	String strOut
	
	SplitString/E=regExPattern noteStr2, strOut
	//print V_flag
	
	Variable strOutNum = str2num(strOut)
	
	return strOutNum
End

Function/WAVE extractWaveListInfo()
	SVAR gWaveList = root:Globals:gWaveList
	Wave/T expW = root:experimentwave
	Wave/T proW = root:protocolwave
	Wave/T folderW = root:Data:folder
	Variable numWaves = ItemsInList(gWaveList, ";")
	Make/O/T/N=(13, numWaves) w_ExtractedInfo
	Wave/T w_ExtractedInfo
	
	SetDimLabel 0, 0, protocol, w_ExtractedInfo
	SetDimLabel 0, 1, group, w_ExtractedInfo
	SetDimLabel 0, 2, series, w_ExtractedInfo
	SetDimLabel 0, 3, sweep, w_ExtractedInfo
	SetDimLabel 0, 4, trace, w_ExtractedInfo
	SetDimLabel 0, 5, traceName, w_ExtractedInfo
	SetDimLabel 0, 6, protocol, w_ExtractedInfo
	SetDimLabel 0, 7, exper, w_ExtractedInfo
	SetDimLabel 0, 8, folder, w_ExtractedInfo
	SetDimLabel 0, 9, fileName, w_ExtractedInfo
	SetDimLabel 0, 10, folderLast, w_ExtractedInfo
	SetDimLabel 0, 11, DayMonth, w_ExtractedInfo
	SetDimLabel 0, 12, capacitance, w_ExtractedInfo
	
	Variable i
	for(i=0; i<numWaves; i+=1)
		String curWaveName = StringFromList(i,gWaveList,";")
		Wave/T extractedInfo = extractWaveStrInfo(curWaveName)
		SetDimLabel 1, i, $curWaveName, w_ExtractedInfo
		w_ExtractedInfo[0,5][i] = extractedInfo[p]
		w_ExtractedInfo[%protocol][i] = get_protocolname2(curWaveName)
		w_ExtractedInfo[%fileName][i] = getPMDatFileName(curWaveName)
		w_ExtractedInfo[%DayMonth][i] = getPMSweepTimeDate(curWaveName)
		w_ExtractedInfo[%capacitance][i] = num2str(getPMcapacitance(curWaveName))
	endfor
	
	Make/O/N=(4, numWaves) w_ExtractedInfoNumeric
	Wave w_ExtractedInfoNumeric
	w_ExtractedInfoNumeric[,*][,*] = str2num(w_ExtractedInfo[p+1][q])
	SetDimLabel 0, 0, group, w_ExtractedInfoNumeric
	SetDimLabel 0, 1, series, w_ExtractedInfoNumeric
	SetDimLabel 0, 2, sweep, w_ExtractedInfoNumeric
	SetDimLabel 0, 3, trace, w_ExtractedInfoNumeric
	for(i=0; i<DimSize(w_ExtractedInfo,1); i+=1)
		SetDimLabel 1, i, $GetDimLabel(w_ExtractedInfo, 1, i), w_ExtractedInfoNumeric
	endfor
	if(DimSize(w_ExtractedInfoNumeric, 1) < 2+DimSize(w_ExtractedInfo,1))
		InsertPoints/M=1 INF, 2, w_ExtractedInfoNumeric
		SetDimLabel 1, DimSize(w_ExtractedInfo,1), minimum, w_ExtractedInfoNumeric
		SetDimLabel 1, DimSize(w_ExtractedInfo,1)+1, maximum, w_ExtractedInfoNumeric
	endif
	for(i=0; i<DimSize(w_ExtractedInfoNumeric,0); i+=1)
		WaveStats/Q/RMD=[i][0,DimSize(w_ExtractedInfoNumeric, 1)-3] w_ExtractedInfoNumeric
		w_ExtractedInfoNumeric[i][%minimum] = V_min
		w_ExtractedInfoNumeric[i][%maximum] = V_max
	endfor
	
	//This loop is pretty hardcoded, so will only work for pairs of sweeps, but that doesn't matter too much since the info is also elsewhere -AdrianGR
	Variable tempIndex, tempIndex_cache
	for(i=0; i<numWaves; i+=1)
		//Variable tempIndex = str2num(w_ExtractedInfo[%series][i]) - w_ExtractedInfoNumeric[%series][%minimum]
		//tempIndex = i
		if(str2num(w_ExtractedInfo[%sweep][i]) == 2)
			tempIndex = tempIndex_cache
			//print "sweep is ", str2num(w_ExtractedInfo[%sweep][i]), "set index to ", tempIndex
		else
			tempIndex = i/2
			//print "index ", tempIndex
		endif
		w_ExtractedInfo[%exper][i] = expW[tempIndex]
		w_ExtractedInfo[%folder][i] = folderW[tempIndex]
		w_ExtractedInfo[%folderLast][i] = get_singleRegExMatch(w_ExtractedInfo[%folder][i], "\\W\\W(?:[0-9]{1,4}.[0-9]{1,2}.[0-9]{1,2})\\W\\W(\\w{1,10})\\W\\W")
		tempIndex_cache = tempIndex
	endfor
	
	return w_ExtractedInfo
End


Function testIntegDiff(String choice)
	SetDataFolder root:WorkData
	Duplicate/O WaveRefIndexed("Experiments", 0, 1), w_temp_2
	Wave wt = w_temp_2
	//w_tempp = -w_tempp
	Duplicate/O wt, w_temp_2_DI
	Wave wt2 = w_temp_2_DI
	wt2 = 0
	
	strswitch(choice)
		case "int":
		case "integrate":
			Integrate/METH=1 wt /D=wt2
			SetScale d 0,0,"C", wt2
			break
		case "diff":
		case "differentiate":
			Differentiate/METH=1 wt /D=wt2
			SetScale d 0,0,"A/S", wt2
			break
	endswitch
	
	
	Display/K=1/N=DiffIntWin wt2
	Cursor/C=(65535,0,0)/W=DiffIntWin/H=1/S=1/L=1 B,w_temp_2_DI,0
	AppendToGraph/R/C=(0,30000,10000) wt
	
	SetWindow DiffIntWin hook(myHook)=testCursorMovedHook
End

Function testCursorMovedHook(s)
	STRUCT WMWinHookStruct &s
	strswitch(s.eventName)
		case "cursormoved":
			Variable p1 = pcsr(B,s.winName)
			moveCursorsToPnt(Bp=p1)
			break
	endswitch
	
	return 0
End

Function testIns()
	Wave w = root:'New_FitCoefficients'
	InsertPoints/M=1 INF, 1, w
End

Function removeAllTraces(graphWinNameStr)
	String graphWinNameStr
	
	String tracesList = TraceNameList(graphWinNameStr,";",1)
	//print tracesList
	
	Variable numTraces = ItemsInList(tracesList,";")
	//print "numTraces = ", numTraces
	
	Variable i
	for(i=0; i<numTraces; i+=1)
		print "i = ", i
		//String tmpTrace = StringFromList(i, tracesList, ";",0)
		RemoveFromGraph/Z/W=$graphWinNameStr $""
	endfor
	
	//print "now these traces are on graph: ", TraceNameList(graphWinNameStr,";",1)
End


Function get_InterTrainDelay(inStr, [regExPattern])
	String inStr
	String regExPattern
	if(ParamIsDefault(regExPattern))
		regExPattern = "^x[0-9]{1}.+_([0-9]{1,2})s_[0-9]{1}_[0-9]{1}_([0-9]{3})_[0-9]{1}_.+$"	//If RegEx pattern has not been supplied, default to this (made based on test string "x2X20Hz_50_9s_1_1_001_1_I-mon")
	endif
	String delayStr, sweepStr
	
	SplitString/E=regExPattern inStr, delayStr, sweepStr
	
	Variable delay = str2num(delayStr)
	Variable sweep = str2num(sweepStr)
	
	return delay
End



//Create waves necessary for calculating 'recovery of total syncronous release' -AdrianGR
Function makeRTSRwave(numDelays, delayVals)
	Variable numDelays
	String delayVals
	if(numDelays != ItemsInList(delayVals,";"))
		abort
	endif
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder root:WorkData
	
	String/G root:Globals:gRTSRdelayValList = delayVals
	Make/O/N=(numDelays,1,3) RTSR_data = NaN
	SetDimLabel 2, 0, ratio, RTSR_data
	SetDimLabel 2, 1, P1, RTSR_data
	SetDimLabel 2, 2, P2, RTSR_data
	Make/O/N=(numDelays,1) RTSRdelay_data = NaN
	Make/O/N=(5) RTSR_params
	SetDimLabel 0, 0, includeBool, RTSR_params
	SetDimLabel 0, 1, number, RTSR_params
	SetDimLabel 0, 2, delayNumber, RTSR_params
	SetDimLabel 0, 3, P1P2, RTSR_params
	Redimension/N=(DimSize(RTSR_params,0)+numDelays-1) RTSR_params
	Variable i
	for(i=0; i<numDelays; i+=1)
		String dimLabel = "delay"+num2str(i)
		SetDimLabel 0, DimSize(RTSR_params,0)-numDelays+i, $dimLabel, RTSR_params
		RTSR_params[DimSize(RTSR_params,0)-numDelays+i] = str2num(StringFromList(i,delayVals,";"))
	endfor
	
	Make/T/O RTSRinfo
	
	SetDataFolder saveDFR
End

Function testNans()
	SetDataFolder root:WorkData
	//Duplicate/O RTSR_data, Rtemp
	Wave Rtemp
	//Redimension/N=(-1,2,-1) Rtemp
	Rtemp[][1][0] = Rtemp==0 ? NaN : Rtemp
End

Function proc_button_initRTSRpanel(ctrlName) : ButtonControl
	String ctrlName
	init_RTSR_panel()
End

Function init_RTSR_panel()
	DFREF saveDFR = GetDataFolderDFR()
	
	SetDataFolder root:Globals
	Variable/G gsv_RTSRnumDelays = 4
	String/G gsv_RTSRdelayVals = "9;5;3;1"
	Variable/G gcb_RTSRinclude = 0
	Variable/G gsv_RTSRnumber = 0
	Variable/G gcb_RTSR_P = 0
	//SVAR/Z gRTSRdelayValList = root:Globals:gRTSRdelayValList
	String/G gpop_RTSRdelay = "\"" + gsv_RTSRdelayVals + "\""
	Variable/G gWaveListNum// = 10//ItemsInList(root:Globals:gWaveList,";")
	NVAR gWaveIndex = root:Globals:gWaveIndex
	SetFormula gWaveListNum, "ItemsInList(root:Globals:gWaveList,\";\")-1"
	
	PauseUpdate; Silent 1		// building window...
	NewPanel/W=(20,750,220,955)/N=RTSR_panel/K=1
	
	SetVariable sv_RTSRnumDelays, pos={10,10}, size={180,20}, title="# of delays", value=gsv_RTSRnumDelays, limits={1,INF,1}, help={"Number of delay values."}
	SetVariable sv_RTSRdelayVals, pos={10,35}, size={180,20}, title="Delay values", value=gsv_RTSRdelayVals, help={"List of delay values, separated by semicolon."}
	Button btn_makeRTSR, pos={10,60}, size={180,20}, proc=proc_btn_makeRTSR, title="Make RTSR waves", help={"Click to create waves necessary for RTSR calculations."}
	DrawLine 10,90,190,90
	ValDisplay vd_waveListProgBar, pos={10,87}, size={180,6}, barmisc={0,0}, limits={0,gWaveListNum,0}, value=#"root:Globals:gWaveIndex", highColor=(0,40000,0)
	CheckBox cb_RTSRinclude, pos={10,100}, size={100,20}, title="Include in RTSR", variable=gcb_RTSRinclude, proc=proc_cb_RTSRinclude, help={"Check to include the train about to be analyzed in RTSR analysis."}
	SetVariable sv_RTSRnumber, pos={10,125}, size={100,20}, title="Number", value=gsv_RTSRnumber, limits={0,INF,1}, proc=proc_sv_RTSRnumber, help={"Set 'number', can e.g. correspond to each new cell analyzed."}
	PopupMenu pop_RTSRdelay, pos={10,150}, size={100,20}, title="Delay (s)", value=#gpop_RTSRdelay, proc=proc_pop_RTSRdelay, help={"Choose delay time. List is updated by shift+click."}
	CheckBox cb_RTSR_P, pos={10,175}, size={100,20}, proc=proc_cb_RTSR_P, title="P1", variable=gcb_RTSR_P, help={"P1 when unchecked, P2 when checked. P1/P2 are two separate trains, separated by delay set above."}
	
	Variable/G gsv_A = 10000, gsv_B = 10066
	Button btn_moveStimCursorsB, align=1, pos={160,110}, size={20,15}, fsize=10, title="<", proc=proc_btn_moveStimCursors
	Button btn_moveStimCursorsF, align=1, pos={190,110}, size={20,15}, fsize=10, title=">", proc=proc_btn_moveStimCursors
	SetVariable sv_A, align=1, pos={190,135}, size={60,20}, fsize=10, title="A", limits={0,INF,1}, value=gsv_A
	SetVariable sv_B, align=1, pos={190,155}, size={60,20}, fsize=10, title="B", limits={0,INF,1}, value=gsv_B
	Button btn_Magic, align=1, pos={190,175}, size={60,20}, fsize=10, title="Magic", proc=proc_btn_Magic
	
	SetDataFolder saveDFR
End

Function proc_btn_makeRTSR(ctrlName) : ButtonControl
	String ctrlName
	DoAlert 1, "Are you sure you want to create RTSR waves?\r\n(This will overwrite any previous ones in the current project.)"
	if(V_flag == 2)
		Abort
	endif
	NVAR gsv_RTSRnumDelays = root:Globals:gsv_RTSRnumDelays
	SVAR gsv_RTSRdelayVals = root:Globals:gsv_RTSRdelayVals
	//print gsv_numDelays,gsv_delayVals
	makeRTSRwave(gsv_RTSRnumDelays,gsv_RTSRdelayVals)
	
	update_pop_RTSRdelay()
End

Function proc_cb_RTSR_P(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	if(WaveExists(root:WorkData:RTSR_params)==0)
		Abort
	endif
	Wave RTSRp = root:WorkData:RTSR_params
	
	if(CB_Struct.eventCode == 2)
		switch(CB_Struct.checked)
			case 0:
				CheckBox $CB_Struct.ctrlName, title="P1"
				RTSRp[%P1P2] = 1
				break
			case 1:
				CheckBox $CB_Struct.ctrlName, title="P2"
				RTSRp[%P1P2] = 2
				break
		endswitch
	endif
	
	return 0
End

Function proc_cb_RTSRinclude(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	if(WaveExists(root:WorkData:RTSR_params)==0)
		abort
	endif
	Wave RTSRp = root:WorkData:RTSR_params
	
	if(CB_Struct.eventCode == 2)
		RTSRp[%includeBool] = CB_Struct.checked
		if(CB_Struct.checked)
			updateRTSRparamsFromGUI()
		endif
	endif
	
	return 0
End

Function proc_pop_RTSRdelay(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	if(WaveExists(root:WorkData:RTSR_params)==0)
		abort
	endif
	Wave RTSRp = root:WorkData:RTSR_params
	
	if(((PU_Struct.eventMod & 2^1) != 0)) //Shift+click updates popupmenu
		update_pop_RTSRdelay()
		print "Updated delay popup menu"
	endif
	
	if(PU_Struct.eventCode == 2)
		RTSRp[%delayNumber] = PU_Struct.popNum-1
	endif
	
	return 0
End

Function update_pop_RTSRdelay()
	SVAR gpop_RTSRdelayValList = root:Globals:gRTSRdelayValList
	SVAR gpop_RTSRdelay = root:Globals:gpop_RTSRdelay
	gpop_RTSRdelay = "\"" + gpop_RTSRdelayValList + "\""
	PopupMenu pop_RTSRdelay, value=#gpop_RTSRdelay
End

Function proc_sv_RTSRnumber(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	if(WaveExists(root:WorkData:RTSR_params)==0)
		abort
	endif
	Wave RTSRp = root:WorkData:RTSR_params
	
	if(SV_Struct.eventCode == 1 || SV_Struct.eventCode == 2)
		RTSRp[%number] = SV_Struct.dval
	endif
	
	return 0
End

Function updateRTSRparamsFromGUI()
	if(WaveExists(root:WorkData:RTSR_params)==0)
		abort
	endif
	Wave RTSRp = root:WorkData:RTSR_params
	
	ControlInfo/W=RTSR_panel sv_RTSRnumber
	RTSRp[%number] = V_Value
	ControlInfo/W=RTSR_panel pop_RTSRdelay
	RTSRp[%delayNumber] = V_Value - 1
	ControlInfo/W=RTSR_panel cb_RTSR_P
	RTSRp[%P1P2] = V_Value + 1
End

Function proc_btn_Magic(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	SVAR gTheWave = root:Globals:gTheWave
	NVAR gsv_A = root:Globals:gsv_A, gsv_B = root:Globals:gsv_B
	
	Variable del = get_InterTrainDelay(gTheWave)
	
	if(B_Struct.eventCode == 2)
		switch(B_Struct.eventMod)
			case 2:
				moveCursorsToPnt(Ap=gsv_A,Bp=gsv_B)
				BaselineStartToA()
				BaselineStartToA()
				BaselineStartToA()
				BaselineStartToA()
				BaselineStartToA()
				if(WaveExists(root:WorkData:RTSR_params)==0)
					DoAlert 1, "RTSR waves haven't been created. Continue anyway?"
					if(V_flag == 2)
						Abort
					endif
				endif
				Trains_Amp()
				break
			default:
				moveCursorsToPnt(Ap=gsv_A,Bp=gsv_B)
				SetAxis/W=Experiments left, -4e-9,5e-10
				SetAxis/W=Experiments bottom, 0.495,0.53
		endswitch
	endif
End

Function proc_btn_moveStimCursors(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	NVAR gsv_A = root:Globals:gsv_A, gsv_B = root:Globals:gsv_B
	Variable tempAp, tempBp
	
	if(B_Struct.eventCode == 2)
		strswitch(B_Struct.ctrlName)
			case "btn_moveStimCursorsF":
				if(B_Struct.eventMod == 2)
					gsv_B += 1
					tempAp = pcsr(A, "Experiments")
					tempBp = pcsr(B, "Experiments")+1
					moveCursorsToPnt(Ap=tempAp,Bp=tempBp)
				else
					cursorJumpAB(1)
				endif
				break
			case "btn_moveStimCursorsB":
				if(B_Struct.eventMod == 2)
					gsv_B -= 1
					tempAp = pcsr(A, "Experiments")
					tempBp = pcsr(B, "Experiments")-1
					moveCursorsToPnt(Ap=tempAp,Bp=tempBp)
				else
					cursorJumpAB(-1)
				endif
				break
		endswitch
	endif
End

Function moveCursorsToPnt([Ap, Bp, Cp, Dp])
	Variable Ap, Bp, Cp, Dp
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gCursorA = root:Globals:gCursorA, gCursorB = root:Globals:gCursorB, gCursorC = root:Globals:gCursorC, gCursorD = root:Globals:gCursorD
	DFREF saveDFR = GetDataFolderDFR()
	
	Variable x0, x1, x2, x3
	
	SetDataFolder root:OrigData		
	x0=pnt2x($gTheWave,Ap)
	x1=pnt2x($gTheWave,Bp)
	x2=pnt2x($gTheWave,Cp)
	x3=pnt2x($gTheWave,Dp)
	gCursorA = x0
	
	if(ParamIsDefault(Ap))
		x0 = gCursorA
	endif
	if(ParamIsDefault(Bp))
		x1 = gCursorB
	endif
	if(ParamIsDefault(Cp))
		x2 = gCursorC
	endif
	if(ParamIsDefault(Dp))
		x3 = gCursorD
	endif
	
	
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,gCursorA
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3
	
	SetDataFolder saveDFR
End

Function cursorJumpAB(n, [moveAxes])
	Variable n, moveAxes
	if(ParamIsDefault(moveAxes))
		moveAxes = 1
	endif
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gTrainStim=root:Globals:gTrainStim, gTrainfreq=root:Globals:gTrainfreq
	DFREF saveDFR = GetDataFolderDFR()
	
	Variable x0p, x1p, x0, x1
	SetDataFolder root:OrigData
	x0p = pcsr(A, "Experiments")
	x1p = pcsr(B, "Experiments")
	x0=pnt2x($gTheWave,x0p)
	x1=pnt2x($gTheWave,x1p)
	
	x0 = x0 + n/gTrainfreq
	x1 = x1 + n/gTrainfreq
	
	if(x2pnt($gTheWave,x0) >= numpnts($gTheWave) || x2pnt($gTheWave,x1) >= numpnts($gTheWave) || x2pnt($gTheWave,x0) < 0 || x2pnt($gTheWave,x1) < 0)
		print "Can't move cursors that far"
		SetDataFolder saveDFR
		Abort
	endif
	
	if(x2pnt($gTheWave,x1) > x2pnt($gTheWave,x0))
		//print "Cursor B is higher than cursor A"
	endif
	
	moveCursorsToPnt(Ap=x2pnt($gTheWave,x0),Bp=x2pnt($gTheWave,x1))
	
	if(moveAxes == 1)
		Variable xAxisStart = x0-0.005
		Variable xAxisEnd = x0+0.035
		//SetAxis/W=Experiments left, -4e-9,5e-10
		SetAxis/W=Experiments bottom, xAxisStart, xAxisEnd
	endif
	SetDataFolder saveDFR
End

Function testingTest(Variable g)
	SVAR gTheWave=root:Globals:gTheWave
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder root:OrigData
	print x2pnt($gTheWave,g)
	SetDataFolder saveDFR
End

Function/WAVE testInitSaveData()
	testInitSavePath()
	SetDataFolder root:
	if(DataFolderExists("ResultsConcat")==0)
		NewDataFolder root:ResultsConcat
	endif
	SetDataFolder root:ResultsConcat
	
	DFREF saveRefHere = root:ResultsConcat
	DFREF wavesHere = root:Results
	Wave/WAVE sWW = testMakeSaveWavesWave(wavesHere, saveRefHere, "saveWavesWave")

	return sWW
End

Function/WAVE testSaveData([saveBool])
	Variable saveBool
	if(ParamIsDefault(saveBool))
		saveBool = 0
	endif
	
	Wave/WAVE sWW = testInitSaveData()
	abortOnZeroInWaveRefWave(sWW)
	String saveWavesList = WaveRefWaveToList(sWW,0)
	
	if(saveBool == 1)
		Save/T/M="\r\n"/I/B/P=home saveWavesList as "ThisAnalysis.itx"
		Save/J/M="\r\n"/I/B/P=home/W/U={1,0,1,0} saveWavesList as "ThisAnalysis.txt"
	endif
	return sWW
End

Function testInitSavePath()
	String pathStr = "C:Users:kzw421:Desktop:Adrian G R:ephys recordings:Data analysis 2:"
	NewPath/O/C savePathDA1 pathStr
End

Function/WAVE testLoadData()
	testInitSavePath()
	SetDataFolder root:
	if(DataFolderExists("ResultsConcat")==0)
		NewDataFolder root:ResultsConcat
	endif
	
	DFREF wavesHere = root:ResultsConcat
	DFREF saveRefHere = wavesHere
	SetDataFolder wavesHere
	
	LoadWave/T/O/I/P=savePathDA1 "AllAnalyses.itx"
	
	Wave/WAVE sWW_loaded = testMakeSaveWavesWave(wavesHere, saveRefHere, "saveWavesWave_loaded")
	SetDataFolder wavesHere
	return sWW_loaded
End

Function testConcatData([saveRes])
	Variable saveRes
	if(ParamIsDefault(saveRes))
		saveRes = 1
	endif
	DoAlert 1, "Continue with data concatenation?"
	if(V_flag == 2)
		Abort
	endif
	
	Wave/WAVE sWW = testSaveData()
	Wave/WAVE sWW_loaded = testLoadData()
	SetDataFolder root:ResultsConcat
	if(DataFolderExists("out")==0)
		NewDataFolder :out
	endif
	
	Duplicate/O/WAVE sWW_loaded, :out:sWW_out/WAVE=sWW_out
	
	Variable i
	for(i=0; i<DimSize(sWW_loaded,0); i+=1)
		String tempWaveName = NameOfWave(sWW_loaded[i])
		Duplicate/O sWW_loaded[i], :out:$tempWaveName
		Concatenate/O/DL/NP=0 {sWW_loaded[i], sWW[i]}, :out:$tempWaveName/WAVE=sWWi
		sWW_out[i] = sWWi
	endfor
	
	if(saveRes == 1)
		String saveWavesList = WaveRefWaveToList(sWW_out,0)
		Save/T/M="\r\n"/I/B/P=savePathDA1 saveWavesList as "AllAnalyses.itx"
		Save/J/M="\r\n"/I/B/P=savePathDA1/W/U={1,0,1,0} saveWavesList as "AllAnalyses.txt"
	endif
	
End

Function/WAVE testLoadData2()
	testInitSavePath()
	SetDataFolder root:
	if(DataFolderExists("ResultsConcat")==0)
		NewDataFolder root:ResultsConcat
	endif
	
	DFREF wavesHere = root:ResultsConcat
	DFREF saveRefHere = wavesHere
	SetDataFolder wavesHere
	
	LoadWave/T/O/I/P=savePathDA1 "AllAnalyses.itx"
	
	Wave/WAVE sWW_loaded = testMakeSaveWavesWave(wavesHere, saveRefHere, "saveWavesWave_loaded")
	SetDataFolder wavesHere
	return sWW_loaded
End

Function testConcatData2([saveRes])
	Variable saveRes
	if(ParamIsDefault(saveRes))
		saveRes = 1
	endif
	DoAlert 1, "Continue with data concatenation?"
	if(V_flag == 2)
		Abort
	endif
	SetDataFolder root:
	if(DataFolderExists("imported")==0)
		NewDataFolder :imported
	endif
	SetDataFolder :imported
	
	String baseDir = "C:Users:kzw421:Desktop:Adrian G R:ephys recordings:"
	String subDirList = "2024-07-25:P1_het:;2024-07-29:P1_het:;2024-08-05:P4_het:;2024-07-29:P2_KO:;2024-07-30:P2_KO:;2024-07-30:P3_KO:;2024-07-31:P2_KO:;2024-07-31:P3_KO:;2024-08-01:P2_KO:;2024-08-01:P3_KO:;2024-08-06:P2_KO:;2024-08-07:P2_KO:;2024-08-06:P2_KO213:;2024-08-07:P2_KO213:;"
	String fileNameCommon = "ThisAnalysis02.itx"
	Variable numFiles = ItemsInList(subDirList,";")
	Make/WAVE/O/N=0 loadedWaves
	//Wave/WAVE loadedWaves
	
	Variable k,l
	for(k=0; k<numFiles; k+=1)
		String currentFilePath = baseDir+StringFromList(k,subDirList,";")+fileNameCommon
		String newDFname = "in"+num2str(k)
		NewDataFolder :$newDFname
		SetDataFolder :$newDFname
		LoadWave/T/O currentFilePath
		
		Redimension/N=(ItemsInList(S_waveNames),k+1) loadedWaves
		SetDimLabel 1, k, $newDFname, loadedWaves
		for(l=0; l<ItemsInList(S_waveNames); l+=1)
			loadedWaves[l][k] = $StringFromList(l,S_waveNames,";")
		endfor
		SetDataFolder root:imported
	endfor
	
	NewDataFolder :concat
	SetDataFolder :concat
	DFREF concatDF = GetDataFolderDFR()
	
	for(k=0; k<DimSize(loadedWaves,0); k+=1)
		Duplicate/O/RMD=[k][] loadedWaves, loadedWavesRow
		Wave tempWave = loadedWaves[k][0]
		String tempName = NameOfWave(tempWave)
		Concatenate/DL/NP=0/O {loadedWavesRow}, $tempName
	endfor
	KillWaves loadedWavesRow
	
	DFREF currentDF = GetDataFolderDFR()
	Variable numWavesInDF = CountObjectsDFR(currentDF,1)
	Make/WAVE/N=(numWavesInDF) concatWaves
	
	for(k=0; k<numWavesInDF; k+=1)
		Wave currentWave = WaveRefIndexedDFR(currentDF,k)
		concatWaves[k] = currentWave
		SetDimLabel 0, k, $NameOfWave(currentWave), concatWaves
		if(WaveType(currentWave,1)==1)
			cleanupZeroNanDims2(currentWave,0,doInPlace=1)
		elseif(WaveType(currentWave,1)==2)
			cleanupEmptyDimsT2(currentWave,0,doInPlace=1)
		endif
	endfor
	
	DoAlert 1, "Do you want to do the additional analysis to group into genotype and trains etc.?"
	if(V_flag == 1)
		groupConditionRowsToWaves2(9)
		groupConditionRowsToWaves2(5)
		groupConditionRowsToWaves2(3)
		groupConditionRowsToWaves2(1)
	endif
	
	DoAlert 1, "Do you want to do open the relevant waves?"
	if(V_flag == 1)
		testOpenStuff()
	endif
	
	if(1==0)//
	//Wave/WAVE sWW = testSaveData()
	Wave/WAVE sWW_loaded = testLoadData2()
	SetDataFolder root:ResultsConcat
	if(DataFolderExists("out")==0)
		NewDataFolder :out
	endif
	
	Duplicate/O/WAVE sWW_loaded, :out:sWW_out/WAVE=sWW_out
	
	Variable i
	for(i=0; i<DimSize(sWW_loaded,0); i+=1)
		String tempWaveName = NameOfWave(sWW_loaded[i])
		Duplicate/O sWW_loaded[i], :out:$tempWaveName
		//Concatenate/O/DL/NP=0 {sWW_loaded[i], sWW[i]}, :out:$tempWaveName/WAVE=sWWi
		sWW_out[i] = sWWi
	endfor
	
	if(saveRes == 1)
		String saveWavesList = WaveRefWaveToList(sWW_out,0)
		Save/T/M="\r\n"/I/B/P=savePathDA1 saveWavesList as "AllAnalyses.itx"
		Save/J/M="\r\n"/I/B/P=savePathDA1/W/U={1,0,1,0} saveWavesList as "AllAnalyses.txt"
	endif
	endif//
End

Function testOpenStuff([kill])
	Variable kill
	if(ParamIsDefault(kill))
		kill = 0
	endif
	Variable left = 10, top = 10, width = 400, height = 200
	if(kill <= 0)
		//String subDirList = "grouped_1s;grouped_3s;grouped_5s;grouped_9s;"
		String subDirList = "grouped_1s_2;grouped_3s_2;grouped_5s_2;grouped_9s_2;"
		String resTypePref = "TrainAmp_"
		String t = resTypePref
		String resTypeList = "Sync;"
		//String resTypeList = "Sync;Sync_Norm;CASyncCum;CSyncCum;Sync_PPR;RTSRy;"
		String genoPrefList = "KO213;KO;Het;"
		Variable i,j,k,tableIndex=1
		for(i=0; i<ItemsInList(subDirList); i+=1)
			String subDirStr = StringFromList(i,subDirList,";")
			DFREF subDir = $subDirStr
			for(j=0; j<ItemsInList(resTypeList); j+=1)
				String b = StringFromList(j,resTypeList,";")
				for(k=0; k<ItemsInList(genoPrefList); k+=1)
					String c = StringFromList(k,genoPrefList,";")
					String tableName = "Tbl"+num2str(tableIndex)
					String wName = c+"_"+t+b
					String tableTitle = num2str(tableIndex)+"_"+subDirStr+"_"+c+"_"+b
					
					switch(k)
						case 0:
							Edit/K=1/N=$tableName/W=(left,top,left+width,top+height) subDir:$wName as tableTitle
							break
						case 1:
							Edit/K=1/N=$tableName/W=(2*left+width,top,2*left+2*width,top+height) subDir:$wName as tableTitle
							break
						case 2:
							Edit/K=1/N=$tableName/W=(left,7*top+height,left+width,7*top+2*height) subDir:$wName as tableTitle
							break
					endswitch
					tableIndex += 1
				endfor
			endfor
		endfor
	elseif(kill >= 1)
		Variable w
		for(w=kill; w<100; w+=1)
			KillWindow/Z $("Tbl"+num2str(w))
		endfor
	endif
End

Function/WAVE testMakeSaveWavesWave(DFREF wavesAreHere, DFREF saveRefHere, String saveName)
	SetDataFolder saveRefHere
	Make/WAVE/O/N=(28) $saveName
	Wave/WAVE sWW = $saveName
	
	SetDataFolder wavesAreHere
	sWW[0] = $"TrainExperiments_allInfo"
	sWW[1] = $"TrainAmp_fromInitBaseline"
	sWW[2] = $"TrainAmp_fromInitBaseline_Norm"
	sWW[3] = $"TrainAmp_All"
	sWW[4] = $"TrainAmp_corrected"
	sWW[5] = $"TrainAmp_Delay"
	sWW[6] = $"TrainAmp_RecovAmpFrac"
	sWW[7] = $"TrainAmp_Sync"
	sWW[8] = $"TrainAmp_Sync_Norm"
	sWW[9] = $"TrainAmp_CTimepoints"
	sWW[10] = $"TrainAmp_CAll"
	sWW[11] = $"TrainAmp_CCum"
	sWW[12] = $"TrainAmp_CSync"
	sWW[13] = $"TrainAmp_CSyncCum"
	sWW[14] = $"TrainAmp_CASync"
	sWW[15] = $"TrainAmp_CASyncCum"
	sWW[16] = $"TrainAmp_RTSRx"
	sWW[17] = $"TrainAmp_RTSRy"
	sWW[18] = $"TrainAmp_RTSRinfo"
	sWW[19] = $"TrainAmp_All_PPR"
	sWW[20] = $"TrainAmp_fromInitBaseline_PPR"
	sWW[21] = $"TrainAmp_Sync_PPR"
	sWW[22] = $"TrainAmp_Csync_PPR"
	sWW[23] = $"TrainAmp_CAsync_PPR"
	sWW[24] = $"TrainAmp_CAll_PPR"
	sWW[25] = $"TrainAmp_CCum_PPR"
	sWW[26] = $"TrainAmp_CSyncCum_PPR"
	sWW[27] = $"TrainAmp_CASyncCum_PPR"
	
	SetDataFolder saveRefHere
	
	return sWW
End

Function abortOnZeroInWaveRefWave(inWave)
	Wave/WAVE inWave
	Variable i
	for(i=0; i<DimSize(inWave,0); i+=1)
		if(inWave[i] == 0)
			Abort "One or more wave references missing"
		endif
	endfor
End

Function/WAVE cleanupZeroDims2(inWave, inDim, [doInPlace])
	Wave inWave
	Variable inDim
	Variable doInPlace
	if(ParamIsDefault(doInPlace))
		doInPlace = 0
	endif
	
	String outWaveName = NameOfWave(inWave)
	
	switch(doInPlace)
		case 0:
			if(DataFolderExists("clean")==0)
				NewDataFolder :clean
			endif
			Duplicate/O inWave, :clean:$outWaveName
			Wave outWave = :clean:$outWaveName
			break
		case 1:
			Wave outWave = inWave
			break
	endswitch
	
	//Make/FREE/N=0 indexWave
	
	Variable i
	switch(inDim)
		case 0:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				MatrixOp/O/FREE sumWave = sumRows(outWave)
				if(sumWave[i] == 0)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
		case 1:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				MatrixOp/O/FREE sumWave = sumCols(outWave)
				if(sumWave[i] == 0)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
	endswitch
	return outWave
End

Function/WAVE cleanupZeroNanDims2(inWave, inDim, [doInPlace])
	Wave inWave
	Variable inDim
	Variable doInPlace
	if(ParamIsDefault(doInPlace))
		doInPlace = 0
	endif
	
	String outWaveName = NameOfWave(inWave)
	
	switch(doInPlace)
		case 0:
			if(DataFolderExists("clean")==0)
				NewDataFolder :clean
			endif
			Duplicate/O inWave, :clean:$outWaveName
			Wave outWave = :clean:$outWaveName
			break
		case 1:
			Wave outWave = inWave
			break
	endswitch
	
	//Make/FREE/N=0 indexWave
	
	Variable i
	switch(inDim)
		case 0:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				MatrixOp/O/FREE sumWave = sumRows(outWave)
				if(sumWave[i] == 0 || numType(sumWave[i]) == 2)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
		case 1:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				MatrixOp/O/FREE sumWave = sumCols(outWave)
				if(sumWave[i] == 0 || numType(sumWave[i]) == 2)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
	endswitch
	return outWave
End

Function/WAVE cleanupEmptyDimsT2(inWave, inDim, [doInPlace])
	Wave/T inWave
	Variable inDim
	Variable doInPlace
	if(ParamIsDefault(doInPlace))
		doInPlace = 0
	endif
	
	String outWaveName = NameOfWave(inWave)
	
	switch(doInPlace)
		case 0:
			if(DataFolderExists("clean")==0)
				NewDataFolder :clean
			endif
			Duplicate/O inWave, :clean:$outWaveName
			Wave/T outWave = :clean:$outWaveName
			break
		case 1:
			Wave/T outWave = inWave
			break
	endswitch
	
	//Make/FREE/N=0 indexWave
	
	Variable i
	switch(inDim)
		case 0:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				if(cmpstr(outWave[i], "") == 0)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
		case 1:
			for(i=DimSize(outWave,inDim)-1; i>=0; i-=1)
				if(cmpstr(outWave[i], "") == 0)
					//InsertPoints/M=(inDim) INF, 1, indexWave
					//indexWave[INF] = i
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
	endswitch
	return outWave
End

Function/WAVE cleanupZeroDims(inWave, inDim, [doInPlace])
	Wave inWave
	Variable inDim
	Variable doInPlace
	if(ParamIsDefault(doInPlace))
		doInPlace = 0
	endif
	
	String outWaveName = NameOfWave(inWave)
	
	switch(doInPlace)
		case 0:
			if(DataFolderExists("clean")==0)
				NewDataFolder :clean
			endif
			Duplicate/O inWave, :clean:$outWaveName
			Wave outWave = :clean:$outWaveName
			break
		case 1:
			Wave outWave = inWave
			break
	endswitch
	
	Variable i
	switch(inDim)
		case 0:
			for(i=0; i<DimSize(outWave,inDim); i+=1)
				MatrixOp/O/FREE sumWave = sumRows(outWave)
				if(sumWave[i] == 0)
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
		case 1:
			for(i=0; i<DimSize(outWave,inDim); i+=1)
				MatrixOp/O/FREE sumWave = sumCols(outWave)
				if(sumWave[0][i] == 0)
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
	endswitch
	return outWave
End

Function/WAVE cleanupEmptyDimsT(inWave, inDim)
	Wave/T inWave
	Variable inDim
	if(DataFolderExists("clean")==0)
		NewDataFolder :clean
	endif
	String outWaveName = NameOfWave(inWave)
	Duplicate/O/T inWave, :clean:$outWaveName
	Wave/T outWave = :clean:$outWaveName
	
	//outWave = outWave==0 ? NaN : outWave
	Variable i
	switch(inDim)
		case 0:
			for(i=0; i<DimSize(outWave,inDim); i+=1)
				if(cmpstr(outWave[i], "") == 0)
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
		case 1:
			for(i=0; i<DimSize(outWave,inDim); i+=1)
				if(cmpstr(outWave[0][i], "") == 0)
					DeletePoints/M=(inDim) i, 1, outWave
					//print i
				endif
			endfor
			break
	endswitch
	return outWave
End

Function cleanupWaves1()
	DFREF currentDF = GetDataFolderDFR()
	Variable numWavesInDF = CountObjectsDFR(currentDF,1)
	
	Variable i
	for(i=0; i<numWavesInDF; i+=1)
		Wave currentWave = WaveRefIndexedDFR(currentDF,i)
		if(WaveType(currentWave,1)==1)
			cleanupZeroDims(currentWave,0)
		elseif(WaveType(currentWave,1)==2)
			cleanupEmptyDimsT(currentWave,0)
		endif
	endfor
End

Function groupConditionRowsToWaves2(trainSecCond, [sweepNum, doRTSR_bool])
	Variable trainSecCond
	Variable sweepNum
	Variable doRTSR_bool
	if(ParamIsDefault(sweepNum))
		sweepNum = 1
	endif
	if(ParamIsDefault(doRTSR_bool))
		doRTSR_bool = 1
	endif
	DFREF saveDFR = GetDataFolderDFR()
	//SetDataFolder root:clean
	String newDFname = "grouped_"+num2str(trainSecCond)+"s_"+num2str(sweepNum)
	if(DataFolderExists(newDFname)==0)
		NewDataFolder :$newDFname
	endif
	DFREF newDF = :$newDFname
	DFREF currentDF = GetDataFolderDFR()
	Variable numWavesInDF = CountObjectsDFR(currentDF,1)
	
	Wave/T w_info = TrainExperiments_allInfo
	Wave/T w_RTSRinfo = TrainAmp_RTSRInfo
	
	Variable i, j
	for(i=0; i<numWavesInDF; i+=1)
		Wave currentWave = WaveRefIndexedDFR(currentDF,i)
		if(WaveType(currentWave,1)==1)
			String currentWaveName = NameOfWave(currentWave)
			String prefix1 = "KO_"
			String prefix2 = "Het_"
			String prefix3 = "KO213_"
			String newWaveName1 = prefix1+currentWaveName
			String newWaveName2 = prefix2+currentWaveName
			String newWaveName3 = prefix3+currentWaveName
			String newInfoWaveName1 = prefix1+NameOfWave(w_info)
			String newInfoWaveName2 = prefix2+NameOfWave(w_info)
			String newInfoWaveName3 = prefix3+NameOfWave(w_info)
			String newRTSRInfoWaveName1 = prefix1+NameOfWave(w_RTSRinfo)
			String newRTSRInfoWaveName2 = prefix2+NameOfWave(w_RTSRinfo)
			String newRTSRInfoWaveName3 = prefix3+NameOfWave(w_RTSRinfo)
			Make/O/N=(1,DimSize(currentWave,1)) newDF:$newWaveName1
			Make/O/N=(1,DimSize(currentWave,1)) newDF:$newWaveName2
			Make/O/N=(1,DimSize(currentWave,1)) newDF:$newWaveName3
			Make/T/O/N=(1,DimSize(w_info,1)) newDF:$newInfoWaveName1
			Make/T/O/N=(1,DimSize(w_info,1)) newDF:$newInfoWaveName2
			Make/T/O/N=(1,DimSize(w_info,1)) newDF:$newInfoWaveName3
			Make/T/O/N=(1,DimSize(w_RTSRinfo,1)) newDF:$newRTSRInfoWaveName1
			Make/T/O/N=(1,DimSize(w_RTSRinfo,1)) newDF:$newRTSRInfoWaveName2
			Make/T/O/N=(1,DimSize(w_RTSRinfo,1)) newDF:$newRTSRInfoWaveName3
			//Duplicate/O currentWave, :grouped:$newWaveName1, :grouped:$newWaveName2, :grouped:$newWaveName3
			Wave newWave1 = newDF:$newWaveName1
			Wave newWave2 = newDF:$newWaveName2
			Wave newWave3 = newDF:$newWaveName3
			Wave/T newInfoWave1 = newDF:$newInfoWaveName1
			Wave/T newInfoWave2 = newDF:$newInfoWaveName2
			Wave/T newInfoWave3 = newDF:$newInfoWaveName3
			Wave/T newRTSRInfoWave1 = newDF:$newRTSRInfoWaveName1
			Wave/T newRTSRInfoWave2 = newDF:$newRTSRInfoWaveName2
			Wave/T newRTSRInfoWave3 = newDF:$newRTSRInfoWaveName3
			Variable index1 = 0, index2 = 0, index3 = 0, index4 = 0, index5 = 0, index6 = 0
			//newWave1 = 0
			//newWave2 = 0
			//newWave3 = 0
			if(strsearch(currentWaveName,"RTSR",0) == -1)
				for(j=0; j<DimSize(currentWave,0); j+=1)
					String dimLabel1 = w_info[j][%fileName]+"_"+get_singleRegExMatch(w_info[j][%protocol],".([0-9]s)$")+"_"+num2str(str2num(w_info[j][%sweep]))+"_"+w_info[j][%folderLast]
					Variable bool_condition2 = 0
					if(str2num(w_info[j][%sweep]) == sweepNum && str2num(get_singleRegExMatch(w_info[j][%protocol],".([0-9])s$")) == trainSecCond)
						bool_condition2 = 1
					endif
					
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(KO)$")==1 && bool_condition2 == 1)
						if(index1!=0)
							InsertPoints/M=0 INF, 1, newWave1
							InsertPoints/M=0 INF, 1, newInfoWave1
						endif
						newWave1[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave1,0)-1, $dimLabel1, newWave1
						newInfoWave1[INF][] = w_info[j][q]
						SetDimLabel 0, DimSize(newInfoWave1,0)-1, $dimLabel1, newInfoWave1
						index1 += 1
					endif
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(het)$")==1 && bool_condition2 == 1)
						if(index2!=0)
							InsertPoints/M=0 INF, 1, newWave2
							InsertPoints/M=0 INF, 1, newInfoWave2
						endif
						newWave2[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave2,0)-1, $dimLabel1, newWave2
						newInfoWave2[INF][] = w_info[j][q]
						SetDimLabel 0, DimSize(newInfoWave2,0)-1, $dimLabel1, newInfoWave2
						index2 += 1
					endif
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(KO213)$")==1 && bool_condition2 == 1)
						if(index3!=0)
							InsertPoints/M=0 INF, 1, newWave3
							InsertPoints/M=0 INF, 1, newInfoWave3
						endif
						newWave3[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave3,0)-1, $dimLabel1, newWave3
						newInfoWave3[INF][] = w_info[j][q]
						SetDimLabel 0, DimSize(newInfoWave3,0)-1, $dimLabel1, newInfoWave3
						index3 += 1
					endif
				endfor
			endif
			if(strsearch(currentWaveName,"RTSR",0) >= 0 && doRTSR_bool == 1)
				for(j=0; j<DimSize(currentWave,0); j+=1)
					String dimLabel2 = w_RTSRinfo[j][9]+"_"+get_singleRegExMatch(w_RTSRinfo[j][6],".([0-9]s)$")+"_"+num2str(str2num(w_RTSRinfo[j][3]))+"_"+w_RTSRinfo[j][10]
					Variable bool_condition3 = 1
					
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(KO)$")==1 && bool_condition3 == 1)
						if(index4!=0)
							InsertPoints/M=0 INF, 1, newWave1
							InsertPoints/M=0 INF, 1, newRTSRInfoWave1
						endif
						newWave1[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave1,0)-1, $dimLabel2, newWave1
						newRTSRInfoWave1[INF][] = w_RTSRinfo[j][q]
						SetDimLabel 0, DimSize(newRTSRInfoWave1,0)-1, $dimLabel2, newRTSRInfoWave1
						index4 += 1
					endif
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(het)$")==1 && bool_condition3 == 1)
						if(index5!=0)
							InsertPoints/M=0 INF, 1, newWave2
							InsertPoints/M=0 INF, 1, newRTSRInfoWave2
						endif
						newWave2[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave2,0)-1, $dimLabel2, newWave2
						newRTSRInfoWave2[INF][] = w_RTSRinfo[j][q]
						SetDimLabel 0, DimSize(newRTSRInfoWave2,0)-1, $dimLabel2, newRTSRInfoWave2
						index5 += 1
					endif
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(KO213)$")==1 && bool_condition3 == 1)
						if(index6!=0)
							InsertPoints/M=0 INF, 1, newWave3
							InsertPoints/M=0 INF, 1, newRTSRInfoWave3
						endif
						newWave3[INF][] = currentWave[j][q]
						SetDimLabel 0, DimSize(newWave3,0)-1, $dimLabel2, newWave3
						newRTSRInfoWave3[INF][] = w_RTSRinfo[j][q]
						SetDimLabel 0, DimSize(newRTSRInfoWave3,0)-1, $dimLabel2, newRTSRInfoWave3
						index6 += 1
					endif
				endfor
			endif
			//cleanupZeroDims(newWave1,0, doInPlace=1)
			//cleanupZeroDims(newWave2,0, doInPlace=1)
			//cleanupZeroDims(newWave3,0, doInPlace=1)
		endif
	endfor
	//SetDataFolder :grouped
	//DFREF currentDF2 = GetDataFolderDFR()
	//Variable numWavesInDF2 = CountObjectsDFR(currentDF2,1)
	
	//for(i=0; i<numWavesInDF2; i+=1)
		//Wave currentWave2 = WaveRefIndexedDFR(currentDF2,i)
		//if(WaveType(currentWave2,1)==1)
			//cleanupZeroDims(currentWave2,0)
		//elseif(WaveType(currentWave,1)==2)
			//cleanupEmptyDimsT(currentWave,0)
		//endif
	//endfor
	//cleanupWaves1()
	SetDataFolder saveDFR
End

Function groupConditionRowsToWaves()
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder root:clean
	if(DataFolderExists("grouped")==0)
		NewDataFolder :grouped
	endif
	DFREF currentDF = GetDataFolderDFR()
	Variable numWavesInDF = CountObjectsDFR(currentDF,1)
	
	Wave/T w_info = TrainExperiments_allInfo
	Wave/T w_RTSRinfo = TrainAmp_RTSRInfo
	
	Variable i, j
	for(i=0; i<numWavesInDF; i+=1)
		Wave currentWave = WaveRefIndexedDFR(currentDF,i)
		if(WaveType(currentWave,1)==1)
			String currentWaveName = NameOfWave(currentWave)
			String newWaveName1 = "KO_"+currentWaveName
			String newWaveName2 = "Het_"+currentWaveName
			String newWaveName3 = "KO213_"+currentWaveName
			Duplicate/O currentWave, :grouped:$newWaveName1, :grouped:$newWaveName2, :grouped:$newWaveName3
			Wave newWave1 = :grouped:$newWaveName1
			Wave newWave2 = :grouped:$newWaveName2
			Wave newWave3 = :grouped:$newWaveName3
			newWave1 = 0
			newWave2 = 0
			newWave3 = 0
			if(strsearch(currentWaveName,"RTSR",0) == -1)
				for(j=0; j<DimSize(currentWave,0); j+=1)
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(KO)$")==1)
						newWave1[j][] = currentWave[j][q]
					endif
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(het)$")==1)
						newWave2[j][] = currentWave[j][q]
					endif
					if(singleRegExMatch(w_info[j][%folderLast],"(?i)(KO213)$")==1)
						newWave3[j][] = currentWave[j][q]
					endif
				endfor
			endif
			if(strsearch(currentWaveName,"RTSR",0) >= 0)
				for(j=0; j<DimSize(currentWave,0); j+=1)
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(KO)$")==1)
						newWave1[j][] = currentWave[j][q]
					endif
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(het)$")==1)
						newWave2[j][] = currentWave[j][q]
					endif
					if(singleRegExMatch(w_RTSRinfo[j][10],"(?i)(KO213)$")==1)
						newWave3[j][] = currentWave[j][q]
					endif
				endfor
			endif
			//cleanupZeroDims(newWave1,0, doInPlace=1)
			//cleanupZeroDims(newWave2,0, doInPlace=1)
			//cleanupZeroDims(newWave3,0, doInPlace=1)
		endif
	endfor
	SetDataFolder :grouped
	DFREF currentDF2 = GetDataFolderDFR()
	Variable numWavesInDF2 = CountObjectsDFR(currentDF2,1)
	
	//for(i=0; i<numWavesInDF2; i+=1)
		//Wave currentWave2 = WaveRefIndexedDFR(currentDF2,i)
		//if(WaveType(currentWave2,1)==1)
			//cleanupZeroDims(currentWave2,0)
		//elseif(WaveType(currentWave,1)==2)
			//cleanupEmptyDimsT(currentWave,0)
		//endif
	//endfor
	cleanupWaves1()
	SetDataFolder saveDFR
End

Function singleRegExMatch(inString, regExPattern)
	String inString
	String regExPattern
	String outStr
	Variable sweepOutInt
	
	SplitString/E=(regExPattern) inString, outStr
	if(V_flag < 1)
		//print "No RegEx match!"
	endif
	
	return V_flag
End