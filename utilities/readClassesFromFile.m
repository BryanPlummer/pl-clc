function classes = readClassesFromFile(filename,isTypeOnLeft)
%READCLASSESFROMFILE reads a class dictionary file from disk
%   inputs
%       filename - full file name of the dictionary file to read
%       isTypeOnLeft - indicator of if a phrase type is on the left side
%                       of an underscore or the right
%   outputs
%       classes - parsed categories in a struct format with the words and
%                 phrase types to identify each class
if nargin < 2
    isTypeOnLeft = true;
end

textLines = strsplit(fileread(filename),'\n');
textLines(cellfun(@isempty,textLines)) = [];
tokens = cellfun(@strsplit,textLines,'UniformOutput',false);
classLabels = cellfun(@(f)strsplit(f{1},'_'),tokens,'UniformOutput',false);
words = cell(length(classLabels),1);
types = cell(length(classLabels),1);
for i = 1:length(classLabels)
    tokens = strsplit(textLines{i});
    classLabel = strsplit(tokens{1},'_');
    if length(classLabel) == 3
        types{i} = classLabel([1;3]);
        words{i} = classLabel{2};
    else
        if isTypeOnLeft
            if length(classLabel) > 1
                types{i} = classLabel{1};
            end

            words{i} = classLabel{end};
        else
            if length(classLabel) > 1
                types{i} = classLabel{2};
            end
            
            words{i} = classLabel{1};
        end
    end

    words{i} = horzcat(words{i},tokens(2:end));
end

classes = [];
classes.words = words;
classes.types = types;
