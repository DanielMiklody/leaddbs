function [h,R,p,g]=ea_corrplot_new(X,Y,labels,corrtype)
% Wrapper for gramm to produce a simple correlation plot.
% Group1 denotes colors, Group2 Markers.
% Can also specify custom colors
% (c) Andreas Horn 2019 Charite Berlin

% Example usage:
% ---------------
% X=randn(100,1);
% Y=X.*randn(100,1);
%
% ea_corrplot(X,Y)
%
% group1cell={'Prague','Berlin','London','Moscow','Paris','Madrid'};
% group1.idx=group1cell(ceil(rand(100,1)*6));
% group1.tag='Cohort';
%
% group2cell={'Parkinson','Alzheimer'};
% group2.idx=group2cell(ceil(rand(100,1)*2));
% group2.tag='Disease';
%
% ea_corrplot(X,Y,{'Example Correlation','Age','Disease Duration'},'spearman',group1,group2)
%%user handling%%
%If you don't provide labels and variables
if ~exist('labels','var')
    labels={'','X','Y'};
end
%If you provide only title
if ~(length(labels)==3) % assume only title provided
    labels{2}='X'; labels{3}='Y';
end
%if you haven't specified a corrtype, the default value is Pearson
%correlation
if ~exist('corrtype','var')
    [R,p] = ea_permcorr(X,Y,'Pearson');
    [h,g] = figures(X,Y,R,p);
end
if strcmp(corrtype,'spearman')
    [R,p] = ea_permcorr(X,Y,'spearman');
    [h,g] = figures(X,Y,R,p);    
end
%gramm is a powerful visualization toolbox to create publication quality
%figures
function [h,g] = figures(X,Y,R,p)
   g=gramm('x',X,'y',Y);
   g.stat_glm();
   %PVALUE details
   pv=p;
   pstr='p';
   if exist('pperm','var') && ~isempty(pperm)
      pv=pperm;
      pstr='p(perm)';
   end
   g.set_title([labels{1},' [R = ',sprintf('%.2f',R),'; ',pstr,' = ',sprintf('%.3f',pv),']'],'FontSize',20);
   g.set_names('x',labels{2},'y',labels{3});
   g.set_text_options('base_size',22);
   g.no_legend();
   ratio = 7/8;
   Width = 550;
   Height = Width*ratio;
   h=figure('Position',[200 200 Width Height]);
   g.geom_point();
   g.draw();
   b = uicontrol(h,'Style','listbox','Position',[50 435 100 22],'Value',1,'String', {'Pearson','Spearman'},'FontSize',14);
   set(b,'Callback', @listbox_callbck);
   function listbox_callbck(hObject,callbackdata)
       disp(b.String(hObject.Value));
       if  hObject.Value == 1
          [R,p] = ea_permcorr(X,Y,'Pearson');
          [h,g] = figures(X,Y,R,p);
       else
          [R,p] = ea_permcorr(X,Y,'spearman');
          [h,g] = figures(X,Y,R,p);
       end
   end
       
  
end
   
  
end
