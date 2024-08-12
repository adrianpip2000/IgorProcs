///////////////////////////////////////////////////////////////////////////
//////////// *** Version history in JBS lab *** ///////////////////////////
///////////////////////////////////////////////////////////////////////////
// NeuroB_(27032024)_fork1.ipf --> NeuroB_(12072024)_fork2.ipf
// - Substantial modifications done by AdrianGR during July-August 2024
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
#pragma IgorVersion=6.0
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
NewPanel/W=(20,50,215,700) /N=NeuroBunny		
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
	DrawLine/W=NeuroBunny 5,620,190,620
	DrawLine/W=NeuroBunny 5,520,190,520
//		Button ctrlFolder,pos={5,625},size={90,20},proc=proc_GaussFilter,title="GaussFilter",win=NeuroBunny, fsize=10
		Button ctrlResWave,pos={5,625},size={90,20},proc=proc_Init,title="Init",win=NeuroBunny, fsize=10, fColor=(51143,62708,65535)
		Button ctrlBL1a,pos={5,565},size={90,20},proc=procMenuNB,title="Shift @ Start",win=NeuroBunny, fsize=10
		Button ctrlBL1b,pos={100,565},size={90,20},proc=procMenuNB,title="Shift [A,B]",win=NeuroBunny, fsize=10
		Button ctrlBL2a,pos={5,590},size={90,20},proc=procMenuNB,title="Corr. Full Trace", fsize=10
		Button ctrlBL2b,pos={100,590},size={90,20},proc=procMenuNB,title="Corr. [A,B][C,D]", fsize=10
		Button ctrlWvAverage,pos={100,625},size={90,20},proc=procMenuNB,title="Average Waves",win=NeuroBunny, fsize=10
		Button ctrlAutoscale,pos={5,530},size={90,30},proc=procMenuNB,title="Autoscale",win=NeuroBunny, fsize=10

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
			CheckBox checkFixCursor,pos={10, 445}, help={"Check if you want to fix cursor"}, noproc, title="fix cursors",win=NeuroBunny, fsize=10			
			Button ctrlForwA,pos={50,470},size={40,20},fColor=(20,43,158),proc=proc_ForwA,title="A right",win=NeuroBunny,disable=0, fsize=10
			Button ctrlBackwA,pos={10,470},size={40, 20},fColor=(20,43,158),proc=proc_BackwA,title="A left",win=NeuroBunny,disable=0, fsize=10
			Button ctrlForwB,pos={50,490},size={40,20},fColor=(20,43,158),proc=proc_ForwB,title="B right",win=NeuroBunny,disable=0, fsize=10
			Button ctrlBackwB,pos={10,490},size={40,20},fColor=(20,43,158),proc=proc_BackwB,title="B left",win=NeuroBunny,disable=0, fsize=10
			CheckBox chk_IgnoreSavedCursors,pos={80, 445},value=1, help={"Check to ignore saved cursor positions"}, noproc, title="Ignore saved cursors",win=NeuroBunny, fsize=10
			Button button_RefreshCursors,pos={100,470},size={80,20},proc=proc_button_RefreshCursors,title="Refresh cursors",win=NeuroBunny,disable=0, fsize=10
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

Function testCur()
	STRUCT RGBColor rgb
	
End

Structure curRGB
	STRUCT RGBColor A_RGB
	STRUCT RGBColor B_RGB
	STRUCT RGBColor C_RGB
	STRUCT RGBColor D_RGB
EndStructure

Function [Variable r, Variable g, Variable b] what()
	r = 0
	g = 0
	b = 55555
	return [r,g,b]
End

Function whatf()
	STRUCT curRGB cr
	cr.A_RGB.red = 10
End

