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
--------------------------------------------------------------------------------
-- 데이터베이스 call
--------------------------------------------------------------------------------
create table customer(
    cust_id varchar2(10) constraint customer_pk primary key,
    cust_nm varchar2(10),
    birthday varchar2(14)
);

select cust_nm, birthday from customer where cust_id = :cust_id;

drop table customer;
--------------------------------------------------------------------------------
-- 절차적 루프 처리
--------------------------------------------------------------------------------
create table source
as
select b.no, a.*
from (select * from emp where rownum <= 10) a,
     (select rownum as no from dual connect by level <= 100000) b;

create table target
as
select * from source where 1 = 2;

set timing on;

begin
    for s in (select * from source)
    loop
        insert into target values(s.no, s.empno, s.ename, s.job, s.mgr,
                                  s.hiredate, s.sal, s.comm, s.deptno);
    end loop;

    commit;
end;
/

truncate table target;
--------------------------------------------------------------------------------
-- 커밋과 성능
--------------------------------------------------------------------------------
begin
    for s in (select * from source)
    loop
        insert into target values(s.no, s.empno, s.ename, s.job, s.mgr,
                                  s.hiredate, s.sal, s.comm, s.deptno);
        commit;
    end loop;
end;
/

truncate table target;

declare
    i number(10) := 1;
begin
    for s in (select * from source)
    loop
        insert into target values(s.no, s.empno, s.ename, s.job, s.mgr,
                                  s.hiredate, s.sal, s.comm, s.deptno);

        if mod(i, 100000) = 0 then
            commit;
        end if;
    end loop;
end;
/

truncate table target;
--------------------------------------------------------------------------------
-- one sql의 중요성
--------------------------------------------------------------------------------
insert into target
select * from source;

truncate table target;
--------------------------------------------------------------------------------
-- 6.1.3 array processing 활용
--------------------------------------------------------------------------------
declare
    cursor c is select * from source;
    type typ_source is table of c%rowtype;
    l_source typ_source;

    l_array_size number default 10000;

    procedure insert_target(p_source in typ_source) is
    begin
        forall i in p_source.first..p_source.last
            insert into target values p_source(i);
    end insert_target;
begin
    open c;

    loop
        fetch c bulk collect into l_source limit l_array_size;
        insert_target(l_source);
        exit when c%notfound;
    end loop;

    close c;

    commit;
end;
/

truncate table target;

set timing off;

drop table target;
drop table source;
--------------------------------------------------------------------------------
-- 6.1.4 인덱스 및 제약 해제를 통한 대량 dml 튜닝
--------------------------------------------------------------------------------
create table source
as
select b.no, a.*
from (select * from emp where rownum <= 10) a,
     (select rownum as no from dual connect by level <= 1000000) b;

create table target
as
select * from source where 1 = 2;

alter table target add constraint target_pk primary key (no, empno);

create index target_x1 on target(ename);

set timing on;

insert /*+ append */ into target
select * from source;

commit;
--------------------------------------------------------------------------------
-- pk 제약과 인덱스 해제 1 - pk 제약에 unique 인덱스를 사용한 경우
--------------------------------------------------------------------------------
truncate table target;

alter table target modify constraint target_pk disable drop index;

alter index target_x1 unusable;

alter session set skip_unusable_indexes = true;

insert /*+ append */ into target
select * from source;

commit;

alter table target modify constraint target_pk enable novalidate;

alter index target_x1 rebuild;

select no, empno, count(*)
from source
group by no, empno
having count(*) > 1;
--------------------------------------------------------------------------------
-- pk 제약과 인덱스 해제 2 - pk 제약에 non-unique 인덱스를 사용한 경우
--------------------------------------------------------------------------------
alter index target_pk unusable;

insert into target
select * from source;

insert /*+ append */ into target
select * from source;

set timing off;

truncate table target;

alter table target drop primary key drop index;

create index target_pk on target(no, empno);

alter table target add constraint target_pk primary key (no, empno)
using index target_pk;

alter table target modify constraint target_pk disable keep index;

alter index target_pk unusable;

alter index target_x1 unusable;

set timing on;

insert /*+ append */ into target
select * from source;

commit;

alter index target_x1 rebuild;

alter index target_pk rebuild;

alter table target modify constraint target_pk enable novalidate;
--------------------------------------------------------------------------------
-- 6.1.5 수정가능 조인 뷰
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 전통적인 방식의 update
--------------------------------------------------------------------------------
