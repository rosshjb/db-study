--------------------------------------------------------------------------------
-- 1장 - SQL 처리 과정과 IO
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.1 SQL 파싱과 최적화
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.1.1 구조적, 집합적, 선언적 질의 언어
--------------------------------------------------------------------------------
select e.empno, e.ename, e.job, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno
order by e.ename;
--------------------------------------------------------------------------------
-- 1.1.4 실행계획과 비용
--------------------------------------------------------------------------------
-- SQL 실행경로 미리보기
explain plan for select
    /*+ leading(d e) use_nl(e) no_nlj_prefetch(e) opt_param('_nlj_batching_enabled', 0)
        no_batch_table_access_by_rowid(d) no_batch_table_access_by_rowid(e) */
    e.empno, e.ename, e.job
from emp e, dept d
where e.deptno = d.deptno
and d.loc = 'CHICAGO';

select plan_table_output from table(dbms_xplan.display(format => 'basic cost rows bytes'));

-- 실행계획 선택 근거
create table t as
select d.no, e.* from scott.emp e, (select rownum no from dual connect by level <= 1000) d;

create index t_x01 on t(deptno, no);
create index t_x02 on t(deptno, job, no);

exec dbms_stats.gather_table_stats(user, 't');

set autotrace traceonly explain;

select * from t
where deptno = 10
and no = 1;

select /*+ index(t t_x02) no_index_ss(t t_x02) */ * from t
where deptno = 10
and no = 1;

select /*+ full(t) */ * from t
where deptno = 10
and no = 1;

set autotrace off;
--------------------------------------------------------------------------------
-- 1.1.5 옵티마이저 힌트
--------------------------------------------------------------------------------