--------------------------------------------------------------------------------
-- 6장 - dml 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 6.1 기본 dml 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 6.1.1 dml 성능에 영향을 미치는 요소
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 인덱스와 dml 성능
--------------------------------------------------------------------------------
create table source
as
select b.no, a.*
from (select * from emp where rownum <= 10) a,
     (select rownum as no from dual connect by level <= 100000) b;

create table target
as
select * from source where 1 = 2;

alter table target add constraint target_pk primary key (no, empno);

set timing on;

insert into target select * from source;

truncate table target;

create index target_x1 on target(ename);

create index target_x2 on target(deptno, mgr);

insert into target select * from source;
--------------------------------------------------------------------------------
-- 무결성 제약과 dml 성능
--------------------------------------------------------------------------------
drop index target_x1;

drop index target_x2;

alter table target drop primary key;

truncate table target;

insert into target select * from source;

drop table source;
drop table target;

set timing off;
--------------------------------------------------------------------------------
-- 조건절과 dml 성능
--------------------------------------------------------------------------------
set autotrace traceonly explain;

create index emp_x01 on emp(deptno);

update emp set
sal = sal * 1.1
where deptno = 40;

delete from emp where deptno = 40;
--------------------------------------------------------------------------------
-- 서브쿼리와 dml 성능
--------------------------------------------------------------------------------
create index dept_x01 on dept(loc);

update emp e set
    sal = sal * 1.1
where exists (
    select /*+ no_batch_table_access_by_rowid(dept) */ 'x'
    from dept
    where deptno = e.deptno and loc = 'CHICAGO'
);

delete /*+ leading(e) */ from emp e
where exists (
    select /*+ no_batch_table_access_by_rowid(dept) unnest */ 'x'
    from dept
    where deptno = e.deptno and loc = 'CHICAGO'
);

create table emp_t
as select e.* from emp e where 1 = 2;

insert into emp
select e.*
from emp_t e
where exists (
    select /*+ no_batch_table_access_by_rowid(dept) unnest use_hash(dept) */ 'x'
    from dept
    where deptno = e.deptno and loc = 'CHICAGO'
);

drop index emp_x01;
drop index dept_x01;
drop table emp_t;

set autotrace off;
--------------------------------------------------------------------------------
-- 6.1.2 데이터베이스 call과 성능
--------------------------------------------------------------------------------