Function setCursorsInit(String inWave)
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1/P A,$inWave,0
	Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1/P B,$inWave,100
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1/P C,$inWave,numpnts($inWave)-200
	Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1/P D,$inWave,numpnts($inWave)-100
	//Cursor/C=(65535,33232,0)/W=Experiments/H=1/S=1/L=1/P E,$inWave,numpnts($inWave)-1
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
	
		//----
		//TODO: fix this -AdrianGR
		ControlInfo/W=NeuroBunny chk_IgnoreSavedCursors
		variable flag_IgnoreSavedCursors = V_Value
		variable cursorsFound, cursorsFoundIndex, curA, curB, curC, curD
		[cursorsFound, cursorsFoundIndex, curA, curB, curC, curD] = getSavedCursors(gTheWave)
		
		if((cursorsFound==1 && flag_IgnoreSavedCursors==0) && flag_checkFixCursor==0)
			//Variable x0, x1, x2, x3
			x0=curA
			x1=curB
			x2=curC
			x3=curD
			print x0,x1,x2,x3
			//SetDataFolder root:
			Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
			NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		else //if(cursorsFound==0 || flag_IgnoreSavedCursors==1 || flag_checkFixCursor==0)
			NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
		endif
	
		update_Freq(gTheWave)
		//DoWindow/K Experiments
		KillWindow/Z Experiments
		Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		ModifyGraph/W=Experiments rgb=(0,39168,0)
		ShowInfo/W=Experiments
		setCursorsInit(gTheWave)
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 A,$gTheWave,gCursorA
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 B,$gTheWave,gCursorB
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 C,$gTheWave,gCursorC
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 D,$gTheWave,gCursorD
//		Cursor/C=(65535,33232,0)/H=1/S=1/L=1 E,$gTheWave,numpnts($gTheWave)-1
	endif
	SetDataFolder root:
End


Function DisplayPreviousWave(list)
	String list 								// A semicolon-separated list generated while initialization
	SVAR gTheWave=root:Globals:gTheWave
	NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
	SVAR gWaveList=root:Globals:gWaveList
	
	ControlInfo /W=NeuroBunny checkFixCursor
	variable flag_checkFixCursor = V_Value
	if (V_Value==1)
		Variable x0, x1, x2, x3
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
	
		//----
		//TODO: fix this -AdrianGR
		ControlInfo/W=NeuroBunny chk_IgnoreSavedCursors
		variable flag_IgnoreSavedCursors = V_Value
		variable cursorsFound, cursorsFoundIndex, curA, curB, curC, curD
		[cursorsFound, cursorsFoundIndex, curA, curB, curC, curD] = getSavedCursors(gTheWave)
		
		if((cursorsFound==1 && flag_IgnoreSavedCursors==0) && flag_checkFixCursor==0)
			//Variable x0, x1, x2, x3
			x0=curA
			x1=curB
			x2=curC
			x3=curD
			//SetDataFolder root:
			Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
			NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		else //if(cursorsFound==0 || flag_IgnoreSavedCursors==1 || flag_checkFixCursor==0)
			NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
		endif

		update_Freq(gTheWave)
		//DoWindow/K Experiments
		KillWindow Experiments
		Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
		ModifyGraph/W=Experiments rgb=(0,39168,0)
		ShowInfo/W=Experiments
		setCursorsInit(gTheWave)
		//Cursor/C=(65535,0,0)/H=1/S=1/L=1 A,$gTheWave,gCursorA
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 B,$gTheWave,gCursorB
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 C,$gTheWave,gCursorC
		//Cursor/C=(65535,33232,0)/H=1/S=1/L=1 D,$gTheWave,gCursorD
	endif
	SetDataFolder root:
End

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

////////////////////////////////////////// I think this works now(?) -AdrianGR
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
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 A,$gTheWave,x0
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 B,$gTheWave,x1
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 C,$gTheWave,x2
			Cursor/C=(65535,0,0)/W=Experiments/H=1/S=1/L=1 D,$gTheWave,x3
			SetDataFolder root:
			//Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
			//NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		elseif((cursorsFound==0 || cursorsFound==1) && flag_IgnoreSavedCursors==1)
			KillWindow/Z Experiments
			Display/N=Experiments/K=1/W=(180,50,955,700) $gTheWave
			ModifyGraph/W=Experiments rgb=(0,39168,0)
			ShowInfo/W=Experiments
			setCursorsInit(gTheWave)
			SetDataFolder root:
			//Variable/G gCursorA=x0, gCursorB=x1, gCursorC=x2, gCursorD=x3	
			//NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:gCursorA, gCursorB=root:gCursorB, gCursorC=root:gCursorC, gCursorD=root:gCursorD
		elseif(cursorsFound==0 && flag_IgnoreSavedCursors==0)
			print "Could not find saved cursors for this wave"
			CheckBox chk_IgnoreSavedCursors, value=1
		else
			//NVAR gwaveindex=root:Globals:gwaveindex, gCursorA=root:Globals:gCursorA, gCursorB=root:Globals:gCursorB, gCursorC=root:Globals:gCursorC, gCursorD=root:Globals:gCursorD
		endif	
	elseif(flag_checkFixCursor==1)
		DoAlert 0, "Saved cursors functionality is not (yet) compatible with fixed cursors!"
	endif
		
	SetDataFolder root:
