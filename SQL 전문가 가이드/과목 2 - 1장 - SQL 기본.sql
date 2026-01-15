--------------------------------------------------------------------------------
-- 과목 II - 1장 - SQL 기본
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.2 SELECT 문
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.2.1 SELECT
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
-- 2.1.2.2 산술 연산자와 합성 연산자
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, height-weight AS "키-몸무게" FROM player;

SELECT player_name AS 선수명,
       ROUND (weight / ((height/100) * (height/100)), 2) AS BMI비만지수
FROM player;

SELECT player_name || ' 선수, ' || height || ' cm, ' || weight || ' kg'
       AS 체격정보 FROM player;
--------------------------------------------------------------------------------
-- 2.1.3 함수
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.3.2 문자형 함수
--------------------------------------------------------------------------------
SELECT LOWER('SQL Expert') col1, UPPER('SQL Expert') col2, ASCII('A') col3,
       CHR(65) col4, CONCAT('RDBMS', ' SQL') col5,
       SUBSTR('SQL Expert', 5, 3) col6, LENGTH('SQL Expert') col7,
       LTRIM('xxxYYZZxYZ', 'x') col8, RTRIM('XXYYzzXYzz', 'z') col9,
       RTRIM('XXYYZZXYZ     ') col10, TRIM('x' FROM 'xxYYZZxYZxx') col11
FROM dual;

SELECT LENGTH('SQL Expert') AS len FROM dual;

-- DESC dual;

SELECT * FROM dual;

SELECT CONCAT(player_name, ' 축구선수') AS 선수명 FROM player;
SELECT player_name || ' 축구선수' AS 선수명 FROM player;

SELECT stadium_id, ddd || ')' || tel AS tel, LENGTH(ddd || '-' || tel) AS t_len
FROM stadium;
--------------------------------------------------------------------------------
-- 2.1.3.3 숫자형 함수
--------------------------------------------------------------------------------
SELECT ABS(-15) AS col1, SIGN(-20) AS col2, SIGN(0) AS col3, SIGN(+20) AS col4,
       MOD(7, 3) AS col5, CEIL(38.123) AS col6, FLOOR(38.123) AS col7,
       ROUND(38.5235, 3) AS col8, ROUND(38.5235, 1) AS col9,
       ROUND(38.5235, 0) AS col10, ROUND(38.5235) col11,
       TRUNC(38.5235, 3) AS col12, TRUNC(38.5235, 1) AS col13,
       TRUNC(38.5235, 0) AS col14, TRUNC(38.5235) AS col15,
       SIN(0) AS col16, COS(0) AS col17, TAN(0) AS col18,
       EXP(2) AS col19, POWER(2, 3) AS col20, SQRT(4) AS col21,
       LOG(10, 100) AS col22, LN(7.3890561) AS col23
FROM dual;

SELECT ename, ROUND(sal / 12, 1) AS sal_round, TRUNC(sal / 12, 1) AS sal_trunc
FROM emp;

SELECT ename, ROUND(sal / 12) AS sal_round, CEIL(sal / 12) AS sal_ceil
FROM emp;
--------------------------------------------------------------------------------
-- 2.1.3.4 날짜형 함수
--------------------------------------------------------------------------------
SELECT SYSDATE FROM dual;

SELECT ename AS 사원명, hiredate AS 입사일자,
       EXTRACT(YEAR FROM hiredate) AS 입사년도,
       EXTRACT(MONTH FROM hiredate) AS 입사월,
       EXTRACT(DAY FROM hiredate) AS 입사일
FROM emp;

SELECT ename AS 사원명, hiredate AS 입사일자,
       TO_NUMBER(TO_CHAR(hiredate, 'YYYY')) AS 입사년도,
       TO_NUMBER(TO_CHAR(hiredate, 'MM')) AS 입사월,
       TO_NUMBER(TO_CHAR(hiredate, 'DD')) AS 입사일
FROM emp;
--------------------------------------------------------------------------------
-- 2.1.3.5 변환형 함수
--------------------------------------------------------------------------------
SELECT TO_CHAR(SYSDATE, 'YYYY/MM/DD') AS 날짜,
       TO_CHAR(SYSDATE, 'YYYY. MON, DAY') AS 문자형
FROM dual;

SELECT TO_CHAR(123456789/1200, '$999,999,999.99') AS 환율반영달러,
       TO_CHAR(123456789, 'L999,999,999') AS 원화
