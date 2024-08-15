// ***Version history in JBS lab***
// INFO_Loader_(23032024).ipf --> INFO_Loader_(12072024)_fork1.ipf
// - Substantial modifications done by AdrianGR during July 2024
//
//


#pragma rtGlobals=1	// Use modern global access method.
#include <Execute Cmd On List>

// These routines are based on the 'NeurIgnacio' procedures.


Menu "HEKA Loader"
	"Browse Experiments", Panel_NeurignacioBrowser()
	"Load INFO", Neurignacio_Panel()
End

function Initialize_Variables()
	SVAR S_wavenames=root:Data:S_wavenames
	WAVE/Z group,type
	String/G protocol_wave, group_items,list_experiments="",loaded_experiments=""
	String/G protocol_list,group_list,type_list, culture_list
	String/G resultswave_list="none;"
	String/G tracename=""
	Make/O/T/N=0 protocolwave,groupwave,typewave,experimentwave, culturewave
	Make/O/N=0 protocolsw,groupsw,typesw,experimentsw, culturesw
	NewDataFolder/O root:Results
	
	
	//String temp_list=""
	//temp_list=Removefromlist("name",S_wavenames)
	//protocol_list=temp_list
	//temp_list=Removefromlist("group",S_wavenames)
	//protocol_list=temp_list
	//temp_list=Removefromlist("type",S_wavenames)
	//protocol_list=temp_list
	
	String removeThese = "name;group;type;suffix;folder"
	protocol_list=RemoveFromList(removeThese, S_wavenames, ";")
	//protocol_list=RemoveFromList("group",S_wavenames)
	//protocol_list=RemoveFromList("type",S_wavenames)
	
	group_list=EnumerateItemsfromWave(root:Data:group)
	type_list=EnumerateItemsfromWave(root:Data:type)
	culture_list=EnumerateItemsfromWave(root:Data:folder)
	listtowave(protocol_list,protocolwave)
	listtowave(group_list,groupwave)
	listtowave(type_list,typewave)
	listtowave(culture_list, culturewave)
	
	Redimension/N=(numpnts(protocolwave)) protocolsw
	Redimension/N=(numpnts(groupwave)) groupsw
	Redimension/N=(numpnts(typewave)) typesw
	Redimension/N=(numpnts(culturewave)) culturesw
	
	protocolsw=32
	groupsw=32
	typesw=32
	culturesw=32
end

// -------------- PANELS AND WINDOWS ---------------------------------------

Window Neurignacio_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(320,57,900,760)
	ModifyPanel cbRGB=(56576,56576,56576)
	SetDrawLayer UserBack
	SetDrawEnv fname= "Helvetica",fsize= 25,fstyle= 2,textxjust= 1,textyjust= 1
	DrawText 280,21,"Neuroloader "
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 278,41,"Release 20.03.2024"
	Button LoadINFO,pos={10.00,67.00},size={100.00,20.00},proc=ButtonProc_LoadINFO,title="Load INFO"
EndMacro

function Accessories()
	string/G path
	SVAR S_path=root:Data:S_path, S_filename=root:data:S_filename

	//	DrawPICT 5,112,1,1,PICT_2
	SetDrawEnv fname= "Arial",fsize= 18,fstyle= 1,textxjust= 1//,textyjust= 1
	DrawText 85,135,"Protocols"
	SetDrawEnv fname= "Arial",fsize= 18,fstyle= 1,textxjust= 1//,textyjust= 1
	DrawText 210,135,"Groups"
	SetDrawEnv fname= "Arial",fsize= 18,fstyle= 1,textxjust= 1//,textyjust= 1
	DrawText 320,135,"\"Culture\""
	//	SetDrawEnv fname= "Bradley Hand ITC",fsize= 18,fstyle= 1,textxjust= 1,textyjust= 1	
	//	DrawText 139,351,"Type"
	SetDrawEnv fname= "Arial",fsize= 18,fstyle= 1,textxjust= 1//,textyjust= 1
	DrawText 460,135,"Experiments"

	path=S_path+S_filename
	SetVariable setvar_file,pos={4,87},size={552,15},title=" ",font="Courier New"
	SetVariable setvar_file,fSize=9,fStyle=1,value= path,noedit= 1
	ListBox protocolbox,pos={10,140},size={150,450},frame=2
	ListBox protocolbox,listWave=root:protocolwave,selWave=root:protocolsw,mode= 4
	ListBox groupsbox,pos={165,140},size={90,220},frame=2,listWave=root:groupwave
	ListBox groupsbox,selWave=root:groupsw,mode= 4
	ListBox typebox,pos={165,390},size={90,90},frame=2,listWave=root:typewave
	ListBox typebox,selWave=root:typesw,mode= 4
	ListBox folderbox,pos={260,140},size={120,340},frame=2
	ListBox folderbox,listWave=root:culturewave,selWave=root:culturesw
	ListBox folderbox,mode=4,fsize=10,widths={1000}
	ListBox experimentbox,pos={385,140},size={150,450},listWave=root:experimentwave
	ListBox experimentbox,selWave=root:experimentsw,row= 1,mode= 4

	Button button_Update,pos={385,620},size={60,50},proc=UpdateButtonProc,title="Update",fColor=(3341,33153,54484)
	//Button button_SelectAllExp,pos={167,590},size={100,20},proc=ButtonProc_SelAllExperiments,title="Select All"
	//Button button_SelNoneExp,pos={272,590},size={101,20},proc=ButtonProc_SelNoneExperiments,title="Select None"
	Button button_ResetListBoxes,pos={240,660},size={60,20},proc=ButtonProc_ResetListBoxes,title="RESET!",fColor=(49087,6939,6939)
	Button button_LoadExperiments,pos={220,580},size={100,40},proc=LoadExperiments,title="Load Selected",fColor=(3341,54484,10023),fStyle=1
	Button button_DisplayExp,pos={220,625},size={100,25},proc=Button_DisplayExp,title="Start Display",fColor=(36751,46260,55769)
	
	Button button_SelAllProtocols,pos={10,595},size={150,20},proc=ButtonProc_SelAllGeneric,title="Select all/none"
	Button button_SelAllGroups,pos={165,365},size={90,20},proc=ButtonProc_SelAllGeneric,title="Select all/none"
	Button button_SelAllTypes,pos={165,485},size={90,20},proc=ButtonProc_SelAllGeneric,title="Select all/none"
	Button button_SelAllFolders,pos={260,485},size={120,20},proc=ButtonProc_SelAllGeneric,title="Select all/none"
	Button button_SelAllExperiments,pos={385,595},size={150,20},proc=ButtonProc_SelAllGeneric,title="Select all/none"
	Button button_SelAllPGTF,pos={220,510},size={100,45},proc=ButtonProc_SelAllGeneric,fsize=10,title="Select all/none \n(protocols, groups,\ntypes, cultures)"
	
	GroupBox group_LoadingButtons,pos={216,576},size={110,110}
	
	//	PopupMenu popup0,pos={180,630},size={150,20},proc= VersionPopup,title="Data Format"
	//	PopupMenu popup0,mode=1,popColor= (0,65535,65535),value="Pulse;PatchMaster"
	//	Button button_AverageSelected,pos={262,432},size={100,20},proc=ButtonProc_AverageSelected,title="Average Selected"
	//	GroupBox groupbox_Procedures,pos={15,449},size={523,92},title="Analysis Procedures"
	//	GroupBox groupbox_Procedures,labelBack=(26112,26112,0),font="Bradley Hand ITC"
	//	GroupBox groupbox_Procedures,fSize=18,fStyle=1,fColor=(65024,39424,5120)
	//	CheckBox check_Review,pos={42,482},size={100,14},title="Review Episodes"
	//	CheckBox check_Review,value= 0
	//	CheckBox check_BlankArtifact,pos={149,482},size={81,14},title="Blank Artifact"
	//	CheckBox check_BlankArtifact,value= 0,mode=1
	//	CheckBox check_Baseline,pos={246,482},size={58,14},title="Baseline"
	//	CheckBox check_Baseline,value= 0,mode=1
	//	CheckBox check_TwoRegion,pos={315,482},size={119,14},title="Two Region Baseline"
	//	CheckBox check_TwoRegion,value= 0,mode=1
	//	CheckBox check_Amplitude,pos={38,511},size={108,14},title="Measure Amplitude"
	//	CheckBox check_Amplitude,value= 0,mode=1
	//	CheckBox check_Area,pos={159,511},size={84,14},title="Measure Area"
	//	CheckBox check_Area,value= 0,mode=1
	//	CheckBox check_SynAsyn,pos={253,511},size={154,14},title="Calculate Syn&Asyn Release"
	//	CheckBox check_SynAsyn,value= 0,mode=1
	//	CheckBox check_Minis,pos={413,511},size={46,14},title="MINIs",value= 0,mode=1
