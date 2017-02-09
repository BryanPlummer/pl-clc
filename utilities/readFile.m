function contents = readFile(filename)
    contents = strsplit(fileread(filename),'\n');
    contents(cellfun(@isempty,contents)) = [];
end