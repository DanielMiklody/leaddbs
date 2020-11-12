function s=ea_roi2struct(obj)

props = properties(obj);
for p = 1:numel(props)
    if ~ismember(props{p},{'controlH','plotFigureH','patchH','toggleH','htH','Tag'})
        s.(props{p})=obj.(props{p});
    else
        s.(props{p})=[];
    end
end