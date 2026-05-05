SET search_path TO goodreads_v2;

-- ============================================
-- TASK A: SELECT, beregnede felter og aliaser
-- ============================================

-- 1. book_id, title og alias pub_year
SELECT id AS book_id, title, year_published AS pub_year
FROM book;

-- 2. Distinkte sideantal
SELECT DISTINCT page_count
FROM book
ORDER BY page_count;
-- DISTINCT fjerner dubletter: hvis 10 bøger alle har 300 sider,
-- vises 300 kun én gang i stedet for 10 gange.

-- 3. Beregnet felt: bogens alder i år
SELECT title, year_published,
       (2026 - year_published) AS age_in_years
FROM book;
-- age_in_years beregner hvor mange år siden bogen blev udgivet


-- ============================================
-- TASK B: FILTERING
-- ============================================

-- 1. Bøger færdiggjort i 2020
SELECT *
FROM book_read
WHERE EXTRACT(YEAR FROM date_finished) = 2020;

-- 2. Titler der starter med 'The'
SELECT title
FROM book
WHERE title LIKE 'The%';

-- 3. Bøger uden ISBN
SELECT id, title
FROM book
WHERE isbn IS NULL;


-- ============================================
-- TASK C: AGGREGATES
-- ============================================

-- Total antal bøger
SELECT COUNT(*) AS total_books
FROM book;

-- Min, max og gennemsnit af page_count
SELECT
    MIN(page_count) AS min_pages,
    MAX(page_count) AS max_pages,
    ROUND(AVG(page_count), 2) AS avg_pages
FROM book;


-- ============================================
-- TASK D: GROUP BY OG HAVING
-- ============================================

-- Single value rule forklaring:
-- Når du bruger GROUP BY, skal alle kolonner i SELECT enten
-- være med i GROUP BY, eller bruges med en aggregatfunktion
-- (COUNT, SUM, AVG, MIN, MAX). En gruppe består af mange rækker,
-- så SQL ved ikke hvilken enkelt værdi den skal vise for en kolonne
-- der ikke er grupperet eller aggregeret.

-- Grupper efter udgivelsesår, tæl bøger, vis gennemsnit
-- Behold kun år med gennemsnitlig sideantal > 100
SELECT
    year_published,
    COUNT(*) AS book_count,
    ROUND(AVG(page_count), 2) AS avg_page_count
FROM book
GROUP BY year_published
HAVING AVG(page_count) > 100
ORDER BY year_published;


-- ============================================
-- TASK E: ORDER BY
-- ============================================

-- Top 10 længste bøger
SELECT id, title, page_count
FROM book
ORDER BY page_count DESC
LIMIT 10;

-- Titler stigende, year_published faldende
SELECT title, year_published
FROM book
ORDER BY title ASC, year_published DESC;


-- ============================================
-- TASK F: JOINS
-- ============================================

-- 1. book id, title og forfatterens fulde navn
SELECT b.id AS book_id, b.title,
       a.first_name || ' ' || a.last_name AS full_name
FROM book b
INNER JOIN author a ON b.author_id = a.id;

-- 2. Alle forfattere med antal bøger
SELECT a.first_name || ' ' || a.last_name AS full_name,
       COUNT(b.id) AS book_count
FROM author a
LEFT JOIN book b ON a.id = b.author_id
GROUP BY a.id, a.first_name, a.last_name
ORDER BY book_count DESC;

-- 3. FULL OUTER JOIN mellem publisher og book:
-- Viser publishers uden bøger (book-kolonner = NULL)
-- og bøger uden en publisher (publisher-kolonner = NULL).
-- Afslører huller i data som en INNER JOIN ville skjule.
SELECT p.id AS publisher_id, p.publisher_name AS publisher_name,
       b.id AS book_id, b.title
FROM publisher p
FULL OUTER JOIN book b ON p.id = b.publisher_id;


-- 4. Inner join forklaring:
-- En INNER JOIN returnerer kun rækker hvor der er match i BEGGE tabeller.
-- En bog uden forfatter og en forfatter uden bøger ville begge blive udeladt.
-- Det er som snitmængden af to sæt.


-- ============================================
-- TASK G: SET OPERATIONS
-- ============================================

-- UNION (fjerner dubletter)
SELECT b.title FROM book b
INNER JOIN book_read br ON b.id = br.book_id
WHERE br.status = 'read'
UNION
SELECT b.title FROM book b
INNER JOIN book_read br ON b.id = br.book_id
WHERE br.status = 'to-read';

-- UNION ALL (beholder dubletter)
SELECT b.title FROM book b
INNER JOIN book_read br ON b.id = br.book_id
WHERE br.status = 'read'
UNION ALL
SELECT b.title FROM book b
INNER JOIN book_read br ON b.id = br.book_id
WHERE br.status = 'to-read';

-- Forskel: UNION fjerner dubletter (en bog der både er 'read' og 'to-read'
-- vises kun én gang). UNION ALL beholder alle rækker inkl. dubletter og er hurtigere.


-- ============================================
-- TASK H: DML EXTENSIONS
-- ============================================

-- Find gyldige foreign key værdier
SELECT MAX(id) + 1 AS new_id FROM book;
SELECT id FROM author LIMIT 3;
SELECT id FROM publisher LIMIT 3;
SELECT id FROM binding_type LIMIT 3;

-- Indsæt ny bog (justér author_id, publisher_id, binding_id efter ovenstående)
INSERT INTO book (id, title, year_published, page_count, isbn, author_id, publisher_id, binding_id)
VALUES (
    (SELECT MAX(id) + 1 FROM book),
    'The New Adventure',
    2023,
    320,
    '9781234567890',
    1,
    1,
    1
);

