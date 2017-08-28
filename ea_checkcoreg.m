function varargout = ea_checkcoreg(varargin)
% EA_CHECKCOREG MATLAB code for ea_checkcoreg.fig
%      EA_CHECKCOREG, by itself, creates a new EA_CHECKCOREG or raises the existing
%      singleton*.
%
%      H = EA_CHECKCOREG returns the handle to a new EA_CHECKCOREG or the handle to
%      the existing singleton*.
%
%      EA_CHECKCOREG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EA_CHECKCOREG.M with the given input arguments.
%
%      EA_CHECKCOREG('Property','Value',...) creates a new EA_CHECKCOREG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ea_checkcoreg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ea_checkcoreg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ea_checkcoreg

% Last Modified by GUIDE v2.5 28-Aug-2017 17:55:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ea_checkcoreg_OpeningFcn, ...
    'gui_OutputFcn',  @ea_checkcoreg_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ea_checkcoreg is made visible.
function ea_checkcoreg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ea_checkcoreg (see VARARGIN)

options=varargin{1};
%ea_init_coregmrpopup(handles,1);
set(handles.leadfigure,'Name',[options.patientname, ': Check Coregistration']);

directory=[options.root,options.patientname,filesep];

setappdata(handles.leadfigure,'options',options);
setappdata(handles.leadfigure,'directory',directory);

[pth,patientname]=fileparts(fileparts(directory));
handles.patientname.String=patientname;

set(handles.leadfigure,'name',['MR-Coregistration: ',patientname]);


presentfiles=ea_getall_coregcheck(options);
anchor=presentfiles{1};
presentfiles(1)=[];

set(handles.normsettings,'Visible','off');
if exist([directory,options.prefs.gprenii],'file') && ~ea_coreglocked(options,options.prefs.gprenii)
    presentfiles=[presentfiles;{[directory,options.prefs.gprenii]}];
end

if isempty(presentfiles)
    close(handles.leadfigure)
   return 
end
%set(handles.previous,'visible','off'); set(handles.next,'visible','off');



setappdata(handles.leadfigure,'presentfiles',presentfiles)
setappdata(handles.leadfigure,'anchor',anchor)
setappdata(handles.leadfigure,'activevolume',1);
setappdata(handles.leadfigure,'options',options);

ea_mrcview(handles);



% Choose default command line output for ea_checkcoreg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ea_checkcoreg wait for user response (see UIRESUME)


function ea_mrcview(handles)

options=getappdata(handles.leadfigure,'options');

presentfiles=getappdata(handles.leadfigure,'presentfiles');
anchor=getappdata(handles.leadfigure,'anchor');
activevolume=getappdata(handles.leadfigure,'activevolume');
directory=[options.root,options.patientname,filesep];

if activevolume==length(presentfiles)
    set(handles.disapprovebutn,'String','Disapprove & Close');
    set(handles.approvebutn,'String','Approve & Close');
    
else
    set(handles.approvebutn,'String','Approve & Next >>');
    set(handles.disapprovebutn,'String','Disapprove & Next >>');
    
end

currvol=presentfiles{activevolume};

switch stripex(currvol)
    case 'glanat'
        [options] = ea_assignpretra(options);
        anchor=[ea_space,options.primarytemplate,'.nii'];
        set(handles.leadfigure,'Name',[options.patientname, ': Check Normalization']);
        
        ea_addnormmethods(handles,options,'coregmrpopup');
        
        if ~exist([directory,'ea_normmethod_applied.mat'],'file')
            method='';
        else
            method=load([directory,'ea_normmethod_applied.mat']);
            method=method.norm_method_applied{end};
        end
        
        set(handles.anchortxt,'String','Template (red wires):');
        set(handles.coregresultstxt,'String','Normalization results:');
        set(handles.normsettings,'Visible','on');
    otherwise
        set(handles.anchortxt,'String','Anchor modality (red wires):');
        set(handles.coregresultstxt,'String','Coregistration results:');
        set(handles.leadfigure,'Name',[options.patientname, ': Check Coregistration']);
        
        switch currvol
            case ['tp_',options.prefs.ctnii_coregistered] % CT
                ea_init_coregctpopup(handles,options,'coregmrpopup');
                if ~exist([directory,'ea_coregctmethod_applied.mat'],'file')
                    method='';
                else
                    method=load([directory,'ea_coregctmethod_applied.mat']);
                    method=method.coregct_method_applied{end};
                end
            otherwise % MR
                ea_init_coregmrpopup(handles,1);
                if ~exist([directory,'ea_coregmrmethod_applied.mat'],'file')
                    method='';
                else
                    method=load([directory,'ea_coregmrmethod_applied.mat']);
                    if isfield(method,stripex(currvol)) % specific method used for this modality
                        method=method.(stripex(currvol));
                    else
                        if isfield(method,'coregmr_method_applied')
                        method=method.coregmr_method_applied{end};
                        else
                            method='';
                        end
                    end
                end
               
        end
        
        set(handles.normsettings,'Visible','off');