FROM dual;

SELECT team_id AS 팀ID,
       TO_NUMBER(zip_code1, '999') + TO_NUMBER(zip_code2, '999') AS 우편번호합
FROM team;
--------------------------------------------------------------------------------
-- 2.1.3.6 CASE 표현
--------------------------------------------------------------------------------
SELECT ename,
       CASE WHEN sal > 2000 THEN sal ELSE 2000 END AS revised_salary
FROM emp;

SELECT loc, CASE loc WHEN 'NEW YORK' THEN 'EAST'
                WHEN 'BOSTON' THEN 'EAST'
                WHEN 'CHICAGO' THEN 'CENTER'
                WHEN 'DALLAS' THEN 'CENTER'
                ELSE 'ETC'
            END AS area
FROM dept;

SELECT ename, CASE WHEN sal >= 3000 THEN 'HIGH'
                   WHEN sal >= 1000 THEN 'MID'
                   ELSE 'LOW'
              END AS salary_grade
FROM emp;

SELECT ename, sal, CASE WHEN sal >= 2000 THEN 1000
                        ELSE (CASE WHEN sal >= 1000 THEN 500 ELSE 0 END)
                   END AS bonus
FROM emp;
--------------------------------------------------------------------------------
-- 2.1.3.7 NULL 관련 함수
--------------------------------------------------------------------------------
SELECT NVL(NULL, 'NVL-OK') AS nvl_test1, NVL('Not-Null', 'NVL-OK') AS nvl_test2
FROM dual;

SELECT player_name AS 선수명, position AS 포지션, NVL(position, '없음') AS NL포지션
FROM player WHERE team_id = 'K08';

SELECT player_name AS 선수명, position AS 포지션,
       CASE WHEN position IS NULL THEN '없음'
            ELSE position
       END AS NL포지션
FROM player WHERE team_id = 'K08';

SELECT ename AS 선수명, sal AS 월급, comm AS 커미션,
       (sal * 12) + comm AS 연봉A, (sal * 12) + NVL(comm, 0) AS 연봉B
FROM emp;

SELECT mgr FROM emp WHERE ename = 'SCOTT';

SELECT mgr FROM emp WHERE ename = 'KING';

SELECT NVL(mgr, 9999) AS mgr FROM emp WHERE ename = 'KING';

SELECT mgr FROM emp WHERE ename = 'JSC';

SELECT NVL(mgr, 9999) AS mgr FROM emp WHERE ename = 'JSC';

SELECT MAX(mgr) AS mgr FROM emp WHERE ename = 'JSC';

SELECT NVL(MAX(mgr), 9999) AS mgr FROM emp WHERE ename = 'JSC';

SELECT ename, empno, mgr, NULLIF(mgr, 7698) AS nuif FROM emp;

SELECT ename, empno, mgr, CASE WHEN mgr = 7698 THEN NULL ELSE mgr END AS nuif
FROM emp;

SELECT ename, comm, sal, COALESCE(comm, sal) AS coal FROM emp;

SELECT ename, comm, sal, CASE WHEN comm IS NOT NULL THEN comm
                              ELSE (CASE WHEN sal IS NOT NULL THEN sal
                                         ELSE NULL END)
                         END AS coal FROM emp;
--------------------------------------------------------------------------------
-- 2.1.4 WHERE 절
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.4.3 비교 연산자
--------------------------------------------------------------------------------
-- ORA-00904: "K02": 부적합한 식별자
-- SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
-- FROM player WHERE team_id = K02;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02';

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE position = 'MF';

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE height >= '170';
--------------------------------------------------------------------------------
-- 2.1.4.4 SQL 연산자
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id IN ('K02', 'K07');

SELECT ename, job, deptno FROM emp
WHERE (job, deptno) IN (('MANAGER', 20), ('CLERK', 30));

SELECT ename, job, deptno FROM emp
WHERE job IN ('MANAGER', 'CLERK') AND deptno IN (20, 30);

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE position LIKE 'MF';

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE player_name LIKE '장%';

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE player_name LIKE '장_호';

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE height BETWEEN 170 AND 180;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE position = NULL;

SELECT player_name AS 선수명, position AS 포지션, team_id AS 팀ID
FROM player WHERE position IS NULL;
--------------------------------------------------------------------------------
-- 2.1.4.5 논리 연산자
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' AND height >= 170;

