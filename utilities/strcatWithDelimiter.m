function term = strcatWithDelimiter(words,delimiter)
%STRCATWITHDELIMITER concatenates words with a delimiter between different
%words
%   inputs
%       words - cell array of words to concatenate
%       delimiter - character to place between the elements of the words
%                   input variable
%   outputs
%       term - character array with the array of words concatenated with
%              the delimiter
    if isempty(words)
        term = [];
        return;
    end
    if ~iscell(words)
        error('strcatWithDelimiter: only supports cell array inputs');
    end
    if nargin < 2
        delimiter = ' ';
    end

    words = strtrim(words);
    nWords = length(words);
    if nWords > 1
        term = cell(1,length(words)+length(words)-1);
        term(1:2:length(term)) = words;
        delIdx = 2:2:length(term);
        term(delIdx) = repmat({delimiter},length(delIdx),1);
        term = horzcat(term{:});
    else
        term = words{1};
    end
end

