function dirList = getDirList(querydir,flag)
    if nargin < 2
        isdir = 0;
    else
        if strcmp(flag,'dir')
            isdir = 1;
        else
            error('Only supported flag is "dir"');
        end
    end
    
    if isdir
        dirList = dir(querydir);
        dirList = dirList([dirList.isdir]);
        dirList(strcmp('.',{dirList.name})) = [];
        dirList(strcmp('..',{dirList.name})) = [];
    else
        dirList = dir(sprintf('%s/*',querydir));
        dirList = dirList(~[dirList.isdir]);
    end
    
    dirList = {dirList.name};
end