end
if ~exist([directory,'ea_coreg_approved.mat'],'file') % init
    for vol=1:length(presentfiles)
        approved.(stripex(presentfiles{vol}))=0;
    end
    save([directory,'ea_coreg_approved.mat'],'-struct','approved');
else
    approved=load([directory,'ea_coreg_approved.mat']);
end
setappdata(handles.leadfigure,'method',method);

% show result:
checkfig=[directory,'checkreg',filesep,stripex(currvol),'2',stripex(anchor),'_',method,'.png'];
if ~exist(checkfig,'file')
    switch stripex(currvol)
        case 'glanat'
            options=ea_assignpretra(options);
            anchorpath=[ea_space,options.primarytemplate];
        otherwise
            anchorpath=[directory,stripex(anchor)];
    end
    ea_gencheckregpair([directory,stripex(currvol)],anchorpath,checkfig);
    if ~exist(checkfig,'file')
        checkfig=fullfile(ea_getearoot,'helpers','gui','coreg_msg.png');
    end
end
im=imread(checkfig);
set(0,'CurrentFigure',handles.leadfigure);
set(handles.leadfigure,'CurrentAxes',handles.standardax);

imagesc(im);
axis off
axis equal

% textfields:

set(handles.depvolume,'String',[stripex(currvol),'.nii']);

function fn=stripex(fn)
[~,fn]=fileparts(fn);

function presentfiles=ea_getall_coregcheck(options)
directory=[options.root,options.patientname,filesep];
[options,presentfiles]=ea_assignpretra(options);
% add postoperative volumes:
switch options.modality
    case 1 % MR
        if exist([directory,options.prefs.tranii_unnormalized],'file')
            presentfiles=[presentfiles;options.prefs.tranii_unnormalized];
        end
        if exist([directory,options.prefs.cornii_unnormalized],'file')
            presentfiles=[presentfiles;options.prefs.cornii_unnormalized];
        end
        if exist([directory,options.prefs.sagnii_unnormalized],'file')
            presentfiles=[presentfiles;options.prefs.sagnii_unnormalized];
        end
    case 2 % CT
        if exist([directory,'tp_',options.prefs.ctnii_coregistered],'file')
            presentfiles=[presentfiles;['tp_',options.prefs.ctnii_coregistered]];
        end
end
if exist([directory,options.prefs.fa2anat],'file')
    presentfiles=[presentfiles;options.prefs.fa2anat];
end

