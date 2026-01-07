--------------------------------------------------------------------------------
-- 1장 - SQL 기본
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.2 SELECT 문
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.2.1 SELECT
--------------------------------------------------------------------------------
SELECT player_id, player_name, team_id, position, height, weight, back_no
FROM player;

SELECT ALL position FROM player;

SELECT position FROM player;

SELECT DISTINCT position FROM player;

SELECT * from emp;

SELECT player_name AS 선수명, position AS 위치, height AS 키, weight AS 몸무게
FROM player;

SELECT player_name 선수명, position 위치, height 키, weight 몸무게 FROM player;

SELECT player_name AS "선수 명", position AS 포지션, height AS 키, weight AS 몸무게
FROM player;
--------------------------------------------------------------------------------
-- 1.2.2 산술 연산자와 합성 연산자
--------------------------------------------------------------------------------
