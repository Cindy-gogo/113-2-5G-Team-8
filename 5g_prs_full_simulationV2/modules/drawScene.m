function walls = drawScene(ax, scene, thick)
    walls = {};
    if strcmp(scene, '單牆')
        walls{end+1} = [-10 -30 -10 30];
    elseif strcmp(scene, '多房')
        walls{end+1} = [-10 -30 -10 30];
        walls{end+1} = [10 -30 10 30];
        walls{end+1} = [-30 -10 30 -10];
        walls{end+1} = [-30 10 30 10];
    end
    for i = 1:length(walls)
        line(walls{i}([1 3]), walls{i}([2 4]), 'Parent', ax, 'Color','k','LineWidth',thick/10);
    end
end