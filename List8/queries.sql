--PART 1

--1
CREATE TABLE CYTATY AS
SELECT *
FROM ZSBD_TOOLS.CYTATY;

--2
SELECT *
FROM CYTATY
WHERE lower(TEKST) LIKE '%pesymista%'
  AND TEKST LIKE '%optymista%';

--3
CREATE INDEX CYTATY_IDX ON CYTATY (TEKST)
    indextype is CTXSYS.CONTEXT;

--4
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'optymista & pesymista') > 0;

--5
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'pesymista ~ optymista') > 0;

--6
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'near((pesymista, optymista), 3)') > 0;

--7
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'near((pesymista, optymista), 10)') > 0;

--8
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, '$życi%') > 0;

--9
SELECT AUTOR, TEKST, SCORE(1)
FROM CYTATY
WHERE CONTAINS(TEKST, '$życi%', 1) > 0;

--10
SELECT AUTOR, TEKST, SCORE(1)
FROM CYTATY
WHERE CONTAINS(TEKST, '$życi%', 1) > 0
  and rownum = 1
ORDER BY SCORE(1)
;

--11
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, '!probelm') > 0;

SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'fuzzy(probelm, 60, 6, weight)') > 0;

--12
INSERT INTO CYTATY (ID, AUTOR, TEKST)
VALUES (39, ' Bertrand Russell', 'To smutne, że głupcy są tacy pewni
siebie, a ludzie rozsądni tacy pełni wątpliwości');

COMMIT;

--13
SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'głupcy') > 0;

--indeks prawdopodobnie nie zostal nalozony

--14
SELECT *
FROM DR$CYTATY_IDX$I;

--nie ma slowa glupcy

--15
DROP INDEX CYTATY_IDX;

CREATE INDEX CYTATY_IDX ON CYTATY (TEKST)
    indextype is CTXSYS.CONTEXT;

--16
SELECT *
FROM DR$CYTATY_IDX$I;

--slowo glupcy pojawilo sie

SELECT *
FROM CYTATY
WHERE CONTAINS(TEKST, 'głupcy') > 0;

--17
DROP INDEX CYTATY_IDX;
DROP TABLE CYTATY;


--PART 2

--1
CREATE TABLE QUOTES AS
SELECT *
FROM ZSBD_TOOLS.QUOTES;

--2
CREATE INDEX QUOTES_IDX ON QUOTES (TEXT)
    indextype is CTXSYS.CONTEXT;

--3
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'work') > 0;

SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, '$work') > 0;

SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'working') > 0;

SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, '$working') > 0;

--4
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'it') > 0;

--słowo nie podlega indeksacji

--5
SELECT *
FROM CTX_STOPLISTS;

--no pewnie default

--6
SELECT *
FROM CTX_STOPWORDS;

--7
DROP INDEX QUOTES_IDX;

CREATE INDEX QUOTES_IDX ON QUOTES (TEXT)
    indextype is CTXSYS.CONTEXT
    parameters ( 'stoplist CTXSYS.EMPTY_STOPLIST' );

--8
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'it') > 0;
--aye mamy to

--9
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'fool & humans') > 0;


--10
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'fool & computer') > 0;

--11
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, '(fool & humans) within SENTENCE') > 0;

--12
DROP INDEX QUOTES_IDX;

--13
begin
 ctx_ddl.create_section_group('nullgroup', 'NULL_SECTION_GROUP');
 ctx_ddl.add_special_section('nullgroup', 'SENTENCE');
 ctx_ddl.add_special_section('nullgroup', 'PARAGRAPH');
end;

--14
CREATE INDEX QUOTES_IDX ON QUOTES (TEXT)
    indextype is CTXSYS.CONTEXT
parameters ( 'section group nullgroup' );

--15
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, '(fool & humans) within SENTENCE') > 0;

SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, '(fool & computer) within SENTENCE') > 0;--teraz dziala

--16
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'humans') > 0;--myslnik nie nalezy do indeksowanych tokenow

--17
DROP INDEX QUOTES_IDX;

begin
 ctx_ddl.create_preference('lex_z_m','BASIC_LEXER');
 ctx_ddl.set_attribute('lex_z_m',
 'printjoins', '_-');
 ctx_ddl.set_attribute ('lex_z_m',
 'index_text', 'YES');
end;
CREATE INDEX QUOTES_IDX ON QUOTES (TEXT)
    indextype is CTXSYS.CONTEXT
parameters ( 'section group nullgroup LEXER lex_z_m' );

--18
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'humans') > 0; --teraz nie mamy non-humans

--19
SELECT *
FROM QUOTES
WHERE CONTAINS(TEXT, 'non\-humans') > 0;

--20
begin
    ctx_ddl.drop_preference('lex_z_m');
end;

DROP INDEX QUOTES_IDX;

DROP TABLE QUOTES;