SELECT team_id AS 팀ID, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id IN ('K02', 'K07') AND position = 'MF';

SELECT team_id AS 팀ID, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' OR team_id = 'K07' AND position = 'MF'
                  AND height >= 170 AND height <= 180;

SELECT team_id AS 팀ID, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE (team_id = 'K02' OR team_id = 'K07') AND position = 'MF'
                  AND height >= 170 AND height <= 180;

SELECT team_id AS 팀ID, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id IN ('K02', 'K07') AND position = 'MF'
                  AND height BETWEEN 170 AND 180;
--------------------------------------------------------------------------------
-- 2.1.4.6 부정 연산자
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' AND NOT position = 'MF'
                  AND NOT height BETWEEN 175 AND 185;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' AND position <> 'MF'
                  AND height NOT BETWEEN 175 AND 185;

SELECT player_name AS 선수명, nation AS 국적 FROM player
WHERE nation IS NOT NULL;
--------------------------------------------------------------------------------
-- 2.1.5 GROUP BY, HAVING 절
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.5.1 집계함수
--------------------------------------------------------------------------------
SELECT COUNT(*) AS 전체행수, COUNT(height) AS 키건수, MAX(height) AS 최대키,
       MIN(height) AS 최소키, ROUND(AVG(height), 2) AS 평균키
FROM player
WHERE height > 160;
--------------------------------------------------------------------------------
-- 2.1.5.2 GROUP BY 절
--------------------------------------------------------------------------------
-- ORA-00937: 단일 그룹의 그룹 함수가 아닙니다
-- SELECT position AS 포지션, AVG(height) AS 평균키 FROM player;
-- ORA-00904: "포지션": 부적합한 식별자
-- SELECT position AS 포지션, AVG(height) AS 평균키 FROM player GROUP BY 포지션;

SELECT position AS 포지션, COUNT(*) AS 인원수, COUNT(height) AS 키대상,
       MAX(height) AS 최대키, MIN(height) AS 최소키,
       ROUND(AVG(height), 2) AS 평균키
FROM player GROUP BY position;
--------------------------------------------------------------------------------
-- 2.1.5.3 HAVING 절
--------------------------------------------------------------------------------
-- ORA-00934: 그룹 함수는 허가되지 않습니다
-- SELECT position AS 포지션, ROUND(AVG(height), 2) AS 평균키 FROM player
-- WHERE AVG(height) >= 180 GROUP BY position;

SELECT position AS 포지션, ROUND(AVG(height), 2) AS 평균키 FROM player
GROUP BY position HAVING AVG(height) >= 180;

SELECT position AS 포지션, AVG(height) AS 평균키 FROM player
HAVING AVG(height) >= 180 GROUP BY position;

SELECT team_id AS 팀ID, COUNT(*) AS 인원수 FROM player
WHERE team_id IN ('K09', 'K02') GROUP BY team_id;

SELECT team_id AS 팀ID, COUNT(*) AS 인원수 FROM player
GROUP BY team_id HAVING team_id IN ('K09', 'K02');

SELECT position AS 포지션, ROUND(AVG(height), 2) AS 평균키
FROM player GROUP BY position HAVING max(height) >= 190;
--------------------------------------------------------------------------------
-- 2.1.5.4 CASE 표현을 활용한 월별 데이터 집계
--------------------------------------------------------------------------------
SELECT ename AS 사원명, deptno AS 부서번호,
       EXTRACT(MONTH FROM hiredate) AS 입사월, sal AS 급여
FROM emp;

SELECT ename AS 사원명, deptno AS 부서번호,
       CASE month WHEN 1 THEN sal END AS m01,
       CASE month WHEN 2 THEN sal END AS m02,
       CASE month WHEN 3 THEN sal END AS m03,
       CASE month WHEN 4 THEN sal END AS m04,
       CASE month WHEN 5 THEN sal END AS m05,
       CASE month WHEN 6 THEN sal END AS m06,
       CASE month WHEN 7 THEN sal END AS m07,
       CASE month WHEN 8 THEN sal END AS m08,
       CASE month WHEN 9 THEN sal END AS m09,
       CASE month WHEN 10 THEN sal END AS m10,
       CASE month WHEN 11 THEN sal END AS m11,
       CASE month WHEN 12 THEN sal END AS m12