End
///////////////////////////////////////////

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
		
		wave/Z w_temp=root:WorkData:$gTheWave			// Make references to used waves
		wave/Z w_results=root:Results:TrainAmp_Csync
		wave/Z w_Aresults=root:Results:TrainAmp_CAsync
		wave/Z w_Allresults=root:Results:TrainAmp_CAll
		wave/Z w_Cumresults=root:Results:TrainAmp_CCum
		wave/Z w_BExtrRRP=root:Results:Backextr:TrainBackextr_RRP
		wave/Z w_BExtrPrate=root:Results:Backextr:TrainBackextr_Prate
		wave/Z w_BExtrRelPr=root:Results:Backextr:TrainBackextr_RelPr
		wave/T/Z w_BExtrRelOK=root:Results:Backextr:TrainBackextr_OK
		wave/Z w_CCwave=root:Results:Backextr:$CCwave
		wave/Z w_fitwave=root:Results:Backextr:$Fitwave
		
		n=DimSize(w_results,0)+1
		Redimension/N=(n,-1) w_results, w_Aresults, w_Allresults, w_Cumresults
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
				w_results[n-1][j] += (charge)
				w_Aresults[n-1][j] += (Baseline_charge)
				w_Allresults[n-1][j] += (charge)+(Baseline_charge)
				if(j==0)
					w_Cumresults[n-1][j] += (charge)+(Baseline_charge)
				else
					w_Cumresults[n-1][j] += (charge)+(Baseline_charge) - w_Cumresults[n][j-1]
				endif
				w_Cumresults[n-1][j]*=-1
				w_CCwave[j]=w_Cumresults[n-1][j]
				j += 1
		while (j<gTrainStim)
	
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
	Variable V_fitOptions=4
	string activetrace, destwavename, fit_name
	variable amp, fitmax, xfit, baseline, Init_amp, Init_baseline
	Variable DoCharge=Nan
	variable/G cursorA_orig,cursorB_orig,cursorC_orig
	variable vmin_cache
	
	variable post_pulse_baseline, V_avg, i_loc//, K0 //K0 should not be declared because it is a system variable! -AdrianGR
	
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
	

	Variable cols = gTrainStim
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
	if (WaveExists('TrainAmp_fromX0')==0)		//Wave for saving Amplitudes to level of end of previous pulse //-AdrianGR
		Make/N=(1,cols) 'TrainAmp_fromX0'
	endif
	if (WaveExists('TrainInt_TonicAUCtotal')==0)		//Wave for saving tonic release AUC //-AdrianGR
		Make/N=(cols) 'TrainInt_TonicAUCtotal'
	endif
	if (WaveExists('TrainInt_TonicAUC')==0)
		Make/N=(1,cols) 'TrainInt_TonicAUC'
	endif
	if (WaveExists('TrainInt_TonicX')==0)		//Wave for saving tonic release X-positions //-AdrianGR
		Make/N=(1,cols+1) 'TrainInt_TonicX'
	endif
	if (WaveExists('TrainInt_TonicY')==0)		//Wave for saving tonic release Y-positions //-AdrianGR
		Make/N=(1,cols+1) 'TrainInt_TonicY'
	endif
	if (WaveExists('AUCbaselineX')==0)
		Make/N=(1,cols+1) 'AUCbaselineX'
	endif
	if (WaveExists('AUCbaselineY')==0)
		Make/N=(1,cols+1) 'AUCbaselineY'
	endif
	if (WaveExists('TrainInt_PhasicAUC')==0)
		Make/N=(1,cols) 'TrainInt_PhasicAUC'
	endif
	if (WaveExists('TrainInt_PhasicAUCtotal')==0)
		Make/N=(cols) 'TrainInt_PhasicAUCtotal'
	endif
	
	
	
	if(WaveExists(root:WorkData:W_coef)==0)	//Make coefficient wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_coef
	endif
	if(WaveExists(root:WorkData:W_fitConstants)==0)	//Make fitConstants wave if it doesn't exist (prevents error during first run of Trains) -AdrianGR
		Make/D root:WorkData:W_fitConstants
	endif
	
	if(WaveExists(root:WorkData:w_tempAUC)==0)	//-AdrianGR
		Make/D/N=(1,cols) root:WorkData:w_tempAUC
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
	
	//-AdrianGR
	Wave w_resultsTrainAmp_fromX0 = root:Results:TrainAmp_fromX0
	Wave w_resultsTrainInt_TonicAUCtotal = root:Results:TrainInt_TonicAUCtotal
	Wave w_resultsTrainInt_TonicAUC = root:Results:TrainInt_TonicAUC
	Wave w_resultsTrainInt_TonicX = root:Results:TrainInt_TonicX
	Wave w_resultsTrainInt_TonicY = root:Results:TrainInt_TonicY
	Wave AUCbaselineX = root:Results:AUCbaselineX
	Wave AUCbaselineY = root:Results:AUCbaselineY
	Wave w_resultsTrainInt_PhasicAUC = root:Results:TrainInt_PhasicAUC
	Wave w_resultsTrainInt_PhasicAUCtotal = root:Results:TrainInt_PhasicAUCtotal
	Wave w_tempAUC = root:WorkData:w_tempAUC
	WaveStats/Q/R=(x0-0.05*1/gTrainfreq,x0) w_temp
	Variable preStimBaseline0 = V_avg
	
	Wave w_
	
	n=DimSize(w_resultsSync,0)+1
	Redimension/N=(n,-1) w_resultsSync, w_resultsAll, w_resultsDel, w_resultsCorr
	Redimension/N=(n) w_resultsExp, w_resultsPro
	Redimension/N=(n) w_resultsTrainInt_TonicAUCtotal //-AdrianGR
	Redimension/N=(n,-1) w_resultsTrainAmp_fromX0, w_resultsTrainInt_TonicAUC, w_resultsTrainInt_TonicX, w_resultsTrainInt_TonicY, AUCbaselineX, AUCbaselineY, w_resultsTrainInt_PhasicAUC, w_resultsTrainInt_PhasicAUCtotal
	Redimension/N=(n,-1) w_tempAUC
	
	BlankArtifactInTrain(w_temp,x0,x1,gTrainfreq,gTrainStim)
	n -= 1
	j=0
	
	SetDataFolder root:WorkData:
	
	WaveStats/Q/M=1/R=[numpnts(w_temp)-2001,numpnts(w_temp)-1] w_temp
	post_pulse_baseline = V_avg
	print "post_pulse_baseline =	", post_pulse_baseline
	
	WaveStats/Q/M=1/R=(x0-0.001,x0) w_temp
	Init_baseline = V_avg
	print "Init_baseline =	", Init_baseline
	
	
	DeleteAnnotations/W=Experiments/A //Deletes any previous tags (or other annotations) on the graph -AdrianGR
	
	Make/O/D/N=(2) w_idkY
	Make/O/D/N=(2) w_idkX
	
	do
		if (j>0)
			x0+=1/gTrainfreq
			//Cursor A $gTheWave x0
			x1+=1/gTrainfreq
			//Cursor B $gTheWave x1
		endif
		
		
		WaveStats/Q/M=1/R=(x1,x0+(j+1)/gTrainfreq) w_temp
		vmin_cache = V_minLoc
		Init_amp = V_min - Init_baseline
		w_resultsAll[n][j] = Init_Amp				//Save full amplitude to zero
		w_resultsDel[n][j] = V_minLoc - x0		//Save delay from start of artefact to peak 
		//wavestats/Q/M=1/R=(x0,x1) w_temp
		//baseline=V_min
		WaveStats/Q/M=1/R=(x0-0.001,x0) w_temp
		baseline = V_avg
		amp = Init_amp - baseline						//Save evoked amplitude (to last sustained level).
		w_resultsSync[n][j] = (amp)
		
		
		//-AdrianGR //TODO: something wrong here? AUC doesn't seem to stay consistent when running multiple times, see also later
		WaveStats/Q/R=(x0-0.05*(1/gTrainfreq),x0) w_temp		//Getting average from final 5% of previous pulse
		Variable preStimBaseline = V_avg
		WaveStats/Q/R=(x1,x1+1/gTrainfreq) w_temp
		w_resultsTrainAmp_fromX0[n][j] = V_min - preStimBaseline	//Amplitude from baseline as defined above
		w_resultsTrainInt_TonicX[n][j] = x0		//Saving X-coordinates for tonic release
		w_resultsTrainInt_TonicY[n][j] = w_temp(x0)	//Saving Y-coordinates for tonic release
		
		if (j>0) //TODO: something seems to be wrong in calculation of tonic AUC! Which then also changes the phasic since it is dependent on it -AdrianGR
			Duplicate/O w_temp, w_temp2
			w_temp2 = w_temp2 - preStimBaseline0
			Variable phasic = area(w_temp2, x1-1/gTrainfreq, x0)
			//w_resultsTrainInt_PhasicAUC[n][j-1] = phasic
			
			Make/O/D/N=(2) w_tempX
			w_tempX[0] = x1-1/gTrainfreq
			w_tempX[1] = x0 //w_resultsTrainInt_TonicX[n][j]
			Make/O/D/N=(2) w_tempY
			w_tempY[0] = interp(x1-1/gTrainfreq, w_resultsTrainInt_TonicX, w_resultsTrainInt_TonicY)
			w_tempY[1] = w_resultsTrainInt_TonicY[n][j]
			w_tempY = w_tempY - preStimBaseline0
			print w_tempX
			print w_tempY
			Variable tonic = areaXY(w_tempX, w_tempY, w_tempX[0], w_tempX[1])
			w_resultsTrainInt_TonicAUC[n][j-1] = tonic
			
			Variable phasicMinusTonic = phasic - tonic
			w_resultsTrainInt_PhasicAUC[n][j-1] = phasicMinusTonic
			print "phasic: ", phasic, "tonic: ", tonic
			
		endif
		
		
		AUCbaselineX[n][j] = x0
		AUCbaselineY[n][j] = preStimBaseline0
		
		//print areaXY(tempw_resTrIntX, tempw_resTrIntY, x1, x0+1/gTrainfreq) //TODO: fix this. Find a way to get tonic release for each pulse (also minus baseline) -AdrianGR
		
		
			
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
			w_resultsCorr[n][j] = V_min-(W_coef[0]+W_coef[1]*exp(-((x1)-W_fitConstants[0])/W_coef[2])+W_coef[3]*exp(-((x1)-W_fitConstants[0])/W_coef[4])) //Save amplitude from second pulse on based the predicted decay of the first pulse
			
			print "w_resultsCorr[n][j]", w_resultsCorr[n][j]
			
			
			x2+=1/gTrainfreq
			
		else
	
			w_resultsCorr[n][j] = (amp)
			
		endif
		
		//Tag/L=2/W=Experiments/A=MB $fit_name, 100, "\\Z05\\ON" //-AdrianGR
		
		j += 1
	while (j <= gTrainStim)
	
	//TODO: something wrong here? AUC doesn't seem to stay consistent when running multiple times, see also earlier -AdrianGR
	Duplicate/O/RMD=[n][,*] w_resultsTrainInt_TonicAUC, w_tempAgain
	w_resultsTrainInt_TonicAUCtotal[n] = sum(w_tempAgain)
	print "Total tonic release AUC: ", w_resultsTrainInt_TonicAUCtotal[n]
	Duplicate/O/RMD=[n][,*] w_resultsTrainInt_PhasicAUC, w_tempAgainAgain
	w_resultsTrainInt_PhasicAUCtotal[n] = sum(w_tempAgainAgain)
	print "Total phasic release AUC: ", w_resultsTrainInt_PhasicAUCtotal[n]
	
	//Make/O/N=(2) AUCbaselineX
	//AUCbaselineX[0] = w_resultsTrainInt_TonicX[n][0]; AUCbaselineX[0] = w_resultsTrainInt_TonicX[n][INF]
	//Make/O/N=(2) AUCbaselineY
	//AUCbaselineY = preStimBaseline0
	AUCbaselineX[n][INF] = w_resultsTrainInt_TonicX[n][INF]
	AUCbaselineY[n][INF] = preStimBaseline0//*-100
	Duplicate/O/RMD=[n][,*] AUCbaselineX, AUCbaselineX2
	Duplicate/O/RMD=[n][,*] AUCbaselineY, AUCbaselineY2
	AppendToGraph/W=Experiments/C=(0,55555,55555) AUCbaselineY2 vs AUCbaselineX2 //TODO: why does this not show up correctly the graph???? -AdrianGR
	
	//Saving tonic release AUC results. A bit messy, but it works (I think) -AdrianGR
	//Duplicate/O/RMD=[n][,*] w_resultsTrainInt_TonicX, tempw_resTrIntX
	//Duplicate/O/RMD=[n][,*] w_resultsTrainInt_TonicY, tempw_resTrIntY
	//tempw_resTrIntY = tempw_resTrIntY - preStimBaseline0
	//Variable TonicAUC = areaXY(tempw_resTrIntX, tempw_resTrIntY)
	//w_resultsTrainInt_TonicAUCtotal[n] = TonicAUC
	//print "Tonic release AUC: ", TonicAUC
	
	AppendToGraph/W=Experiments/C=(0,0,55555) w_resultsTrainInt_TonicY[n][,*] vs w_resultsTrainInt_TonicX[n][,*] //-AdrianGR
	
	
	print n
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


