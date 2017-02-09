classdef StanfordParser < handle
%STANFORDPARSER matlab interface for the components of the Stanford parser
%that are used in this project
    properties
        % java parser object
        textParser = [];
        
        % stored sentences that have been previously parsed
        sentences = containers.Map;
        
        % parameters used for the java parser object
        opts = [];
        
        % coarse phrase type dictionary
        typeMap = containers.Map;
    end
    
    methods
        function parser = StanfordParser(varargin)
            ip = inputParser;
            defaultParser = fullfile('edu','stanford','nlp','models','lexparser','englishRNN.ser.gz');
            defaultVersion = '3.4.1';
            ip.addParameter('type',defaultParser);
            ip.addParameter('version',defaultVersion);
            ip.parse(varargin{:});
            opts = ip.Results;
            ejmlFile = fullfile(pwd,'external','stanford-parser','ejml-0.23.jar');
            addIfNotInJavaPath(ejmlFile);
            modelJarFN = sprintf('stanford-parser-%s-models.jar',opts.version);
            modelsFile = fullfile(pwd,'external','stanford-parser',modelJarFN);
            addIfNotInJavaPath(modelsFile);
            parserFile = fullfile(pwd,'external','stanford-parser','stanford-parser.jar');
            addIfNotInJavaPath(parserFile);
            parser.textParser = edu.stanford.nlp.parser.lexparser.LexicalizedParser.loadModel(opts.type,{'-maxlength','200'});
            parser.opts = opts;
            categorydir = fullfile('dictionaries','coarseCategoryDictionaries');
            categoryList = getDirList(categorydir);
            cellfun(@(f)addTypeLexicon(parser,f,categorydir),categoryList);
        end
        
        function addTypeLexicon(parser,filename,filedir)
        %ADDTYPELEXICON reads a lexicon from disk and stores it in the
        %typeMap member variable
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       filename - file name of the lexicon to read
        %       filedir - directory containing the lexicon
            if isempty(parser.typeMap)
                category = strrep(filename,'.txt','');
                assert(~parser.typeMap.isKey(category));
                parser.typeMap(category) = readFile(fullfile(filedir,filename));
            end
        end
        
        function parseTree = parseSentence(parser,rawSentence)
        %PARSESENTENCE returns a java Tree object containing the parsed
        %sentence
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       rawSentence - sentence to parse (character array data type)
        %   outputs
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
            if parser.sentences.isKey(rawSentence)
                parseTree = parser.sentences(rawSentence);
            else
                parseTree = parser.textParser.parse(rawSentence);
                parser.sentences(rawSentence) = parseTree;
            end
        end
        
        function [entities,phraseMap,parseTree] = getKnownPhrases(parser,sentence,phrases,entityID,groups)
        %GETKNOWNPHRASES returns a set of predefined phrases, as occurs
        %with the annotated phrases in the Flickr30k Entities dataset
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       sentence - character array of the sentence to extract
        %                  phrases from
        %       phrases - character array of known phrases
        %       entityID - identifier for the known phrases
        %       groups - phrase types for the known phrases
        %   outputs
        %       entities - Entity objects containing the phrase data
        %       phraseMap - array that maps the parseTree leaf indices to
        %                   entity instances
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
            if isempty(phrases)
                entities = [];
                phraseMap = [];
                parseTree = [];
                return;
            end
            parseTree = parser.parseSentence(sentence);
            treeLeaves = parseTree.getLeaves();
            entities(length(phrases),1) = Entity;
            nLeaves = treeLeaves.size();
            phraseMap = zeros(nLeaves,1);
            leafIdx = 1;
            for i = 1:length(phrases)
                wordTokenized = cell(length(phrases{i}),1);
                wordPOS = cell(length(phrases{i}),1);
                j = 1;
                while j <= length(phrases{i})
                    word = phrases{i}{j};
                    N = 0;
                    % A single phrase could have been tokenized into
                    % multiple chunks, so need to do substring matching to
                    % find the entire phrase.
                    for k = leafIdx:nLeaves
                        leafIdx = leafIdx + 1;
                        leaf = treeLeaves.get(k-1);
                        idx =  parseTreeStringCompareN(leaf,word,N);
                        if N > 0 && isempty(idx)
                            N = 0;
                            idx = parseTreeStringCompareN(leaf,word,N);
                        end
                        if ~isempty(idx)
                            phraseMap(k) = i;
                            wordTokenized{j} = [wordTokenized{j};{word(N+1:idx)}];
                            wordPOS{j} = [wordPOS{j};{char(leaf.parent(parseTree).label)}];
                            N = idx;
                            if idx == length(word)
                                break;
                            end
                        else
                            wordTokenized{j} = [];
                            wordPOS{j} = [];
                            phrasesMatched = find(phraseMap == i);
                            if ~isempty(phrasesMatched)
                                if j > 1
                                    j = j - 1;
                                    word = phrases{i}{j};
                                end
                                phraseMap(phrasesMatched) = 0;
                            end

                            % A phrase's words should be right next to each 
                            % other in the parse tree.
                            assert(N == 0);
                        end
                    end 

                    assert(N == length(word));
                    j = j + 1;
                end

                wordPOS = vertcat(wordPOS{:});
                wordTokenized = vertcat(wordTokenized{:});
                treePosition = find(phraseMap == i,1,'first');
                entities(i) = Entity(wordTokenized,wordPOS,treePosition,entityID{i},groups{i});
            end 

            nMapped = length(unique(phraseMap(phraseMap > 0)));
            assert(nMapped == length(phrases));

            for i = 1:nMapped
                phraseIdx = find(phraseMap == i);
                mapped = min(phraseIdx):max(phraseIdx);
                assert(length(phraseIdx) == length(mapped));
            end
        end
        
        function [entities,phraseMap,parseTree] = getPhrases(parser,sentence)
        %GETPHRASES returns a set of noun phrase chunks
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       sentence - character array of the sentence to extract
        %                  phrases from
        %   outputs
        %       entities - Entity objects containing the phrase data
        %       phraseMap - array that maps the parseTree leaf indices to
        %                   entity instances
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
            parseTree = parser.parseSentence(sentence);
            treeLeaves = parseTree.getLeaves();
            nLeaves = treeLeaves.size();
            sentence = removePunctuation(sentence);
            nJumpsToPhraseNode = 2;
            leafMap = zeros(nLeaves,1);
            for i = 1:nLeaves
                leaf = treeLeaves.get(i-1);
                phraseNode = leaf.ancestor(nJumpsToPhraseNode,parseTree);
                if strncmp('NP',phraseNode.label,2) || strncmp('ADJP',phraseNode.label,4)
                    leafMap(i) = phraseNode.nodeNumber(parseTree);
                end
            end

            phraseID = unique(leafMap(leafMap > 0));
            entities(length(phraseID),1) = Entity;
            phraseMap = zeros(nLeaves,1);
            invalid = false(length(phraseID),1);
            currentID = 1;
            for i = 1:length(phraseID)
                phraseLeafIdx = find(leafMap == phraseID(i));
                phraseMap(phraseLeafIdx) = currentID;
                wordTokenized = cell(length(phraseLeafIdx),1);
                wordPOS = cell(length(phraseLeafIdx),1);
                for j = 1:length(phraseLeafIdx)
                    leaf = treeLeaves.get(phraseLeafIdx(j)-1);
                    wordTokenized{j} = char(leaf.label);
                    wordPOS{j} = char(leaf.parent(parseTree).label);
                end
                
                wordTokenized = parseTreeToken2Words(wordTokenized);
                words = removePunctuation(strcatWithDelimiter(wordTokenized,' '));
                words = strtrim(words);
                if isempty(words) || strcmpi(words,'and') || strcmpi(words,'or')
                    invalid(i) = true;
                    phraseMap(phraseLeafIdx) = 0;
                    continue
                end

                currentID = currentID + 1;
                treePosition = min(phraseLeafIdx);
                entityID = num2str(phraseID(i));
                groups = parser.getCoarseCategory(wordTokenized,parseTree,phraseMap,i);
                entities(i) = Entity(wordTokenized,wordPOS,treePosition,entityID,groups);
            end

            entities(invalid) = [];
        end

        function groups = getCoarseCategory(parser,words,parseTree,phraseMap,phraseID)
        %GETCOARSECATEGORY obtains the phrase types of the input phrase
        %based on lexicons stored in the typeMap member variable
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       words - cell array containing the individual words of the
        %               phrase to type
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
        %       phraseMap - array that maps the parseTree leaf indices to
        %                   entity instances
        %       phraseID - identifier for the phrases
        %   outputs
        %       groups - phrase types for the input phrase
            categories = parser.typeMap.keys();
            treeLeaves = parseTree.getLeaves();
            nLeaves = treeLeaves.size();
            wordTokenized = cell(nLeaves,1);
            for i = 1:nLeaves
                leaf = treeLeaves.get(i-1);
                wordTokenized{i} = char(leaf.label);
            end

            firstWordIdx = find(phraseMap == phraseID,1);
            hasGroup = false(length(categories),1);
            for i = 1:length(categories)
                categoryWords = parser.typeMap(categories{i});
                if ~isempty(strfind(categories{i},'_phrase'))
                    maxNumWords = max(cellfun(@(f)length(strsplit(f,' ')),categoryWords));
                    wordsBefore = wordTokenized(1:firstWordIdx-maxNumWords);
                    wordsBefore = getPunctuationFilteredWords(wordsBefore,maxNumWords,false);
                    for j = 1:length(wordsBefore)
                        phrase = strcatWithDelimiter(wordsBefore(end-j+1:end),' ');
                        hasGroup(i) = ~isempty(find(strcmpi(phrase,categoryWords),1));
                        if hasGroup(i),break,end
                    end

                    if hasGroup(i),continue,end
                    wordsAfter = wordTokenized(firstWordIdx+length(words):end);
                    wordsAfter = getPunctuationFilteredWords(wordsAfter,maxNumWords,true);
                    for j = 1:length(wordsAfter)
                        phrase = strcatWithDelimiter(wordsAfter(1:j),' ');
                        hasGroup(i) = ~isempty(find(strcmpi(phrase,categoryWords),1));
                        if hasGroup(i),break,end
                    end
                else
                    for j = 1:length(words)
                        phrase = strcatWithDelimiter(words(end-j+1:end),' ');
                        phrase = removePunctuation(phrase);
                        hasGroup(i) = ~isempty(find(strcmpi(phrase,categoryWords),1));
                        if hasGroup(i),break,end
                    end
                end
            end

            categories = categories(hasGroup);
            if isempty(categories)
                groups = {'other'};
            else
                groups = strrep(categories,'_phrase','');
                groups = unique(strrep(groups,'colors','clothing'));
                if length(groups) > 1 && ~isempty(find(strcmp('notvisual',groups),1))
                    groups = {'notvisual'};
                end
            end
        end

        function [relationship,phrase] = extractAllSentenceData(parser,sentence,phrases,entityID,groups)
        %GETCOARSECATEGORY obtains the phrase types of the input phrase
        %based on lexicons stored in the typeMap member variable
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       sentence - input sentence to extract entity and pair phrase
        %                  relation data from
        %       phrases - optional, known phrases to extract
        %       entityID - optional, identifier for the input phrases
        %       groups - optional, phrase types for the input phrases
        %   outputs
        %       relationship - pair phrase relations for the sentence
        %       phrase - entity data for the sentence
            if nargin > 2
                [phrase,phraseMap,parseTree] = parser.getKnownPhrases(sentence,phrases,entityID,groups);
            else
                [phrase,phraseMap,parseTree] = parser.getPhrases(sentence);
            end
            if isempty(phrase)
                relationship = [];
                return;
            end
            treeLeaves = parseTree.getLeaves();
            nonPhraseLeaves = find(phraseMap == 0);
            relationship = cell(length(nonPhraseLeaves),1);
            for i = 1:length(nonPhraseLeaves)
                leafIndex = nonPhraseLeaves(i);
                leaf = treeLeaves.get(leafIndex-1);
                relationship{i} = parser.getRelationship(parseTree,leaf,leafIndex,phraseMap);
            end
            
            relationship(cellfun(@isempty,relationship)) = [];
            relationship = vertcat(relationship{:});
            relationship = parser.createComplexRelationships(relationship);
            invalidRelation = false(length(relationship),1);
            for i = 1:length(relationship)
                if ~isempty(relationship(i).leftPhrase)
                    leftPosition = phrase(relationship(i).leftPhrase).sentencePosition;
                    invalidRelation(i) = leftPosition >= relationship(i).sentencePosition;
                end
                if ~invalidRelation(i) && ~isempty(relationship(i).rightPhrase)
                    rightPosition = phrase(relationship(i).rightPhrase).sentencePosition;
                    invalidRelation(i) = rightPosition < relationship(i).sentencePosition;
                end
            end
            
            relationship(invalidRelation) = [];
        end
        
        function relationship = createComplexRelationships(parser,relationship)
        %CREATECOMPLEXRELATIONSHIPS combines pair phrase relationships
        %between the same phrases that occur in sequence with each other
        %(e.g. for the sentence "man jumping over a fence", rather than
        %having (man,jumping,fence) and (man,over,fence) this combines them
        %so it becomes (man,jumping over,fence)
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       relationship - pair phrase relations for the sentence
        %   outputs
        %       relationship - combined pair phrase relations for the
        %                      sentence
            nRelationshipsPrev = 0;
            while nRelationshipsPrev ~= length(relationship)
                nRelationshipsPrev = length(relationship);
                isFound = false;
                for i = 1:length(relationship)
                    for j = i+1:length(relationship)
                        isFound = isRelationInSequence(relationship(i),relationship(j));
                        if isFound
                            sentencePosition = min(relationship(i).sentencePosition,relationship(j).sentencePosition);
                            leftPhrase = relationship(i).leftPhrase;
                            rightPhrase = relationship(i).rightPhrase;
                            if relationship(i).sentencePosition < relationship(j).sentencePosition
                                word = [relationship(i).words;relationship(j).words];
                                pos = [relationship(i).pos;relationship(j).pos];
                            else
                                word = [relationship(j).words;relationship(i).words];
                                pos = [relationship(j).pos;relationship(i).pos];
                            end
                            
                            relationship([i;j]) = [];
                            combinedRelationship = Relationship(word,pos,sentencePosition,leftPhrase,rightPhrase);
                            relationship = [relationship;combinedRelationship];
                            break;
                        end
                    end
                    
                    if isFound
                        break;
                    end
                end
            end
        end

        function relationship = getRelationship(parser,parseTree,leaf,leafIndex,phraseMap)
        %GETRELATIONSHIP returns the pair phrase relationship based on the
        %leaf input of the parseTree
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
        %       leaf - word identifying a relationship (e.g. running in the
        %              relationship (man,running,field)
        %       leafIdx - index of the leaf identifying its position in the
        %                 sentence
        %       phraseMap - array that maps the parseTree leaf indices to
        %                   entity instances
        %   outputs
        %       relationship - pair phrase relation for the leaf input
            leftEntity = parser.getRelationEntity(parseTree,leaf,phraseMap,true);
            rightEntity = parser.getRelationEntity(parseTree,leaf,phraseMap,false);
            if ~isempty(leftEntity) && ~isempty(rightEntity)
                [X,Y] = meshgrid(1:length(leftEntity),1:length(rightEntity));
                leftEntity = leftEntity(X(:));
                rightEntity = rightEntity(Y(:));
                keep = leftEntity < rightEntity;
                leftEntity = leftEntity(keep);
                rightEntity = rightEntity(keep);
            end
            
            nRelations = max(length(leftEntity),length(rightEntity));
            if nRelations == 0
                relationship = [];
                return;
            end
            relationship(nRelations,1) = Relationship;
            pos = {char(leaf.parent(parseTree).label)};
            word = {char(leaf.label)};
            for i = 1:nRelations
                le = [];
                if ~isempty(leftEntity)
                    le = leftEntity(i);
                end
                
                re = [];
                if ~isempty(rightEntity)
                    re = rightEntity(i);
                end
                relationship(i) = Relationship(word,pos,leafIndex,le,re);
            end
            
            filterRelation = false(nRelations,1);
            for i = 1:nRelations
                if length(relationship(i).words) == 1
                    filterRelation(i) = strcmp('.',relationship(i).words);
                    filterRelation(i) = filterRelation(i) || strcmp(',',relationship(i).words);
                    if filterRelation(i),continue,end
                end
                if isempty(relationship(i).leftPhrase),continue,end
                if isempty(relationship(i).rightPhrase),continue,end
                filterRelation(i) = relationship(i).leftPhrase == relationship(i).rightPhrase;
            end
            relationship(filterRelation) = [];
        end

        function entity = getRelationEntity(parser,parseTree,leaf,phraseMap,isLeftEntity)
        %GETRELATIONENTITY returns the entity related to a pair phrase
        %relationship
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
        %       leaf - word identifying a relationship (e.g. running in the
        %              relationship (man,running,field)
        %       phraseMap - array that maps the parseTree leaf indices to
        %                   entity instances
        %       isLeftEntity - indicator of which side of the pair phrase
        %                      relationship the desired entity falls on
        %   outputs
        %       relationship - pair phrase relation for the leaf input
            nJumpsToPhraseNode = 2;
            phraseNode = leaf.ancestor(nJumpsToPhraseNode,parseTree);
            leaf = leaf.ancestor(nJumpsToPhraseNode-1,parseTree);
            entityNP = parser.findClosestNP(parseTree,phraseNode,leaf,isLeftEntity);
            if isempty(entityNP)
                entity = [];
                return;
            end
            treeLeaves = parseTree.getLeaves();
            nEntities = max(phraseMap);
            isSelected = false(nEntities,1);
            for i = 1:nEntities
                npIdx = find(phraseMap == i);
                for j = 1:length(npIdx)
                    npLeaf = treeLeaves.get(npIdx(j)-1);
                    npNode = npLeaf.ancestor(nJumpsToPhraseNode,parseTree);
                    npNodeNumber = npNode.nodeNumber(parseTree);
                    isSelected(i) = npNodeNumber == entityNP;
                    if isSelected(i)
                        break;
                    end
                end
 
            end
           
           entity = find(isSelected);
        end

        function entityIdx = findClosestNP(parser,parseTree,currNode,prevNode,traverseUp)
        %FINDCLOSESTNP returns the leaf index of the first noun phrase
        %found while traversing a parseTree object
        %   inputs
        %       parser - this instance of a StanfordParser object
        %       parseTree - java Tree object, see the documentation for the
        %                   Stanford Parser for information on the object
        %       currNode - current node in the parseTree object
        %       prevNode - previous node considered while traversing the
        %                  parseTree object
        %       traverseUp - indicator of the direction that the next node
        %                    to be considered is in
        %   outputs
        %       entityIdx - location of the noun phrase in the parseTree
            if isempty(currNode)
                entityIdx = [];
                return;
            end
            childNodes = currNode.children();
            if traverseUp
                prevLoc = false(length(childNodes),1);
                prevNumber = prevNode.nodeNumber(parseTree);
                for i = 1:length(childNodes)
                    prevLoc(i) = childNodes(i).nodeNumber(parseTree) == prevNumber;
                end
                prevLoc = find(prevLoc);
                assert(length(prevLoc) == 1);
            else
                prevLoc = length(childNodes)+1;
            end

            if strncmp('QP',currNode.label,2) || strncmp('ADVP',currNode.label,4)
                nextNode = currNode.parent(parseTree);
                if strncmp('NP',nextNode.label,2) || strncmp('ADJP',nextNode.label,4)
                    if traverseUp
                        numToJumpPastNP = 2;
                        nextNode = currNode.ancestor(numToJumpPastNP,parseTree);
                        newPrevNode = currNode.ancestor(numToJumpPastNP-1,parseTree);
                        entityIdx = parser.findClosestNP(parseTree,nextNode,newPrevNode,traverseUp);
                        if ~isempty(entityIdx),return,end
                    else
                        entityIdx = nextNode.nodeNumber(parseTree);
                        return;
                    end
                end
            end

            entityIdx = [];
            rootSubject = 2;
            if strncmp('S',prevNode.label,1) && traverseUp && prevNode.nodeNumber(parseTree) ~= rootSubject
                if prevLoc > 1
                    nextNode = childNodes(1);
                    entityIdx = parser.findClosestNP(parseTree,nextNode,currNode,false);
                    if ~isempty(entityIdx),return,end
                end
            else
                for i = 1:prevLoc-1
                    nextNode = childNodes(i);
                    entityIdx = parser.findClosestNP(parseTree,nextNode,currNode,false);
                    if ~isempty(entityIdx),return,end
                end
            end

            if strncmp('NP',currNode.label,2) || strncmp('ADJP',currNode.label,4)
                entityIdx = currNode.nodeNumber(parseTree);
                return;
            end
            
            if traverseUp
                nextNode = currNode.parent(parseTree);
                entityIdx = parser.findClosestNP(parseTree,nextNode,currNode,traverseUp);
            else
                for i = prevLoc+1:length(childNodes)
                    nextNode = childNodes(i);
                    entityIdx = parser.findClosestNP(parseTree,nextNode,currNode,traverseUp);
                    if ~isempty(entityIdx),return,end
                end
            end
        end
    end
end

