function neededAdding = addIfNotInJavaPath(fileToAdd)
%ADDIFNOTINJAVAPATH adds a jar file to the java path if it is not already
%there
%   inputs
%       fileToAdd - name of the jar file to add
%   outputs
%       neededAdding - true if the jar file wasn't in the path previously
    inpath = javaclasspath;
    neededAdding = isempty(find(strcmp(fileToAdd,inpath),1));
    if neededAdding
        javaaddpath(fileToAdd)
    end
end