-- Verificer ny bog
SELECT * FROM book ORDER BY id DESC LIMIT 1;

-- Vis antal rækker der påvirkes (1990-1999)
SELECT COUNT(*) AS rows_to_update
FROM book_read br
JOIN book b ON br.book_id = b.id
WHERE b.year_published BETWEEN 1990 AND 1999;

-- Opdater status til 'classic'
UPDATE book_read
SET status = 'classic'
WHERE book_id IN (
    SELECT id FROM book WHERE year_published BETWEEN 1990 AND 1999
);

-- Verificer opdatering
SELECT br.profile_id, br.book_id, br.status, b.title, b.year_published
FROM book_read br
JOIN book b ON br.book_id = b.id
WHERE b.year_published BETWEEN 1990 AND 1999
LIMIT 10;


-- ============================================
-- TASK I: TRANSACTIONS
-- ============================================

-- Find en book_read række at arbejde med
SELECT profile_id, book_id, status FROM book_read LIMIT 5;

-- TRANSACTION 1: Rollback
BEGIN;
    UPDATE book_read SET status = 'read'
    WHERE profile_id = 1 AND book_id = 35657891;

    -- Bekræft ændringen er synlig i denne session
    SELECT profile_id, book_id, status FROM book_read
    WHERE profile_id = 1 AND book_id = 35657891;

ROLLBACK;

-- Bekræft ændringen er væk
SELECT profile_id, book_id, status FROM book_read
WHERE profile_id = 1 AND book_id = 35657891;

-- TRANSACTION 2: Commit (find en 'to-read' række)
SELECT profile_id, book_id, status FROM book_read WHERE status = 'to-read' LIMIT 1;

BEGIN;
    UPDATE book_read
    SET status = 'read', rating = 4
    WHERE profile_id = 1 AND book_id = 54493401;

    SELECT profile_id, book_id, status, rating FROM book_read
    WHERE profile_id = 1 AND book_id = 54493401;
COMMIT;

-- Verificer at ændringen er gemt permanent
SELECT profile_id, book_id, status, rating FROM book_read
WHERE profile_id = 1 AND book_id = 54493401;

-- TRANSACTION 3: Savepoint
BEGIN;
    UPDATE book_read SET rating = 5
    WHERE profile_id = 1 AND book_id = 35657891;

    SAVEPOINT sp1;

    -- Dette vil fejle (id eksisterer allerede)
    INSERT INTO book (id, title, year_published, page_count, isbn, author_id, publisher_id, binding_id)
    VALUES (1, 'Fejl bog', 2020, 100, '0000000000000', 1, 1, 1);

    -- Kør denne efter fejlen:
    ROLLBACK TO SAVEPOINT sp1;

COMMIT;

-- Verificer: rating=5 er gemt, den fejlende insert skete ikke
SELECT profile_id, book_id, rating FROM book_read
WHERE profile_id = 1 AND book_id = 35657891;




-- ============================================
-- FORKLARINGER TIL ASSIGNMENT 1
-- ============================================

-- TASK A:
-- DISTINCT fjerner dubletter fra resultatet.
-- Uden DISTINCT ville samme sideantal vises flere gange
-- hvis fx 10 bøger alle har 300 sider.
-- Med DISTINCT vises 300 kun én gang.

-- Beregnet felt (age_in_years):
-- Feltet udregner hvor mange år siden en bog blev udgivet
-- ved at trække year_published fra 2026.
-- Eksempel: en bog fra 2018 får age_in_years = 8.

-- TASK D:
-- Single value rule (GROUP BY-reglen):
-- Når du bruger GROUP BY, skal alle kolonner i SELECT enten
-- være med i GROUP BY, eller bruges med en aggregatfunktion
-- (COUNT, SUM, AVG, MIN, MAX).
-- En gruppe består af mange rækker, så SQL ved ikke hvilken
-- enkelt værdi den skal vise for en kolonne der ikke er grupperet.

-- TASK F:
-- FULL OUTER JOIN mellem publisher og book:
-- Viser publishers uden bøger (book-kolonner = NULL)
-- og bøger uden en publisher (publisher-kolonner = NULL).
-- Det afslører huller i data som en INNER JOIN ville skjule.

-- Inner join forklaring:
-- En INNER JOIN returnerer kun rækker hvor der er match i BEGGE tabeller.
-- En bog uden forfatter og en forfatter uden bøger ville begge blive udeladt.
-- Det er som snitmængden af to sæt.

-- TASK G:
-- UNION fjerner dubletter - en bog der optræder i begge sæt vises kun én gang.
-- UNION ALL beholder alle rækker inkl. dubletter og er hurtigere
-- fordi den ikke checker for dubletter.

-- TASK I (Session A/B observation):
-- Session A kørte BEGIN og SELECT ... FOR UPDATE for at låse rækken.
-- Session B forsøgte at UPDATE den samme række. I teorien skulle Session B
-- have blokeret og ventet på at Session A committede, fordi FOR UPDATE
-- sætter en eksklusiv row-level lås i PostgreSQL.
-- I vores test gennemførte Session B uden at vente, hvilket skyldes at
-- DataGrip auto-committede Session A's transaktion efter SELECT.
-- Dette illustrerer at FOR UPDATE kun virker som en blokerende lås
-- så længe BEGIN-transaktionen holdes åben og ikke auto-committes.
