function nClasses = writeRestrictedClasses(dictionary,minNumInstances,outfn,catchall)
%WRITERESTRICTEDCLASSES outputs the cue dictionary file
%   inputs
%       dictionary - a containers.Map object where each key is the category
%                    label and the value 
%       minNumInstances - minimum number of instances that a category must
%                         occur to be in the final output dictionary
%       outfn - file name to write the dictionary to
%       catchall - any categories that are meant to model any phrases that
%                  don't occur at least minNumInstances times
%   outputs
%       nClasses - final number of output categories in the dictionary
    if nargin < 4
        catchall = [];
    end
    
    classLabels = dictionary.keys();
    classDictionary = cell(length(classLabels)+length(catchall),1);
    for i = 1:length(classLabels)
        item = dictionary(classLabels{i});
        if item.nInstances >= minNumInstances
            classes = [classLabels(i),item.classVariants];
            classDictionary{i} = strcatWithDelimiter(classes);
        end
    end
    
    for i = 1:length(catchall)
        classDictionary{length(classLabels)+i} = strcatWithDelimiter(catchall{i});
    end
    
    classDictionary(cellfun(@isempty,classDictionary)) = [];
    nClasses = length(classDictionary);
    fileID = fopen(outfn,'w');
    cellfun(@(f)fprintf(fileID,'%s\n',f),classDictionary);
    fclose(fileID);
end