% now check if those are already approved (then don't show again):

todel=[];
for pf=1:length(presentfiles)
    if ea_coreglocked(options,presentfiles{pf})
        todel=[todel,pf];
    end
end
presentfiles(todel)=[];




% --- Outputs from this function are returned to the command line.
function varargout = ea_checkcoreg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


% --- Executes on selection change in methodbutton.
function methodbutton_Callback(hObject, eventdata, handles)
% hObject    handle to methodbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns methodbutton contents as cell array
%        contents{get(hObject,'Value')} returns selected item from methodbutton


% --- Executes during object creation, after setting all properties.
function methodbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to methodbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in recomputebutn.
function recomputebutn_Callback(hObject, eventdata, handles)
% hObject    handle to recomputebutn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',handles.leadfigure,'coreg');

options=getappdata(handles.leadfigure,'options');

presentfiles=getappdata(handles.leadfigure,'presentfiles');
anchor=getappdata(handles.leadfigure,'anchor');
activevolume=getappdata(handles.leadfigure,'activevolume');
directory=[options.root,options.patientname,filesep];

currvol=presentfiles{activevolume};


switch stripex(currvol)
    case 'glanat'
        options.normalize.method=getappdata(handles.leadfigure,'normmethod');
        options.normalize.method=options.normalize.method{get(handles.coregmrpopup,'Value')};
        options.normalize.methodn=get(handles.coregmrpopup,'Value');
        ea_dumpnormmethod(options,options.normalize.method,'normmethod'); % has to come first due to applynormalization.
        eval([options.normalize.method,'(options)']); % triggers the normalization function and passes the options struct to it.
        
        if options.modality == 2 % (Re-) compute tonemapped (normalized) CT
            ea_tonemapct_file(options,'mni');
        end
        
    case ['tp_',options.prefs.ctnii_coregistered] % CT
        options.coregct.method=getappdata(handles.leadfigure,'coregctmethod');
        options.coregct.method=options.coregct.method{get(handles.coregmrpopup,'Value')};
        options.coregct.methodn=get(handles.coregmrpopup,'Value');
        
        eval([options.coregct.method,'(options)']); % triggers the coregct function and passes the options struct to it.
        ea_dumpnormmethod(options,options.coregct.method,'coregctmethod');
        ea_tonemapct_file(options,'native'); % (Re-) compute tonemapped (native space) CT
        ea_gencoregcheckfigs(options); % generate checkreg figures
        
    otherwise % MR
        options.coregmr.method=get(handles.coregmrpopup,'String');
        options.coregmr.method=options.coregmr.method{get(handles.coregmrpopup,'Value')};
        ea_coreg2images(options,[directory,presentfiles{activevolume}],[directory,anchor],[directory,presentfiles{activevolume}],{},0);
        ea_dumpspecificmethod(handles,options.coregmr.method)
end

ea_mrcview(handles)
ea_busyaction('off',handles.leadfigure,'coreg');


function ea_dumpspecificmethod(handles,method)
options=getappdata(handles.leadfigure,'options');

presentfiles=getappdata(handles.leadfigure,'presentfiles');
anchor=getappdata(handles.leadfigure,'anchor');
activevolume=getappdata(handles.leadfigure,'activevolume');
directory=[options.root,options.patientname,filesep];

m=load([directory,'ea_coregmrmethod_applied.mat']);
m.(stripex(presentfiles{activevolume}))=method;
save([directory,'ea_coregmrmethod_applied.mat'],'-struct','m');




% --- Executes on button press in approvebutn.
function approvebutn_Callback(hObject, eventdata, handles)
% hObject    handle to approvebutn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',handles.leadfigure,'coreg');

options=getappdata(handles.leadfigure,'options');
presentfiles=getappdata(handles.leadfigure,'presentfiles');
activevolume=getappdata(handles.leadfigure,'activevolume');
directory=[options.root,options.patientname,filesep];
currvol=presentfiles{activevolume};


switch stripex(currvol)
    case 'glanat'
    case stripex(['tp_',options.prefs.ctnii_coregistered])
    otherwise % make sure method gets logged for specific volume.
        method=getappdata(handles.leadfigure,'method');
        if exist([directory,'ea_coregmrmethod_applied.mat'],'file')
        m=load([directory,'ea_coregmrmethod_applied.mat']);
        end
        m.(stripex(currvol))=method;
        save([directory,'ea_coregmrmethod_applied.mat'],'-struct','m');
end


approved=load([directory,'ea_coreg_approved.mat']);

approved.(stripex(currvol))=1;
save([directory,'ea_coreg_approved.mat'],'-struct','approved');





presentfiles=getappdata(handles.leadfigure,'presentfiles');
anchor=getappdata(handles.leadfigure,'anchor');
activevolume=getappdata(handles.leadfigure,'activevolume');

if activevolume==length(presentfiles)
    close(handles.leadfigure); % make an exit
    return
else
    activevolume=activevolume+1;
end
setappdata(handles.leadfigure,'activevolume',activevolume);
ea_mrcview(handles);
ea_busyaction('off',handles.leadfigure,'coreg');


% --- Executes on selection change in coregmrpopup.
function coregmrpopup_Callback(hObject, eventdata, handles)
% hObject    handle to coregmrpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coregmrpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coregmrpopup

options=getappdata(handles.leadfigure,'options');

presentfiles=getappdata(handles.leadfigure,'presentfiles');
activevolume=getappdata(handles.leadfigure,'activevolume');
currvol=presentfiles{activevolume};
% init retry popup:
if strcmp(currvol,'glanat.nii')
    
    ea_switchnormmethod(handles,'coregmrpopup');
end


% --- Executes during object creation, after setting all properties.
function coregmrpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coregmrpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in openviewer.
function openviewer_Callback(hObject, eventdata, handles)
% hObject    handle to openviewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options=getappdata(handles.leadfigure,'options');
presentfiles=getappdata(handles.leadfigure,'presentfiles');
activevolume=getappdata(handles.leadfigure,'activevolume');
currvol=presentfiles{activevolume};
switch stripex(currvol)
    case 'glanat'
        ea_show_normalization(options);
    otherwise
        presentfiles=getappdata(handles.leadfigure,'presentfiles');
        anchor=getappdata(handles.leadfigure,'anchor');
        activevolume=getappdata(handles.leadfigure,'activevolume');
        
        directory=[options.root,options.patientname,filesep];
        
        options.moving=[directory,presentfiles{activevolume}];
        options.fixed=[directory,anchor];
        options.tag=[presentfiles{activevolume},' & ',anchor];
        
        ea_show_coregistration(options);
        
end


% --- Executes on button press in normsettings.
function normsettings_Callback(hObject, eventdata, handles)
% hObject    handle to normsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currentNormMethod=getappdata(handles.normsettings,'currentNormMethod');
ea_shownormsettings(currentNormMethod,handles)


% --- Executes on button press in disapprovebutn.
function disapprovebutn_Callback(hObject, eventdata, handles)
% hObject    handle to disapprovebutn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% hObject    handle to approvebutn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',handles.leadfigure,'coreg');

options=getappdata(handles.leadfigure,'options');
presentfiles=getappdata(handles.leadfigure,'presentfiles');
activevolume=getappdata(handles.leadfigure,'activevolume');
directory=[options.root,options.patientname,filesep];
currvol=presentfiles{activevolume};



approved=load([directory,'ea_coreg_approved.mat']);

approved.(stripex(currvol))=0;
save([directory,'ea_coreg_approved.mat'],'-struct','approved');


switch stripex(currvol)
    case 'glanat'
    case stripex(['tp_',options.prefs.ctnii_coregistered])
    otherwise % make sure method gets unlogged for specific volume.
        method=getappdata(handles.leadfigure,'method');
        m=load([directory,'ea_coregmrmethod_applied.mat']);
        if isfield(m,stripex(currvol))
            m=rmfield(m,stripex(currvol));
        end
        save([directory,'ea_coregmrmethod_applied.mat'],'-struct','m');
end


presentfiles=getappdata(handles.leadfigure,'presentfiles');
anchor=getappdata(handles.leadfigure,'anchor');
activevolume=getappdata(handles.leadfigure,'activevolume');

if activevolume==length(presentfiles)
    close(handles.leadfigure); % make an exit
    return
else
    activevolume=activevolume+1;
end
setappdata(handles.leadfigure,'activevolume',activevolume);
ea_mrcview(handles);
ea_busyaction('off',handles.leadfigure,'coreg');


% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
% hObject    handle to back (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',handles.leadfigure,'coreg');

options=getappdata(handles.leadfigure,'options');
presentfiles=getappdata(handles.leadfigure,'presentfiles');
activevolume=getappdata(handles.leadfigure,'activevolume');
activevolume=getappdata(handles.leadfigure,'activevolume');

if activevolume==1
    return
else
    activevolume=activevolume-1;
end
setappdata(handles.leadfigure,'activevolume',activevolume);
ea_mrcview(handles);
ea_busyaction('off',handles.leadfigure,'coreg');