FROM (SELECT ename, deptno, EXTRACT(MONTH FROM hiredate) AS month, sal
      FROM emp);

SELECT deptno AS 부서번호,
       AVG(CASE month WHEN 1 THEN sal END) AS m01,
       AVG(CASE month WHEN 2 THEN sal END) AS m02,
       AVG(CASE month WHEN 3 THEN sal END) AS m03,
       AVG(CASE month WHEN 4 THEN sal END) AS m04,
       AVG(CASE month WHEN 5 THEN sal END) AS m05,
       AVG(CASE month WHEN 6 THEN sal END) AS m06,
       AVG(CASE month WHEN 7 THEN sal END) AS m07,
       AVG(CASE month WHEN 8 THEN sal END) AS m08,
       AVG(CASE month WHEN 9 THEN sal END) AS m09,
       AVG(CASE month WHEN 10 THEN sal END) AS m10,
       AVG(CASE month WHEN 11 THEN sal END) AS m11,
       AVG(CASE month WHEN 12 THEN sal END) AS m12
FROM (SELECT ename, deptno, EXTRACT(MONTH FROM hiredate) AS month, sal
      FROM emp)
GROUP BY deptno;

SELECT deptno AS 부서번호,
       AVG(DECODE(month, 1, sal)) AS m01,
       AVG(DECODE(month, 2, sal)) AS m02,
       AVG(DECODE(month, 3, sal)) AS m03,
       AVG(DECODE(month, 4, sal)) AS m04,
       AVG(DECODE(month, 5, sal)) AS m05,
       AVG(DECODE(month, 6, sal)) AS m06,
       AVG(DECODE(month, 7, sal)) AS m07,
       AVG(DECODE(month, 8, sal)) AS m08,
       AVG(DECODE(month, 9, sal)) AS m09,
       AVG(DECODE(month, 10, sal)) AS m10,
       AVG(DECODE(month, 11, sal)) AS m11,
       AVG(DECODE(month, 12, sal)) AS m12
FROM (SELECT ename, deptno, EXTRACT(MONTH FROM hiredate) AS month, sal
      FROM emp)
GROUP BY deptno;
--------------------------------------------------------------------------------
-- 2.1.5.5 집계함수와 NULL 처리
--------------------------------------------------------------------------------
SELECT team_id,
       NVL(SUM(CASE position WHEN 'FW' THEN 1 ELSE 0 END), 0) AS fw,
       NVL(SUM(CASE position WHEN 'MF' THEN 1 ELSE 0 END), 0) AS mf,
       NVL(SUM(CASE position WHEN 'DF' THEN 1 ELSE 0 END), 0) AS df,
       NVL(SUM(CASE position WHEN 'GK' THEN 1 ELSE 0 END), 0) AS gk,
       COUNT(*) AS sum
FROM player GROUP BY team_id;

SELECT team_id,
       NVL(SUM(CASE position WHEN 'FW' THEN 1 END), 0) AS fw,
       NVL(SUM(CASE position WHEN 'MF' THEN 1 END), 0) AS mf,
       NVL(SUM(CASE position WHEN 'DF' THEN 1 END), 0) AS df,
       NVL(SUM(CASE position WHEN 'GK' THEN 1 END), 0) AS gk,
       COUNT(*) AS sum
FROM player GROUP BY team_id;

SELECT team_id,
       NVL(SUM(CASE WHEN position = 'FW' THEN 1 END), 0) AS fw,
       NVL(SUM(CASE WHEN position = 'MF' THEN 1 END), 0) AS mf,
       NVL(SUM(CASE WHEN position = 'DF' THEN 1 END), 0) AS df,
       NVL(SUM(CASE WHEN position = 'GK' THEN 1 END), 0) AS gk,
       COUNT(*) AS sum
FROM player GROUP BY team_id;

SELECT ROUND(AVG(CASE WHEN position = 'MF' THEN height END), 2) AS 미드필더,
       ROUND(AVG(CASE WHEN position = 'FW' THEN height END), 2) AS 포워드,
       ROUND(AVG(CASE WHEN position = 'DF' THEN height END), 2) AS 디펜더,
       ROUND(AVG(CASE WHEN position = 'GK' THEN height END), 2) AS 골키퍼,
       ROUND(AVG(height), 2) 전체평균키
