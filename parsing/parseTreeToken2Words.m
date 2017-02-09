function words = parseTreeToken2Words(words)
    words = cellfun(@tokenReplacement,words,'UniformOutput',false);
end

function word = tokenReplacement(word)
    word = strrep(word,char(8217),'''');
    word = strrep(word,'''''','"');
    word = strrep(word,'`','''');
    word = strrep(word,'.','.');
    word = strrep(word,'``','"');
    word = strrep(word,'-LRB-','(');
    word = strrep(word,'-RRB-',')');
end