Function BlankArtifactInTrain(w,x0,x1,freq,num_stim)
	wave w
	variable x0,x1 //x-coordinates of first artifact
	variable freq,num_stim
	variable i, AverageT=0.001, TempAverage
	
	i=0
	do
		TempAverage = mean(w, x0+i/freq-AverageT,pnt2x(w,x2pnt(w,x0+i/freq)-1)) 	//Added by Jakob to average over 1 ms
//		w[x2pnt(w,x0+i/freq),x2pnt(w,0.000025*i+x1+i/freq)]=w[x2pnt(w,x0+i/freq)-1]
		w[x2pnt(w,x0+i/freq),x2pnt(w,0.000025*i+x1+i/freq)]=TempAverage
		i += 1
	while (i<num_stim)
End

Function BlankArtifactInTrain2(w,x0,x1,freq,num_stim)
	wave w
	variable x0,x1 //x-coordinates of first artifact 
	variable freq,num_stim
	variable i, y0, y1
	string asyncdestwavename
	SVAR gTheWave=root:Globals:gTheWave
	
	i=0
	asyncdestwavename=gTheWave+"_async"
	wave/Z wavex=root:WorkData:$asyncdestwavename
	wavex=NaN
	Make/D/N=4/O W_coef
		do
		w[x2pnt(w,x0+i/freq),x2pnt(w,0.000025*i+x1+i/freq)]=w[x2pnt(w,x0+i/freq)-1]
		wavex[x2pnt(wavex,x0+i/freq),x2pnt(wavex,0.000025*i+x1+i/freq)]=w[x2pnt(w,x0+i/freq)-1]
		i += 1
	while (i<num_stim)
//	interpolate2 wavex
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
	End
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
Function getStringFreq(inString)
	String inString
	String regExPattern = "([0-9]{1,3})(.?)([Hh]z)" //Matches e.g. "20Hz", "20 Hz", "200_hz" etc.
	String outFreq = ""
	
	SplitString/E=regExPattern inString, outFreq
	if(V_flag==3)
		print("Extracted frequency is: "+outFreq+" Hz")
		return str2num(outFreq)
	else
		print("Could not extract frequency, defaulted to 50 Hz")
		return 50
	endif
End

// Set gTrainFreq and gRecFreq based on extracted frequency from getStringFreq -AdrianGR
Function update_Freq(String inWaveStr)
	NVAR gTrainFreq = root:Globals:gTrainFreq
	NVAR gRecFreq = root:Globals:gRecFreq
	gTrainFreq = getStringFreq(inWaveStr)
	gRecFreq = getStringFreq(inWaveStr)
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