FROM player;
--------------------------------------------------------------------------------
-- 2.1.6 ORDER BY 절
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.6.1 ORDER BY 정렬
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버
FROM player ORDER BY player_name DESC;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버
FROM player ORDER BY 포지션 DESC;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE height IS NOT NULL ORDER BY height DESC, back_no;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버
FROM player WHERE back_no IS NOT NULL ORDER BY 3 DESC, 2, 1;

SELECT dname, loc, deptno FROM dept ORDER BY dname, loc, deptno DESC;

SELECT dname AS dept, loc AS area, deptno FROM dept
ORDER BY dname, area, deptno DESC;

SELECT dname, loc AS area, deptno FROM dept ORDER BY 1, area, 3 DESC;
--------------------------------------------------------------------------------
-- 2.1.6.2 SELECT 문장 실행 순서
--------------------------------------------------------------------------------
SELECT empno, ename FROM emp ORDER BY mgr;

SELECT empno FROM (SELECT empno, ename FROM emp ORDER BY mgr);

-- ORA-00904: "MGR": 부적합한 식별자
-- SELECT mgr FROM (SELECT empno, ename FROM emp ORDER BY mgr);

-- ORA-00979: GROUP BY 표현식이 아닙니다.
-- SELECT job, sal FROM emp GROUP BY job HAVING COUNT(*) > 0 ORDER BY sal;

-- ORA-00979: GROUP BY 표현식이 아닙니다.
-- SELECT job FROM emp GROUP BY job HAVING COUNT(*) > 0 ORDER BY sal;

SELECT job, SUM(sal) AS salary_sum FROM emp
GROUP BY job HAVING SUM(sal) > 5000 ORDER BY SUM(sal);
--------------------------------------------------------------------------------
-- 2.1.7 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.7.2 EQUI JOIN
--------------------------------------------------------------------------------
SELECT player.player_name AS 선수명, team.team_name AS 소속팀명
FROM player, team
WHERE team.team_id = player.team_id;

SELECT player.player_name AS 선수명, team.team_name AS 소속팀명
FROM player INNER JOIN team ON team.team_id = player.team_id;

SELECT player.player_name, player.back_no, player.team_id,
       team.team_name, team.region_name
FROM player, team WHERE team.team_id = player.team_id;

SELECT a.player_name AS 선수명, a.back_no AS 백넘버, a.team_id AS 팀코드,
       b.team_name AS 팀명, b.region_name AS 연고지
FROM player a, team b WHERE b.team_id = a.team_id;

SELECT a.player_name AS 선수명, a.back_no AS 백넘버,
       b.region_name AS 연고지, b.team_name AS 팀명
FROM player a, team b WHERE a.position = 'GK' AND b.team_id = a.team_id
ORDER BY a.back_no;

-- ORA-00904: "PLAYER"."PLAYER_NAME": 부적합한 식별자
-- SELECT player.player_name AS 선수명, a.back_no AS 백넘버,
--        b.region_name AS 연고지, b.team_name AS 팀명
-- FROM player a, team b WHERE a.position = 'GK' AND b.team_id = a.team_id
-- ORDER BY a.back_no;

SELECT team.region_name, team.team_name, team.stadium_id,
       stadium.stadium_name, stadium.seat_count
FROM team, stadium WHERE stadium.stadium_id = team.stadium_id;

SELECT a.region_name, a.team_name, a.stadium_id,
       b.stadium_name, b.seat_count
FROM team a, stadium b WHERE b.stadium_id = a.stadium_id;

SELECT region_name, team_name, a.stadium_id, stadium_name, seat_count
FROM team a, stadium b WHERE b.stadium_id = a.stadium_id;
--------------------------------------------------------------------------------
-- 2.1.7.3 Non EQUI JOIN
--------------------------------------------------------------------------------
CREATE TABLE salgrade (
    grade NUMBER PRIMARY KEY,
    losal NUMBER NOT NULL CHECK (0 <= losal AND losal <= 9999),
    hisal NUMBER NOT NULL CHECK (0 <= hisal AND hisal <= 9999),
    CHECK (losal <= hisal)
);

INSERT INTO salgrade VALUES (1, 700, 1200);
INSERT INTO salgrade VALUES (2, 1201, 1400);
INSERT INTO salgrade VALUES (3, 1401, 2000);
INSERT INTO salgrade VALUES (4, 2001, 3000);
INSERT INTO salgrade VALUES (5, 3001, 9999);