end

Function VersionPopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr			// contents of current popup item as string
	popNum=0
	popStr="Pulse;PatchMaster"
End


Window Panel_NeurignacioBrowser() : Panel

	ButtonProc_Folder("null")
	string/G exp_group="A"
	string/G exp_name=""
	string/G gVersion
	
	if (cmpstr(gVersion,"Pulse")==0)
		string/G first_file="Pulse_1_1_001"
	else
		string/G first_file="PatchMaster_1_1_001_1_I-mon"
	endif
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(10,54,1000,804) as "PULSE Browser"
	SetDrawLayer UserBack
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 110,94,"Group"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 110,142,"Serie"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 84,47,"Filename"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 216,205,"Protocol"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 495,310,"Sweep"
	DrawText 22,240,"Type:"
	Button button_folder,pos={1.00,2.00},size={50.00,20.00},proc=ButtonProc_Folder,title="Folder"
	Button button_folder,help={"Load folder containing \".dat\" experiment files"}
	TitleBox title_folder,pos={52.00,2.00},size={703.00,23.00}
	TitleBox title_folder,help={"Current working folder"},fStyle=1
	TitleBox title_folder,variable= folderstr
	ValDisplay valdisp_NumDATfiles,pos={148.00,40.00},size={40.00,17.00},bodyWidth=25,title="of"
	ValDisplay valdisp_NumDATfiles,help={"Total Number of Files in folder"},frame=0
	ValDisplay valdisp_NumDATfiles,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_NumDATfiles,value= #"ItemsInlist(DATfiles)"
	ValDisplay valdisp_IndexDAT,pos={115.00,40.00},size={25.00,17.00},bodyWidth=25
	ValDisplay valdisp_IndexDAT,help={"Current number of file"},frame=0
	ValDisplay valdisp_IndexDAT,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_IndexDAT,value= #"index_Dat+1"
	SetVariable setvar_protocolstr,pos={181.00,215.00},size={60.00,18.00},bodyWidth=80,fsize=10,title=" "
	SetVariable setvar_protocolstr,help={"Name of the protocol (editable)"}
	SetVariable setvar_protocolstr,value=protocolstr
	SetVariable setvar_SweepTot,pos={489.00,332.00},size={43.00,18.00},bodyWidth=25,title="of "
	SetVariable setvar_SweepTot,help={"Total Number of Sweeps"},frame=0
	SetVariable setvar_SweepTot,limits={-inf,inf,0},value= SweepTot,noedit= 1
	SetVariable setvar_SweepCurrent,pos={462.00,332.00},size={25.00,18.00},bodyWidth=25,title=" "
	SetVariable setvar_SweepCurrent,help={"Current Sweep"},frame=0
	SetVariable setvar_SweepCurrent,limits={-inf,inf,0},value= SweepCurrent,noedit= 1
	Button button_GroupNext,pos={152.00,102.00},size={23.00,23.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01->"
	Button button_GroupNext,help={"Next Group"}
	Button button_GroupPrevious,pos={40.00,102.00},size={23.00,23.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01<-"
	Button button_GroupPrevious,help={"Previous group"}
	Button button_SerieNext,pos={152.00,149.00},size={23.00,23.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01->"
	Button button_SerieNext,help={"Next Serie"}
	Button button_SeriePrevious,pos={40.00,149.00},size={23.00,23.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01<-"
	Button button_SeriePrevious,help={"Previous Serie"}
	Button button_SweepNext,pos={520.00,329.00},size={20.00,20.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01->"
	Button button_SweepNext,help={"Next Sweep"}
	Button button_SweepPrevious,pos={432.00,329.00},size={20.00,20.00},proc=ButtonProc_TreeArrows,title="\\JC\\f01<-"
	Button button_SweepPrevious,help={"Previous Sweep"}
	Button button_Add,pos={190.00,110.00},size={50.00,50.00},proc=ButtonProc_AddExperiment,title="Add"
	Button button_Add,help={"Add displayed Serie to the table"},fStyle=1
	Button button_Add,fColor=(16384,28160,65280)
	PopupMenu popup_Group,pos={65.00,102.00},size={86.00,19.00},bodyWidth=86
	PopupMenu popup_Group,help={"Current Group"}
	PopupMenu popup_Group,mode=1,popvalue="1 of NaN",value= #"GroupPopList"
	PopupMenu popup_Series,pos={65.00,149.00},size={86.00,19.00},bodyWidth=86,proc=PopMenuProc_TreePopUp
	PopupMenu popup_Series,help={"Current Serie"}
	PopupMenu popup_Series,mode=1,popvalue="1 of NaN",value= #"SeriePopList"
	TitleBox popup_FileName,pos={45.00,57.00},size={89.00,23.00},proc=PopMenuProc_FileName
	TitleBox popup_FileName,help={"Current Experiment File"},frame=5,fStyle=1
	TitleBox popup_FileName,variable= DATfilename
	Button button_FilePrevious,pos={16.00,57.00},size={23.00,23.00},proc=ButtonProc_FileArrows,title="\\JC\\f01<-"
	Button button_FilePrevious,help={"Previous experiment file"}
	Button button_FileNext,pos={221.00,57.00},size={23.00,23.00},proc=ButtonProc_FileArrows,title="\\JC\\f01->"
	Button button_FileNext,help={"Next experiment file"}
	Button button_ZoomOut,pos={636.00,312.00},size={61.00,37.00},proc=ButtonProc_ZoomOUT,title="Autoscale"
	Button button_ZoomOut,help={"Autoscale Zoom"}
	Button button_AllSweeps,pos={556.00,329.00},size={65.00,20.00},proc=ButtonProc_TreeArrows,title="Show All"
	Button button_AllSweeps,help={"Display all the Sweeps"}
	PopupMenu popup_type,pos={74.00,220.00},size={76.00,19.00},bodyWidth=70,proc=PopMenuProc_Type,title=" "
	PopupMenu popup_type,help={"Current type of neuron"}
	PopupMenu popup_type,mode=1,popvalue="EPSC",value= #"\"EPSC;IPSC;?\""
	PopupMenu popup_ExpGroup,pos={71.00,195.00},size={79.00,19.00},bodyWidth=79
	PopupMenu popup_ExpGroup,help={"Current Experimental Condition"}
	PopupMenu popup_ExpGroup,mode=1,popvalue="A",value= #"Exp_Group"
	Button button_AddExpGroup,pos={12.00,196.00},size={50.00,23.00},proc=ButtonProc_ExpGroup,title="Group"
	Button button_AddExpGroup,help={"New experimental condition will be created"}
	TitleBox title_Note,pos={7.00,248.00},size={178.00,488.00}
	TitleBox title_Note,help={"Information from the experiment"}
	TitleBox title_Note,labelBack=(65280,65280,48896),fSize=10,fStyle=0
	TitleBox title_Note,variable= notestr
	GroupBox group_BrowseCommands,pos={7.00,31.00},size={251.00,154.00}
	GroupBox group_DisplayCommands,pos={425.00,302.00},size={277.00,56.00}
	GroupBox group_TableCommands,pos={7.00,190.00},size={252.00,58.00}
	Display/W=(264,31,1270,248)/HOST=#  $first_file 
	RenameWindow #,BrowseGraph
	SetActiveSubwindow ##
	
	CheckBox chk_ProtocolstrCleanup1,pos={432,400},size={20,20},title="Use cleaned protocol name as per Adrian rules?"
	CheckBox chk_ProtocolstrCleanup1, proc=proc_chk_Protocolstr
	String/G replaceSubStr2 = ""
	String/G replaceSubStr2with = ""
	CheckBox chk_ProtocolstrCleanup2,pos={432,420},size={20,20},title="Do replacement?"
	CheckBox chk_ProtocolstrCleanup2, proc=proc_chk_Protocolstr
	SetVariable setvar_replaceSubStr2,pos={432,440},size={60,20},bodyWidth=80,fsize=10,title="Replace this"
	SetVariable setvar_replaceSubStr2,help={"Remove all instances of this substring..."}
	SetVariable setvar_replaceSubStr2,value=replaceSubStr2
	SetVariable setvar_replaceSubStr2with,pos={432,460},size={60,20},bodyWidth=80,fsize=10,title="with this"
	SetVariable setvar_replaceSubStr2with,help={"...and replace with this"}
	SetVariable setvar_replaceSubStr2with,value=replaceSubStr2with
	//SetVariable setvar_replaceSubStr2preview,pos={432,470},size={60,20},bodyWidth=80,fsize=10,title="preview:"
	//SetVariable setvar_replaceSubStr2preview,help={"Preview"}
	//SetVariable setvar_replaceSubStr2preview,value=protocolstr,disable=2,live=1

	
	//CheckBox chk_SelAllSweeps,pos={432.00,360.00},size={20.00,20.00},title="Select all sweeps?"
	//CheckBox chk_SelAllSweeps,help={"If checked, all sweeps in current serie will be added"}
	
	ControlUpdate popup_Group //These two make sure that the popups are updated after file has been loaded -AdrianGR
	ControlUpdate popup_Series
EndMacro

// ------------------------------- FUNCTIONS ---------------------------------


//ButtonProc_SelAll("button_SelAll")
// Initial Values for High Train Analysis
//	TabProc_AnalysisTools("Tab_AnalysisTools",0)
//	Cursor/C=(65535,0,0)/H=1/S=1/L=1 A,$namewave,0.0005
//	Cursor/C=(65535,33232,0)/H=1/S=1/L=1 B,$namewave,0.0015
//	SetAxis bottom 0.00,0.002
//	AppendToGraph sucroseinterval
//End


function ListToWave(listin, namewave)
	string listin
	wave/T namewave
	variable num_items
	variable i=0
	
	num_items=ItemsInList(listin)
	Redimension/N=(num_items) namewave
	
	do
		if (cmpstr(listin,"")==0)
			Abort ("List contains no items")
		else
			namewave[i]=StringfromList(i,listin)
		endif
		i += 1
	while (i<=num_items-1)
end

function/S EnumerateItems(listin)
	string listin
	string listout
	string item
	variable num_items, i=0
	
	listout=""
	
	do
		item=StringfromList(0,listin)
		listin=RemovefromLIst(item,listin)
		listout += item+";"
	while (strlen(item)!=0)
	return listout
end

function/S EnumerateItemsfromWave(wavein)
	wave/T wavein
	string listout
	variable n,i=0
	
	n=numpnts(wavein)
	listout=""
	do
		if (strsearch(listout,wavein(i),0)<0)
			if (cmpstr(wavein(i),"")>0)	//Added if-statement to prevent population of listout with empty values -AdrianGR
				listout += wavein(i) + ";"
			endif
		endif
		i += 1
	while (i<=n)
	return listout
end

function CreateGroupWave(wavein)
	wave/T wavein
	WAVE/T group
	variable i=0
	
	do
		if (strsearch(wavein(i),"S25b",0)>=0)
			group[i]="S25b"
		endif
		if (strsearch(wavein(i),"WT",0)>=0)
			group[i]="WT"
		endif
		if (strsearch(wavein(i),"GFP",0)>=0)
			group[i]="GFP"
		endif
		i += 1
	while (i<=111)
end

proc SelectExperiments()
	string listout
	string groupcriteria, typecriteria, culturecriteria, protocolcriteria
	variable match,i,j,n,n_protocol=0
	string item, strtemp, protocolwave_ref
	
	Setdatafolder root:
	listout=""
	// Create list of items selected from 'group'
	groupcriteria=""
	n=numpnts(groupsw)
	i=0
	do
		if (groupsw[i]>=48)
			groupcriteria += groupwave[i]+";"
		endif
		i+=1
	while (i<=n-1)
	
	// Create list of items selected from 'type'
	typecriteria=""
	n=numpnts(typesw)
	i=0
	do
		if (typesw[i]>=48)
			typecriteria += typewave[i]+";"
		endif
		i+=1
	while (i<=n-1)
	
	// Create list of items selected from 'Culture'
	culturecriteria=""
	n=numpnts(culturesw)
	i=0
	do
		if (culturesw[i]>=48)
			culturecriteria += culturewave[i]+";"
		endif
		i +=1
	while (i<=n-1)
	
	// Create list of items selected from 'protocol'
	protocolcriteria=""
	n=numpnts(protocolsw)
	i=0
	do
		if (protocolsw[i]>=48)
			protocolcriteria += protocolwave[i]+";"
			protocolwave_ref=protocolwave[i]
			print protocolcriteria
		endif
		i +=1
	while (i<=n-1)
	n_protocol=ItemsInList(protocolcriteria)
	
	SetDataFolder root:Data
	string/G protocolname_list=""
	n=numpnts(name)
	//Check if experiment matches with criteria
	i=0
	do
		if ((strsearch(groupcriteria,group[i],0)>=0) && (strsearch(typecriteria,type[i],0)>=0) && strsearch(culturecriteria, folder[i],0)>=0))
			match=1
		else
			match=0
		endif
		print i
		if (match==1) //name(i) matched grop and type
			j=0
			do
				item=StringFromList(j,protocolcriteria)
				strtemp=$item(i)
				if (cmpstr(strtemp,"")!=0)
					//listout += name[i]+suffix[i] + ";"
					listout += name[i]+suffix[i]+" series= "+strtemp
					protocolname_list+=item+";"
					print "item=",item
					print "listout=",listout
				endif
				j+=1
			while (j<=n_protocol-1)
		endif
		i +=1
	while (i<=n-1)
	SetDataFolder root:
	if (strlen(listout)<=0)
		experimentwave[]="" //This just throws an error, so I disabled it -AdrianGR
		Abort "No Experiments were found.\rPossibly no experiment satisfies criteria."
	else
		ListTowave(listout,experimentwave)
	endif
end

proc CalcRGB(red,blue,green)
	variable red,blue,green
	printf "%g,%g,%g",red*65535/255,blue*65535/255,green*65535/255 
end

////////////////////////////////////////////////////
// Just testing some things -AdrianGR

Function [variable R, variable G, variable B] RGBconv_sub (variable red, variable blue, variable green)
	//variable red,blue,green
	variable cFactor = 65535/255
	//cFactor = 65535/255
	return [red*cFactor, blue*cFactor, green*cFactor]
end

Function callRGB()
	variable red_out, green_out, blue_out
	[red_out, green_out, blue_out] = RGBconv_sub(122, 201, 2)
	print red_out, green_out, blue_out
End
////////////////////////////////////////////////////

Function UpdateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	variable n
	wave experimentwave, experimentsw
	
	execute "Selectexperiments()"
	n=numpnts(experimentwave)
	//Redimension/N=0 experimentsw
	Redimension/N=(n) experimentsw
	experimentsw=32
	listbox experimentbox listwave=experimentwave,selwave=experimentsw,mode=4
End

function FindStringValue(str,w)
	string str
	wave/T w
	variable i,n
	variable p=-1
	
	n=numpnts(w)-1
	i=0
	do
		if (cmpstr(str,ReplaceString("¯",w[i],"O"))==0)
			p=i
			break
		endif
		i +=1
	while (i<=n)
	return p
end

function/S get_nametemp(nametemp)
	string nametemp
	string v1
	
	sscanf nametemp,"%s",v1
	
	return v1
end

function get_seriesnum(nmetemp)
	string nmetemp
	
	string skip
	variable s
	sscanf nmetemp,"%s%*[ series= ]%d", skip, s
	return s
end

proc LoadExperiments(ctrlName) : ButtonControl
	String ctrlName
	
	string protocolcriteria, item, protocoltemp
	string pre_nametemp, nametemp, filenametemp, strtemp, wavenumtemp
	variable groupnum, seriesnum=1, wavenum
	variable n_exp,delta_n_exp,more,i,ii,j,n,n_protocol=0
	string pathname // Name of the path
	string loaded_experiments
	variable s, time0
	
	string gVersion_infoloader=root:Data:gVersion_infoloader

	killdatafolder/Z root:OrigData
	NewDataFolder/O root:OrigData
	SetDataFolder root:
	time0=datetime
	pathname=root:Data:S_path
	groupnum=1 //Only 1st group are considered
	
	// Create list of items selected from 'protocol'
	protocolcriteria=""
	n=numpnts(protocolsw)
	i=0
	do
		if (protocolsw[i]>=48)
			protocolcriteria += protocolwave[i]+";"
		endif
		i +=1
	while (i<=n-1)
	n_protocol=ItemsInList(protocolcriteria)
	
	print "protocolcriteria=",protocolcriteria
	print "n_protocol=",n_protocol
	
	n=numpnts(experimentwave)
	i=0
	delta_n_exp=0
	do
		if (experimentsw[i]>=48)
			pre_nametemp=experimentwave[i]

			SetDataFolder root:Data
			
			nametemp=get_nametemp(pre_nametemp)
			seriesnum=get_seriesnum(pre_nametemp)
			
			item=StringFromList(i,root:Data:protocolname_list)
			
			print "item=",item
				
				
			protocoltemp=$item(n_exp+delta_n_exp)
				
						if (seriesnum!=0)
							print "pathname=",pathname
							filenametemp=pathname+nametemp+".dat"	//":"
							filenametemp=replacestring(":",filenametemp,"\\"+"\\") //necessary in using bpc_ReadHeka, because it is windows only
							filenametemp=filenametemp[0]+":"+filenametemp[1,INF]
							
							print "suffix=",suffix[n_exp]
							
							nametemp=nametemp+suffix[n_exp]
							SetDataFolder root:OrigData
							
							print "nametemp=",nametemp
							print "filenametemp=",filenametemp
							
							wavenumtemp=num2str(wavenum)
							
							print "wavenumtemp=",wavenumtemp
							
							ControlInfo popup0

							if (cmpstr(gVersion_infoloader,"Pulse")==0)
							bpc_LoadPulse/A=(groupnum)/B=(seriesnum)/C=1/N=("x"+wavenumtemp+item)/O filenametemp
							endif
							
							if (cmpstr(gVersion_infoloader,"PatchMaster")==0)
							bpc_LoadPM/A=(groupnum)/B=(seriesnum)/N=("x"+wavenumtemp+item)/O filenametemp
							endif
					

							loaded_experiments += "x"+wavenumtemp+item+";"
							wavenum += 1

							SetDataFolder root:Data
						endif
			SetDataFolder root:
			List_Experiments += nametemp+";"//AddListItem(List_Experiments,nametemp) //+"@"+item+"_"+num2str(groupnum)+"_"+num2str(seriesnum)) //Generate a list of experiments loaded
		endif
		i+=1
	while (i<n)
	//	list_experiments=removelistitem(0,list_Experiments) // Remove first empty "" item
	print "List_experiments =",  List_Experiments
	print ItemsInList(list_experiments),"experiments loaded in", datetime-time0, "secs"
	list_experiments=""
End


function ConttoEpis(w, namewave,freq,x_first)
	wave w
	string namewave
	variable freq,x_first
	variable p_first
	variable segmentlength, nSegments
	variable bp=50 //num points before stimulus
	
	p_first=x2pnt(w,x_first)
	segmentlength=x2pnt(w,1/freq)
	//nSegments=round((numpnts(w)-(p_first-bp)/segmentlength)
	duplicate w,waveforconttoepis
end

function EpisToCont(list, namewave)
	string list,namewave
	variable i,n,points, p0,p1
	string item
	
	n=ItemsInList(list)-1
	item=StringfromList(i,list)
	Duplicate/O $item,$namewave
	points=numpnts($namewave)
	wave w=$namewave
	i=1
	do
		item=StringfromList(i,list)
		wave w_item=$item
		p0=points
		points +=numpnts(w_item)
		Redimension/N=(points) w
		w[p0,points-1]=w_item[p-p0]
		DoUpdate
		i += 1
	while (i<=n)
end


function FindRoot(name, separator) //equivalent to strsearch
	string name, separator
	variable num_car,i
	
	num_car=strlen(name)
	i=num_car
	do
		i -=1
	while ((i>0) && cmpstr(name[i],separator)!=0)
	return i-1
end

function ReviewWavesInList(list)
	string list
	variable num_items,i,j
	string item, namewave
	string graphname
	
	num_items=ItemsInList(List)
	i=1
	do
		item=stringfromlist(i,list)
		graphname="graphtemp"+num2str(i)
		Dowindow/C $graphname
		display
		j=1
		do	
			namewave=item+"_"+num2str(j)
			if (waveexists($namewave)==0)
				break
			endif
			AppendtoGraph $namewave
			AutopositionWindow/E
			j +=1
		while (j>1)
		i +=1
	while (i<num_items)
	Make/O/N=(num_items) review_wave // Cointains if wave is selected or no (0)
	review_wave=1 // All are selected by default
end


Function DisplayWaveList(list)
	String list // A semicolon-separated list.
	String theWave
	Variable index=0
	variable pos
	string temp
	
	do
		// Get the next wave name
		theWave = StringFromList(index, list)
		pos=strsearch(theWave,"@",0)-1
		if (pos<0)
			pos=strlen(theWave)-1
		endif
		//	if (strsearch(theWave[0,pos],"_",0)-1>0)
		//		pos=strsearch(theWave[0,pos],"_",0)-1
		//	endif
		if (strlen(theWave) == 0)
			break // Ran out of waves
		endif
		if (index == 0) // Is this the first wave?
			Display/K=1/W=(2.25,38,954,425) $theWave
			//		temp="Dowindow/C "+ReplaceString("Ø",theWave[0,pos],"O") //Changes 'Ø' for a compatible graph name
			Dowindow/C theWave
			//		Execute temp
		else
			AppendToGraph $theWave
		endif

		index += 1
	while (1) // Loop until break above
End

Function RenameAllWaveNamesPPT(waveFolder)
	String waveFolder
	String objName, objNameNew
	Variable index = 0, wavecount, strStart=7, strEnd, strLength, flag=0, temp_pos1, temp_pos2  
  
	SetDataFolder root:$waveFolder
  
	wavecount = CountObjects("", 1)
	do
		objName = GetIndexedObjName("", 1, index)
		if (strlen(objName) == 0)
			break
		endif
		strLength = strlen(objName)
		strEnd = strLength - 1 //IGOR indexes strings starting from 0!
   
		flag=0  
		do
			if (cmpstr(objName[strEnd], "_")==0) //cmpstr returns 0 if strings are equal
				flag=1
			else
				strEnd-=1
			endif
		while((flag==0) && (strEnd>strStart))
   
		objNameNew = "pm"+objName[strStart, strEnd+1]
		temp_pos1 = Strsearch(objNameNew, "Leak", 0)
		temp_pos2 = temp_pos1
		do
			temp_pos2-=1
		while((temp_pos2>0) &&  (cmpstr(objNameNew[temp_pos2], "_")!=0))
		objNameNew = objNameNew[0,temp_pos2-1] + objNameNew[temp_pos1, strlen(objNameNew)-1]
		wave w = WaveRefIndexed("", index ,4)
		make/O $objNameNew=NaN
		wave waveOutput = $objNameNew
   
		Printf "Designated name for wave: %s\r", objNameNew
		duplicate/O w waveOutput
		//   MoveWave (blush)objNameNew,root: 
		index += 1
	while(index<wavecount)
	Print wavecount
	SetDataFolder root:
End

Function ButtonProc_SelAll(ctrlName) : ButtonControl
	String ctrlName
	wave review_wave
	NVAR tracenum
	variable i,nmax
	
	nmax=numpnts(review_wave)
	i=0
	do
		review_wave[i]=1
		ModifyGraph lstyle[i]=0, rgb[i]=(1,65535,33232), lsize[i]=1 //blue-green
		i +=1
	while (i<=nmax-1)
	ModifyGraph/Z lstyle[tracenum]=0, rgb[tracenum]=(0,0,65535), lsize[tracenum]=3	//blue
	review_wave=1
	CheckBox check_selected value=1
End

Function ButtonProc_SelNone(ctrlName) : ButtonControl
	String ctrlName
	wave review_wave
	NVAR tracenum
	variable i,nmax

	nmax=numpnts(review_wave)
	i=0
	do
		review_wave[i]=1
		ModifyGraph lstyle[i]=0, rgb[i]=(51664,44236,58982), lsize[i]=1 //blue-green
		i +=1
	while (i<=nmax-1)
	ModifyGraph/Z lstyle[tracenum]=0, rgb[tracenum]=(13112,0,26214), lsize[tracenum]=3	//blue
	review_wave=0
	CheckBox check_selected value=0
End



Function ListBoxProc_listbox(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end

	string selwave
	
	if (event==4 || event==5)
		selwave=ctrlname[0,strsearch(ctrlname,"box",0)-1]+"sw"
		wave sw=$selwave
		sw[row]=sw[row] -1
	endif
	return 0
End

Function ButtonProc_SelAllExperiments(ctrlName) : ButtonControl
	String ctrlName
	wave experimentsw
	experimentsw[]=48
End

Function ButtonProc_SelNoneExperiments(ctrlName) : ButtonControl
	String ctrlName
	wave experimentsw
	experimentsw[]=32
End

// Selects all or none based on whether any already are selected -AdrianGR
Function ButtonProc_SelAllGeneric(ctrlName) : ButtonControl
	String ctrlName
	//wave protocolsw
	//wave groupsw
	//wave typesw
	//wave culturesw
	//wave experimentsw
	//wave checkThisWave
	Variable checkFlagEnable = 1
	Variable flagPGTF = 0
	
	strswitch(ctrlName)
		case "button_SelAllProtocols":
			wave checkThisWave = protocolsw
		break
		case "button_SelAllGroups":
			wave checkThisWave = groupsw
		break
		case "button_SelAllTypes":
			wave checkThisWave = typesw
		break
		case "button_SelAllFolders":
			wave checkThisWave = culturesw
		break
		case "button_SelAllExperiments":
			wave checkThisWave = experimentsw
		break
		case "button_SelAllPGTF":
			fSelAllPGTF()
			checkFlagEnable = 0
			//Concatenate/NP {protocolsw,groupsw,typesw,culturesw}, checkThisWave
			//if(howManySel(checkThisWave)>>0)
				//wave protocolsw[]=32
				//wave groupsw[]=32
				//wave typesw[]=32
				//wave culturesw[]=32
			//elseif(howManySel(checkThisWave)==0 && checkFlagEnable == 1)
				//wave protocolsw[]=48
				//wave groupsw[]=48
				//wave typesw[]=48
				//wave culturesw[]=48
			//endif
		break
	endswitch
	
	if(WaveExists(checkThisWave)!=0 && checkFlagEnable == 1)
		if(howManySel(checkThisWave)>>0)
			checkThisWave[]=32
			return 0
		elseif(howManySel(checkThisWave)==0 && checkFlagEnable == 1)
			checkThisWave[]=48
			return 1
		endif
	elseif(checkFlagEnable == 1)
		DoAlert 0, "Nothing to select! (Or something is wrong)"
	endif
	
End

// Returns how many items are selected -AdrianGR
Function howManySel(inWave)
	Wave inWave
	Variable i, selCount

	for (i=0; i<DimSize(inWave,0); i+=1)
		if(inWave[i]==48)
			selCount += 1
		endif
	endfor
	
	return selCount
End

// Helper function for selecting all or none -AdrianGR
Function fSelAllPGTF()
	wave protocolsw,groupsw,typesw,culturesw
	if(WaveExists(temp_comboWave)==1)
		KillWaves temp_comboWave
	endif
	wave temp_comboWave
	Concatenate/NP {protocolsw,groupsw,typesw,culturesw}, temp_comboWave
	
	if(howManySel(temp_comboWave)>>0)
		protocolsw=32
		groupsw=32
		typesw=32
		culturesw=32
	elseif(howManySel(temp_comboWave)==0)
		protocolsw=48
		groupsw=48
		typesw=48
		culturesw=48
	endif
	KillWaves temp_comboWave
End

//Function fSelAllPGTF_invert() // This function is just a convoluted way of making the selection inverse -AdrianGR
//	String pref = "button_SelAll"
//	String suff = "Protocols;Groups;Types;Folders"
//	Variable i=0
//	
//	for(i=0; i<ItemsInList(suff); i+=1)
//		ButtonProc_SelAllGeneric(pref+StringFromList(i,suff,";"))
//	endfor
//End

Function ButtonProc_ResetListBoxes(ctrlName) : ButtonControl
	String ctrlName
	wave protocolsw,groupsw,typesw, culturesw, experimentsw
	
	protocolsw=32
	groupsw=32
	typesw=32
	culturesw=32
	experimentsw=32
	
	string tablelist=WinList("*",";","WIN:2")
	string graphlist=WinList("*",";","WIN:1")
	string allwindows=tablelist+graphlist, window_name
	print allwindows
	variable i_loc2
	
	for (i_loc2=0; i_loc2<itemsinlist(allwindows); i_loc2+=1)
		window_name=stringfromlist(i_loc2,allwindows)
		killwindow/Z $window_name
	endfor

	killwindow/Z NeuroBunny
	
	killdatafolder/Z OrigData
	killdatafolder/Z Globals
	killdatafolder/Z Deconvolution

End


function FindExperiment(s) 
	String s //'s' is the name of a experiment wave
	variable more,i,n
	string oldDF
	
	oldDF=GetDataFolder(1)
	SetDataFolder root:Data
	s=ReplaceString("Ø", s, "O")
	wave name
	//	more = 0
	i=strsearch(s,"@",0)
	if (i<=0)
		i=strlen(s)
	endif
	//if (strsearch(s[0,i+1],"_",0)>0)
	//	i=strsearch(s[0,i+1],"_",0)
	//endif

	do
		i -= 1
		n=FindStringValue(s[0,i],name)
		//		if (cmpstr(s[i,i+1],"b@")==0) // correct 'b' ending
		//			more =1
		//		endif
		more=char2num(Upperstr(s[i+1]))-65
		if ((more<0) || (numtype(more)!=0) || (more>=25))
			more=0
		endif
	while (n<0 && i>=0)
	n += more
	SetDataFolder oldDF
	return n
end

Function ButtonProc_LoadINFO(ctrlName) : ButtonControl
	
	String ctrlName
	NewDataFolder/O/S root:Data
	Execute "LoadWave/J/W/O/K=2"
	//LoadWave/J/W/O/K=2
	//if(V_Flag==0)
		//abort
	//endif
	
	string version
	Prompt version, "Format:",popup "PatchMaster;Pulse"
	DoPrompt "Please specify Data format.", version
	string/G gVersion_infoloader=version
	
	SetDataFolder root:	
	Initialize_Variables()
	Accessories()
End


Function ButtonProc_Folder(ctrlName) : ButtonControl
	String ctrlName
	NewPath/O/Q/Z/M="Select Folder with HEKA experiment files" Path_Experiment
	if (V_Flag!=0)
		abort
	endif
	PathInfo Path_experiment
//	string/G folderstr=S_path
	
	string/G folderstr=replacestring(":",S_path,"\\"+"\\") //necessary in using bpc_ReadHeka, because it is windows only
	folderstr=folderstr[0]+":"+folderstr[1,INF]
	
	variable/G index_DAT=0
	string/G DATfiles=indexedfile(Path_experiment,-1,".dat") //List of the ".dat" files in folder
	string/G DATfilename=indexedfile(Path_experiment,index_DAT,".dat") //filename of the first ".dat" of the folder
	string version
	Prompt version, "Format:",popup "PatchMaster;Pulse"
	DoPrompt "Please specify Data format.", version
	string/G gVersion=version
	// Choose which amplifier
	if (cmpstr(gVersion,"PatchMaster")==0)
		string amplifier
		Prompt amplifier, "Format:",popup "EPC10;EPC9;EPC9(old)"
		DoPrompt "Please specify amplifier.", amplifier
		string/G gAmplifier=amplifier
	endif
	//
	
	variable/G GroupCurrent=1
	variable/G SeriesCurrent=1
	variable/G SweepCurrent=1
	
	RefreshFirstFile(DATfilename)
End

function/S fLoadPulse(groupnum, seriesnum, sweepnum, basename, filenamestr)
	variable groupnum, seriesnum, sweepnum
	string basename, filenamestr
	string cmd_str=""
	SVAR gVersion
	
	if (groupnum>0)
		cmd_str += "/A="+num2str(groupnum)
	endif
	if (seriesnum>0)
		cmd_str += "/B="+num2str(seriesnum)
	endif
	if (sweepnum>0)
		cmd_str +="/C="+num2str(sweepnum)
	endif
	
	//	ControlInfo popup0
	if (cmpstr(gVersion,"Pulse")==0)
//		Execute "bpc_LoadPulse/O"+cmd_str+"/N= \""+filenamestr+"\""
		Execute "bpc_LoadPulse/O"+cmd_str+"/N="+"\""+basename+"\"/W \""+filenamestr+"\""
		//SVAR first_file
		//first_file="Pulse_1_1_001"
		
	elseif (cmpstr(gVersion,"PatchMaster")==0)
//		Execute "bpc_LoadPM/O"+cmd_str+"/N= \""+filenamestr+"\""
		Execute "bpc_LoadPM/O"+cmd_str+"/N="+"\""+basename+"\"/W \""+filenamestr+"\""
		//SVAR first_file
		//first_file="PatchMaster_1_1_001_1_I1"
	endif
	
	
	
end

function GetPulseNote(w, basename) //w is a wave obtained by LoadPulse
	wave w
	string basename

	string/G notestr=note(w)
	//string/G vertical_notestr=replaceString(";",notestr,"\n")
	
	//print notestr
	variable n_lines=itemsinlist(notestr)-1
	Make/O/T/N=(n_lines+1,2) $(basename)
	wave/T w_note=$(basename)
	w_note=""
	variable i_line=0
	do
		string linestr=StringfromList(i_line,notestr)
		variable n_items=ItemsInList(linestr,":")-1
		w_note[i_line][0]=StringfromList(0,linestr,":")
		if (n_items>0)
			w_note[i_line][1]=Stringfromlist(n_items,linestr,":")
		endif
		i_line += 1
	while (i_line<=n_lines)
end

Function DisplayWaveListInHost(list, graphname, hostname)
	String list // A semicolon-separated list.
	string graphname, hostname
	string graphname2, newname
	String theWave, theWave2
	Variable index=0, double=0
	SVAR gVersion
	
	do
		if (cmpstr(gVersion,"Pulse")==0)
			// Get the next wave name
			theWave = StringFromList(index, list)
			if (strlen(theWave) == 0)
				break // Ran out of waves
			endif
			if (index == 0) // Is this the first wave?
				if (FindListItem(graphname,ChildWindowList(hostname))>=0)
					KillWindow $(hostname+"#"+graphname)
				endif
				Display/W=(264,31,1270,248)/HOST=$hostname/N=$graphname/K=1 $theWave
			else
				SetActiveSubWindow $(hostname+"#"+graphname)
				AppendToGraph $theWave
			endif
	
		elseif (cmpstr(gVersion,"PatchMaster")==0)
			// Get the next wave name
			theWave = StringFromList(index, list)
			if (strlen(theWave) == 0)
				break // Ran out of waves
			endif

						if (index == 0) // Is this the first wave?
							if (FindListItem(graphname,ChildWindowList(hostname))>=0)
								KillWindow $(hostname+"#"+graphname)
								// KillWindow $(hostname+"#"+graphname2)
							endif
			Display/W=(264,31,1270,248)/HOST=$hostname/N=$graphname/K=1 $theWave
			// Display/W=(264,280,1280,555)/HOST=$hostname/N=$graphname2/K=1/W=(2.25,253,954,425) $theWave2
						else
							SetActiveSubWindow $(hostname+"#"+graphname)
							AppendToGraph $theWave						
							// SetActiveSubWindow $(hostname+"#"+graphname2)
							// AppendToGraph $theWave2
						endif
		endif
		index += 1
	while (1) // Loop until break above	
End


Function PopMenuProc_TreePopUp(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	NVAR Groupcurrent, SeriesCurrent, SweepCurrent
	ControlInfo PopUp_Group
	GroupCurrent=V_Value
	ControlInfo PopUp_Series
	SeriesCurrent=V_Value
	SweepCurrent=1
	RefreshNewSweeps(GroupCurrent, SeriesCurrent, SweepCurrent)
End

function KillAllWaves(namewave)
	string namewave
	string list, strtemp
	variable i,n
	
	list=listwaves(namewave)
	i=0
	n=Itemsinlist(list)-1
	do
		Killwaves/Z $StringfromList(i,list)
		i += 1
	while (i<=n)
end

function/S ListWaves(namestr)
	string namestr
	string strtemp, listout
	strtemp="*"+namestr+"*"
	listout=Wavelist(strtemp,";","")
	print "listout =", listout
	return listout
end

Function ButtonProc_TreeArrows(ctrlName) : ButtonControl
	String ctrlName
	NVAR GroupCurrent, SeriesCurrent, SweepCurrent
	NVAR GroupTot, SeriesTot, SweepTot
	variable DisplayNewGraph=0 //Do I need to display the new graph? 0=No, 1=Yes

	if ((cmpstr(ctrlName,"Button_GroupPrevious")==0) && (GroupCurrent>1))
		GroupCurrent -=1
		SweepCurrent=0
		PopUpMenu PopUp_Group mode=GroupCurrent
		//ControlUpdate popup_Series
		DisplayNewGraph=1
	elseif ((cmpstr(ctrlName,"Button_GroupNext")==0) && (GroupCurrent<GroupTot))
		GroupCurrent +=1
		SweepCurrent=0
		PopUpMenu PopUp_Group mode=GroupCurrent
		//ControlUpdate popup_Series
		DisplayNewGraph=1
	elseif ((cmpstr(ctrlName,"Button_SeriePrevious")==0) && (SeriesCurrent>1))
		SeriesCurrent -=1
		SweepCurrent=1
		PopUpMenu PopUp_Series mode=SeriesCurrent
		DisplayNewGraph=1
	elseif ((cmpstr(ctrlName,"Button_SerieNext")==0) && (SeriesCurrent<SeriesTot))
		SeriesCurrent +=1
		SweepCurrent=1
		PopUpMenu PopUp_Series mode=SeriesCurrent
		DisplayNewGraph=1
	elseif ((cmpstr(ctrlName,"Button_SweepPrevious")==0) && (SweepCurrent>1))
		SweepCurrent -=1
		//		PopUpMenu PopUp_Sweep mode=SweepCurrent
		DisplayNewGraph=1
	elseif ((cmpstr(ctrlName,"Button_SweepNext")==0) && (SweepCurrent<SweepTot))
		SweepCurrent +=1
		//		PopUpMenu PopUp_Sweep mode=SweepCurrent
		DisplayNewGraph=1
	elseif (cmpstr(ctrlName,"Button_AllSweeps")==0)
		SweepCurrent=0
		//		PopUpMenu PopUp_Sweep mode=SweepCurrent
		DisplayNewGraph=1
	endif
	
	if (DisplayNewGraph==1)
		RefreshNewSweeps(GroupCurrent, SeriesCurrent, SweepCurrent)
	endif
End

Function PopMenuProc_FileName(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	string/G DATfilename=PopStr
	variable/G index_DAT=popNum
	RefreshFirstFile(DATfilename)
End

Function ButtonProc_FileArrows(ctrlName) : ButtonControl
	String ctrlName
	SVAR DATfiles
	NVAR index_DAT
	variable numfiles=ItemsInList(DATfiles), indextemp
	variable DisplayNewGraph=0
	string namestr

	if ((cmpstr(ctrlName,"Button_FilePrevious")==0) && (index_DAT>0))
		indextemp=index_DAT-1
		namestr=StringFromList(indextemp, DATfiles)
		if (strlen(namestr)==0)
			DoAlert 0,"Ran out of waves."
			DisplayNewGraph=0
		else
			index_DAT -=1
			DisplayNewGraph=1
		endif
	elseif ((cmpstr(ctrlName,"Button_FileNext")==0) && (index_DAT<numfiles))
		indextemp=index_DAT+1
		namestr=StringFromList(indextemp, DATfiles)
		if (strlen(namestr)==0)
			DoAlert 0,"Ran out of waves."
			DisplayNewGraph=0
		else
			index_DAT +=1
			DisplayNewGraph=1
		endif
	endif
	
	if (DisplayNewGraph==1)
		SVAR DATfilename
		DATfilename=StringFromList(index_DAT, DATfiles)
		RefreshFirstFile(DATfilename)
		//refreshControls()
	endif
End

//NOT WORKING - This function is just to quickly refresh the controls and popupmenus and such -AdrianGR
Function refreshControls()
	NVAR GroupCurrent, SeriesCurrent, SweepCurrent
	//SweepCurrent = 0
	PopUpMenu PopUp_Group mode=GroupCurrent
	PopUpMenu PopUp_Series mode=SeriesCurrent
	RefreshNewSweeps(GroupCurrent, SeriesCurrent, SweepCurrent)
End

Function ButtonProc_ZoomOUT(ctrlName) : ButtonControl
	String ctrlName
	Setactivesubwindow Panel_NeurignacioBrowser#BrowseGraph
	SetAxis/A left
	SetAxis/A bottom
End

Function ButtonProc_AddExperiment(ctrlName) : ButtonControl
	String ctrlName
	NVAR GroupCurrent, SeriesCurrent
	SVAR folderstr, DATfilename, protocolstr
	ControlInfo PopUp_expGroup
	string expgroupstr=S_Value
	ControlInfo PopUp_type
	string typestr=S_Value
	//	ControlInfo check_NewExperiment
	//	variable NewExperiment=1-V_Value //1: new entrance will be created for this filename
	
	if (WaveExists(folder)==0)
		Make/T/N=0 folder
	endif
	if (WaveExists(name)==0)
		Make/T/N=0 name
	endif
	if (WaveExists(suffix)==0)
		Make/T/N=0 suffix
	endif
	if (WaveExists(group)==0)
		Make/T/N=0 group
	endif
	if (WaveExists(type)==0)
		Make/T/N=0 type
	endif
	if (WaveExists($(protocolstr))==0)
		if (stringmatch(protocolstr, "*;"))
			protocolstr=RemoveEnding(protocolstr)
		endif
		
		Make/T/N=(numpnts(name)) $(protocolstr)
		SVAR/Z protocol_list		// Added /Z to the SVAR to prevent an error
		if (SVAR_exists(protocol_list)!=1) // Protocol_list does NOT exist, so I create it
			string/G protocol_list=""
		endif
		protocol_list +=protocolstr+";"
	endif
	wave/T w_protocol=$(protocolstr)
	
	print "protocolstr=",protocolstr
	
	if (FindListItem("DataTable", ChildWindowList("Panel_NeurignacioBrowser"))<0)
		edit/HOST=Panel_NeurignacioBrowser/N=DataTable/W=(185,555,1280,1024) folder, name, suffix, group, type
		Button button_save,pos={220,280},size={50,50},proc=ButtonProc_SaveTable,title="Save",help={"Save table to file"},fStyle=1,fColor=(16384,28160,65280)	//Added by Jakob to allow saving table to file
		Button button_rmLast, pos={300,295}, size={75,20}, proc=ButtonProc_rmLast, title="Remove last", fsize=10, fColor=(40000,0,0) //Button for removing the last appended series from the table -AdrianGR
	endif
	CheckDisplayed/W=Panel_NeurignacioBrowser#DataTable w_protocol
	if (V_Flag==0)
		AppendtoTable/W=Panel_NeurignacioBrowser#DataTable w_protocol 
	endif
	
	//	wave w_folder=folder
	//	wave w_name=name
	//	wave w_suffix=suffix
	//	wave w_group=group
	//	wave w_type=type
	
	string namestr=DATfilename[0,strlen(DATfilename)-5] //Removes final ".dat"
	variable n=numpnts(name)-1

	//if  ((cmpstr(namestr, name[n])==0) && (n>=0))  //This section adds sweep number to the same n in the protocol wave/T; This is unnecessary under the INFOLoader from 200324
	//	Redimension/N=(numpnts(name)) w_protocol
	//	w_protocol[n][0] += num2str(SeriesCurrent)+";"
	//	//		w_protocol[n][1] += num2str(GroupCurrent)+";"
	//else
	//	if (cmpstr(namestr, name[n])==0)
	//		if (cmpstr("",suffix[n])==0)
	//			AddTextWaveItem("B", suffix)
	//			suffix[n]="A"
	//		else
	//		AddTextWaveItem(num2char(char2num(suffix[n])+1),suffix) //C,D,E,F.....
	//		endif
	//	else
	//		AddTextWaveItem("",suffix)
	//	endif
		
		AddTextWaveItemInit(folderstr, folder)
		AddTextWaveItem(namestr, name)
		AddTextWaveItem(expgroupstr, group)
		AddTextWaveItem(typestr, type)
		AddTextWaveItem(num2str(SeriesCurrent)+";", w_protocol)
		
		//		CheckBox check_NewExperiment value=1
	//endif
	string/G exp_name=name[n+1]+suffix[n+1]
	//else
	//	beep //this serie was already added
	//endif	
	
End

//Defines the behavior of checkboxes "chk_ProtocolstrCleanup1" and "chk_ProtocolstrCleanup2" upon clicking -AdrianGR
Function proc_chk_Protocolstr(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	switch(CB_Struct.eventCode)
		case 2: //Only on mouse-up
			updateProtocolstr(cb=CB_Struct)
		break
	endswitch
	return 0 //Doesn't do anything, but Igor documentation says action procedures should always return zero
End

//Function to update protocolstr, to enable doing replacements and such -AdrianGR
Function updateProtocolstr([STRUCT WMCheckboxAction &cb]) //optional STRUCT parameter, is used when checkbox indirectly calls this function
	SVAR protocolstr
	NVAR GroupCurrent, SeriesCurrent, SweepCurrent
	
	if(ParamIsDefault(cb)==1) //Things to do when function isn't called from a checkbox (inferred based on optional parameter not having been passed)
		ControlInfo chk_ProtocolstrCleanup1
		if(V_Value==1)
			subroutine_chk_ProtocolstrCleanup1()
		endif
		ControlInfo chk_ProtocolstrCleanup2
		if(V_Value==1)
			subroutine_chk_ProtocolstrCleanup2()
		endif
	elseif(ParamIsDefault(cb)==0) //Things to do when function is called from a checkbox
		switch(cb.checked)
			case 1: //Checkbox was checked
				strswitch(cb.ctrlName) //Action depends on which checkbox called the function
					case "chk_ProtocolstrCleanup1":
						subroutine_chk_ProtocolstrCleanup1()
						CheckBox chk_ProtocolstrCleanup2, disable=2 //Disable the other checkbox to prevent conflicts
					break
					case "chk_ProtocolstrCleanup2":
						subroutine_chk_ProtocolstrCleanup2()
						CheckBox chk_ProtocolstrCleanup1, disable=2
					break
				endswitch
			break
			case 0: //Checkbox was unchecked
				RefreshNewSweeps(GroupCurrent, SeriesCurrent, SweepCurrent)
				CheckBox chk_ProtocolstrCleanup1, disable=0
				CheckBox chk_ProtocolstrCleanup2, disable=0
			break
		endswitch
	endif
End
//Subroutine to define what the checkbox "chk_ProtocolstrCleanup1" should do -AdrianGR
Function subroutine_chk_ProtocolstrCleanup1()
	SVAR protocolstr
	protocolstr = ReplaceString("rep", protocolstr, "")
	protocolstr = ReplaceString("\x23", protocolstr, "")
End
//Subroutine to define what the checkbox "chk_ProtocolstrCleanup2" should do -AdrianGR
Function subroutine_chk_ProtocolstrCleanup2()
	SVAR protocolstr, replaceSubStr2, replaceSubStr2with
	protocolstr = ReplaceString(replaceSubStr2, protocolstr, replaceSubStr2with)
End


//NOT FINISHED. Function for removing last appended series from the table. -AdrianGR
Function ButtonProc_rmLast(ctrlName) : ButtonControl
	String ctrlName
	SVAR protocol_list, w_protocol
	print DimSize(name,0)
	//thing
End


Function ButtonProc_SaveTable(ctrlName) : ButtonControl			//Added by Jakob to save Table easily
	String ctrlName
	SVAR protocol_list

	variable i, n
	string Savestring, newstr

	wave name
	print(Dimsize(name,0))
	make/O/T/N=(Dimsize(name,0)-0) suffix //Changed from -2 to 0 to fix error not allowing exactly two series to be loaded -AdrianGR

	Savestring="folder;name;suffix;group;type;"
	Savestring+=	protocol_list
	Save/J/B/M="\r\n"/W/F/I Savestring as "DataList.txt"
End

function AddTextWaveItemInit(itemStr, w)
	string ItemStr
	wave/T w
	variable n=numpnts(w)
	Redimension/N=(n+1) w
	w[n]=Itemstr
end

function AddTextWaveItem(itemStr, w)
	string ItemStr
	wave/T w
	variable n=numpnts(folder)
	Redimension/N=(n) w
	w[n]=Itemstr
end
	

Function PopMenuProc_Type(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String/G typestr=PopStr
End

Function ButtonProc_ExpGroup(ctrlName) : ButtonControl
	String ctrlName
	string/G exp_group
	string groupstr
	
	prompt groupstr, "Group: "
	DoPrompt "Add New Experiment Group", groupstr
	if (V_flag)
		return -1
	endif
	exp_group += groupstr+";"
	Popupmenu popup_expgroup mode=ItemsInList(exp_group)
End


function RefreshFirstFile(DATfilename)
	string DATfilename
	SVAR folderstr, gVersion, gAmplifier
	
	NVAR GroupCurrent
	GroupCurrent=1
	NVAR SeriesCurrent
	SeriesCurrent=1
	NVAR SweepCurrent
	SweepCurrent=1 //Changed to 0 because 1 is passed to fLoadPulse anyway -AdrianGR
	

	fLoadPulse(GroupCurrent, SeriesCurrent,1,gVersion,folderstr+DATfilename) //Load Pulse ".dat"
	
	
	
	if (cmpstr(gVersion,"PatchMaster")==0)
		if (cmpstr(gAmplifier,"EPC9")==0)  // Decide which amplifier to use
			getpulsenote($"PatchMaster_1_1_001_1_I-mon", "NotePulse") //Obtain information from Pulse Note
		elseif  (cmpstr(gAmplifier,"EPC9(old)")==0)
			getpulsenote($"PatchMaster_1_1_001_1_I-mon", "NotePulse") //Obtain information from Pulse Note
		else
			print "going to get note..."
			getpulsenote($"PatchMaster_1_1_001_1_I-mon", "NotePulse") //Obtain information from Pulse Note
		endif
	elseif (cmpstr(gVersion,"Pulse")==0)
		getpulsenote($"Pulse_1_1_001", "NotePulse") //Obtain information from Pulse Note
	endif
	
	
	wave/T wavenote=NotePulse
	if (cmpstr(gVersion,"Pulse")==0)
		string/G protocolstr=wavenote[23][1] //Stores name of the protocol for the Sweep
	elseif (cmpstr(gVersion,"PatchMaster")==0)
		string/G protocolstr=wavenote[27][1] //Stores name of the protocol for the Sweep
	endif
	if (stringmatch(protocolstr, "*;"))
		protocolstr=RemoveEnding(protocolstr)
	endif
	protocolstr=TrimString(protocolstr) //Removes leading and trailing whitespace  -AdrianGR
	
	//Obtain Tree Limits from Pulse Note (groups, series, sweeps) and creates PopUp Lists
	string tempstr=wavenote[4][1]
	variable/G GroupTot=str2num(tempstr[strsearch(tempstr,"of ",0)+3,Inf])
	string/G GroupPopList=""
	variable i=1
	do
		GroupPopList += num2str(i)+" of "+num2str(GroupTot)+";"
		i +=1
	while (i<=GroupTot)

	tempstr=wavenote[5][1]
	variable/G SeriesTot=str2num(tempstr[strsearch(tempstr,"of ",0)+3,Inf])
	i=1
	string/G SeriePopList=""
	do
		SeriePopList += num2str(i)+" of "+num2str(SeriesTot)+";"
		i +=1
	while (i<=SeriesTot)
	
	tempstr=wavenote[6][1]
	variable/G SweepTot=str2num(tempstr[strsearch(tempstr,"of ",0)+3,strlen(tempstr)-1])
	i=1
	string/G SweepPopList=""
	do
		SweepPopList += num2str(i)+" of "+num2str(SweepTot)+";"
		i +=1
	while (i<=SweepTot)
	
	//Updates popups and graph -AdrianGR
	if (cmpstr(Winlist("*NeurignacioBrowser*",";","WIN:64"),"")!=0)
		PopUpMenu PopUp_Group mode=1
		PopUpMenu PopUp_Series mode=1
		//PopUpMenu PopUp_Sweep mode=1
		if (cmpstr(gVersion,"PatchMaster")==0)
			DisplayWaveListInHost(WaveList("PatchMaster_1_1_*",";",""), "BrowseGraph", "Panel_NeurignacioBrowser")
		elseif (cmpstr(gVersion,"Pulse")==0)
			DisplayWaveListInHost(WaveList("Pulse_1_1_*",";",""), "BrowseGraph", "Panel_NeurignacioBrowser")
		endif
	endif

	updateProtocolstr() //-AdrianGR

End

function RefreshNewSweeps(Gc, Sc, Swc) //Gc is GroupCurrent, Sc is SeriesCurrent, Swc is SweepCurrent -AdrianGR
	variable Gc, Sc, Swc
	//print Gc,Sc,Swc
	variable AllSweeps
	String theWave, StringOfWave
	if (Swc<=0)
		NVAR gSweepCurrent=Swc
		gSweepCurrent=1
		Swc=1
		AllSweeps=0
	else
		AllSweeps=Swc
	endif
	SVAR folderstr,Datfilename,gVersion,gAmplifier
	KillWindow Panel_NeurignacioBrowser#BrowseGraph
	//if (cmpstr(gVersion,"PatchMaster")==0)
	//	KillWindow Panel_NeurignacioBrowser#BrowseGraph2
	//endif
	KillAllWaves(gVersion+"_")
	fLoadPulse(Gc, Sc, AllSweeps,gVersion,folderstr+DATfilename) 
	
	if (cmpstr(gVersion,"PatchMaster")==0)
		DisplayWaveListInHost(ListWaves(gVersion+"_"+num2str(Gc)+"_"+num2str(Sc)+"_"), "BrowseGraph", "Panel_NeurignacioBrowser")
	elseif (cmpstr(gVersion,"Pulse")==0)
		DisplayWaveListInHost(ListWaves(gVersion+"_"+num2str(Gc)+"_"+num2str(Sc)+"_"), "BrowseGraph", "Panel_NeurignacioBrowser")
	endif

	StringOfWave=ListWaves("Pulse_"+num2str(Gc)+"_"+num2str(Sc)+"_")
	//print "StringOfWave ",StringOfWave
	
	if (cmpstr(gVersion,"PatchMaster")==0)
		if (cmpstr(gAmplifier,"EPC9")==0) // Decide which amplifier to use
			getpulsenote($("PatchMaster_"+num2str(Gc)+"_"+num2str(Sc)+"_00"+num2str(Swc)+"_1_I-mon"), "NotePulse") //Obtain information from Pulse Note
		elseif (cmpstr(gAmplifier,"EPC9(old)")==0) // Decide which amplifier to use
			getpulsenote($("PatchMaster_"+num2str(Gc)+"_"+num2str(Sc)+"_00"+num2str(Swc)+"_1_I-mon"), "NotePulse") //Obtain information from Pulse Note
		else
			//if(stringmatch(StringOfWave, "*Imon*")==1)
					getpulsenote($("PatchMaster_"+num2str(Gc)+"_"+num2str(Sc)+"_00"+num2str(Swc)+"_1_I-mon"), "NotePulse") //Obtain information from Pulse Note
			//endif
			//if(stringmatch(StringOfWave, "*Vmon*")==1)		//programmed by Jakob B. Sørensen on 8. July 2021 to allow loading of current clamp data
			//		getpulsenote($("PatchMaster_"+num2str(Gc)+"_"+num2str(Sc)+"_00"+num2str(Swc)+"_1_I1"), "NotePulse") //Obtain information from Pulse Note
			//endif
		endif
	elseif (cmpstr(gVersion,"Pulse")==0)
		getpulsenote($("Pulse_"+num2str(Gc)+"_"+num2str(Sc)+"_00"+num2str(Swc)), "NotePulse") //Obtain information from Pulse Note
	endif

	wave/T wavenote=NotePulse
	if (cmpstr(gVersion,"Pulse")==0)
		string/G protocolstr=wavenote[23][1] //Stores name of the protocol for the Sweep
	elseif (cmpstr(gVersion,"PatchMaster")==0)
		string/G protocolstr=wavenote[27][1] //Stores name of the protocol for the Sweep
	endif
	if (stringmatch(protocolstr, "*;"))
		protocolstr=RemoveEnding(protocolstr)
	endif
	protocolstr=TrimString(protocolstr) //Removes leading and trailing whitespace  -AdrianGR
	string tempstr=wavenote[6][1]
	variable/G SweepTot=str2num(tempstr[strsearch(tempstr,"of ",0)+3,strlen(tempstr)-1])

	updateProtocolstr() //-AdrianGR

end

