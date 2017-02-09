function str = removePunctuation(str)
    keepCharacters = false(length(str),1);
    spacechar = '\s';
    keepCharacters(regexp(str,spacechar)) = true;
    
    captialLetters = '[A-Z]';
    keepCharacters(regexp(str,captialLetters)) = true;
    
    letters = '[a-z]';
    keepCharacters(regexp(str,letters)) = true;
    
    numbers = '[0-9]';
    keepCharacters(regexp(str,numbers)) = true;
    
    str = str(keepCharacters);
end