SELECT a.ename, a.job, a.sal, b.grade
FROM emp a, salgrade b WHERE a.sal BETWEEN b.losal AND b.hisal;

SELECT a.ename AS 사원명, a.sal AS 급여, b.grade AS 급여등급
FROM emp a, salgrade b WHERE a.sal BETWEEN b.losal AND b.hisal;

DROP TABLE salgrade;
--------------------------------------------------------------------------------
-- 2.1.7.4 3개 이상 TABLE JOIN
--------------------------------------------------------------------------------
SELECT a.player_name AS 선수명, a.position AS 포지션,
       b.region_name AS 연고지, b.team_name AS 팀명,
       c.stadium_name AS 구장명
FROM player a, team b, stadium c
WHERE b.team_id = a.team_id AND c.stadium_id = b.stadium_id
ORDER BY 선수명;
--------------------------------------------------------------------------------
-- 2.1.7.5 OUTER JOIN
--------------------------------------------------------------------------------
SELECT a.stadium_name, a.stadium_id, a.seat_count, a.hometeam_id, b.team_name
FROM stadium a, team b WHERE b.team_id(+) = a.hometeam_id
ORDER BY a.hometeam_id;

SELECT a.ename, a.deptno, b.dname, b.loc
FROM emp a, dept b WHERE b.deptno = a.deptno(+);
--------------------------------------------------------------------------------
-- 2.1.8 표준 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.8.2 INNER JOIN
--------------------------------------------------------------------------------
SELECT a.empno, a.ename, b.deptno, b.dname FROM emp a, dept b
WHERE b.deptno = a.deptno;

SELECT a.empno, a.ename, b.deptno, b.dname
FROM emp a INNER JOIN dept b ON b.deptno = a.deptno;

SELECT a.empno, a.ename, b.deptno, b.dname
FROM emp a JOIN dept b ON b.deptno = a.deptno;
--------------------------------------------------------------------------------
-- 2.1.8.3 NATURAL JOIN
--------------------------------------------------------------------------------
SELECT a.empno, a.ename, deptno, b.dname
FROM emp a NATURAL JOIN dept b;

-- ORA-25155: NATURAL 조인에 사용된 열은 식별자를 가질 수 없음
-- SELECT a.empno, a.ename, b.deptno, b.dname
-- FROM emp a NATURAL JOIN dept b;

SELECT * FROM emp a NATURAL JOIN dept b;

SELECT * FROM emp a INNER JOIN dept b ON b.deptno = a.deptno;

CREATE TABLE dept_temp AS SELECT * FROM dept;

UPDATE dept_temp SET dname = 'CONSULTING' WHERE dname = 'RESEARCH';
UPDATE dept_temp SET dname = 'MARKETING' WHERE dname = 'SALES';

SELECT * FROM dept_temp;

SELECT * FROM dept a NATURAL INNER JOIN dept_temp b;

SELECT * FROM dept a NATURAL JOIN dept_temp b;

SELECT * FROM dept a JOIN dept_temp b
    ON b.deptno = a.deptno AND b.dname = a.dname AND b.loc = a.loc;
--------------------------------------------------------------------------------
-- 2.1.8.4 USING 조건절
--------------------------------------------------------------------------------
SELECT * FROM dept a JOIN dept_temp b USING (deptno);

-- 	ORA-25154: USING 절의 열 부분은 식별자를 가질 수 없음
-- SELECT a.deptno, a.dname, a.loc, b.dname, b.loc
-- FROM dept a JOIN dept_temp b USING (deptno);

SELECT deptno, a.dname, a.loc, b.dname, b.loc
FROM dept a JOIN dept_temp b USING (deptno);

SELECT * FROM dept a JOIN dept_temp b USING (dname);

SELECT * FROM dept a JOIN dept_temp b USING (loc, deptno);

SELECT * FROM dept a JOIN dept_temp b USING (deptno, dname);
--------------------------------------------------------------------------------
-- 2.1.8.5 ON 조건절
--------------------------------------------------------------------------------
SELECT a.empno, a.ename, b.deptno, b.dname
FROM emp a JOIN dept b ON (b.deptno = a.deptno);

SELECT a.ename, a.deptno, b.deptno, b.dname
FROM emp a JOIN dept b ON b.deptno = a.deptno WHERE b.deptno = 30;

