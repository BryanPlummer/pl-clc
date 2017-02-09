function N = parseTreeStringCompareN(leaf,word,N)
    leaf = char(leaf);
    word = strrep(word(N+1:end),char(8217),'''');
    isSame = strncmp(leaf,word,length(leaf));
   
    if isSame
        N = N + length(leaf);
        return
    end
    
    isSame = strcmp('''''',leaf) && strcmp('"',word);
    isSame = or(isSame,strcmp('`',leaf) && strncmp('''',word,1));
    isSame = or(isSame,strcmp('.',leaf) && strncmp('.',word,1));
    isSame = or(isSame,strcmp('``',leaf) && strncmp('"',word,1));
    isSame = or(isSame,strcmp('''''',leaf) && strcmp(char(8221),word));
    isSame = or(isSame,strcmp('-LRB-',leaf) && strcmp('(',word));
    isSame = or(isSame,strcmp('-RRB-',leaf) && strcmp(')',word));
    if isSame
        N = N + 1;
    else
        N = [];
    end
end