SELECT a.ename, a.mgr, a.deptno, b.dname
FROM emp a JOIN dept b ON b.deptno = a.deptno AND a.mgr = 7698;

SELECT a.ename, a.mgr, a.deptno, b.dname
FROM emp a JOIN dept b ON b.deptno = a.deptno WHERE a.mgr = 7698;

SELECT a.team_name, a.stadium_id, b.stadium_name
FROM team a JOIN stadium b ON b.stadium_id = a.stadium_id
ORDER BY a.stadium_id;

SELECT a.team_name, stadium_id, b.stadium_name
FROM team a JOIN stadium b USING (stadium_id)
ORDER BY stadium_id;

SELECT a.team_name, a.team_id, b.stadium_name
FROM team a JOIN stadium b ON b.hometeam_id = a.team_id
ORDER BY a.team_id;

SELECT a.empno, a.deptno, b.dname, c.dname AS new_dname
FROM emp a JOIN dept b ON b.deptno = a.deptno
           JOIN dept_temp c ON c.deptno = b.deptno;

SELECT a.empno, a.deptno, b.dname, c.dname AS new_dname
FROM emp a, dept b, dept_temp c
WHERE b.deptno = a.deptno AND c.deptno = b.deptno;

SELECT a.player_name AS 선수명, a.position AS 포지션,
       b.region_name AS 연고지명, b.team_name AS 팀명,
       c.stadium_name AS 구장명
FROM player a JOIN team b ON b.team_id = a.team_id
              JOIN stadium c ON c.stadium_id = b.stadium_id
WHERE a.position = 'GK' ORDER BY 선수명;

SELECT a.player_name AS 선수명, a.position AS 포지션,
       b.region_name AS 연고지명, b.team_name AS 팀명,
       c.stadium_name AS 구장명
FROM player a, team b, stadium c
WHERE a.position = 'GK' AND b.team_id = a.team_id
                        AND c.stadium_id = b.stadium_id;

SELECT b.stadium_name, b.stadium_id, a.sche_date, c.team_name, d.team_name,
       a.home_score, a.away_score
FROM schedule a JOIN stadium b ON b.stadium_id = a.stadium_id
                JOIN team c ON c.team_id = a.hometeam_id
                JOIN team d ON d.team_id = a.awayteam_id
WHERE a.home_score >= a.away_score + 3;

SELECT b.stadium_name, b.stadium_id, a.sche_date, c.team_name, d.team_name,
       a.home_score, a.away_score
FROM schedule a, stadium b, team c, team d
WHERE a.home_score >= a.away_score + 3 AND b.stadium_id = a.stadium_id
    AND c.team_id = a.hometeam_id AND d.team_id = a.awayteam_id;
--------------------------------------------------------------------------------
-- 2.1.8.6 CROSS JOIN
--------------------------------------------------------------------------------
SELECT a.ename, b.dname FROM emp a CROSS JOIN dept b ORDER BY a.ename;

SELECT a.ename, b.dname FROM emp a CROSS JOIN dept b
WHERE b.deptno = a.deptno;

SELECT a.ename, b.dname FROM emp a INNER JOIN dept b ON b.deptno = a.deptno;
--------------------------------------------------------------------------------
-- 2.1.8.7 OUTER JOIN
--------------------------------------------------------------------------------
SELECT a.stadium_name, a.stadium_id, a.seat_count, a.hometeam_id,
       b.team_name
FROM stadium a LEFT OUTER JOIN team b ON b.team_id = a.hometeam_id
ORDER BY a.hometeam_id;

SELECT a.stadium_name, a.stadium_id, a.seat_count, a.hometeam_id,
       b.team_name
FROM stadium a LEFT JOIN team b ON b.team_id = a.hometeam_id
ORDER BY a.hometeam_id;

SELECT a.ename, b.deptno, b.dname, b.loc
FROM emp a RIGHT OUTER JOIN dept b ON b.deptno = a.deptno;

SELECT a.ename, b.deptno, b.dname, b.loc
FROM emp a RIGHT JOIN dept b ON b.deptno = a.deptno;

UPDATE dept_temp SET deptno = deptno + 20;

SELECT * FROM dept_temp;

SELECT * FROM dept a FULL OUTER JOIN dept_temp b ON b.deptno = a.deptno;

SELECT * FROM dept a FULL JOIN dept_temp b ON b.deptno = a.deptno;

DROP TABLE dept_temp;