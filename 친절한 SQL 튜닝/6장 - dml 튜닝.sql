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

drop table source;
drop table target;
--------------------------------------------------------------------------------
-- 6.1.5 수정가능 조인 뷰
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 전통적인 방식의 update
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    최종거래일시 timestamp,
    최근거래횟수 number(10),
    최근거래금액 number(10)
);

create table 거래(
    고객번호 number(10) constraint 고객_fk references 고객(고객번호),
    거래일시 timestamp,
    거래금액 number(10),
    constraint 거래_pk primary key (고객번호, 거래일시)
);

explain plan for
update 고객 c
set 최종거래일시 = (select /*+ index(거래) */ max(거래일시)
                  from 거래
                  where 고객번호 = c.고객번호
                  and 거래일시 >= trunc(add_months(sysdate, -1))),
    최근거래횟수 = (select /*+ index(거래) */ count(*)
                  from 거래
                  where 고객번호 = c.고객번호
                  and 거래일시 >= trunc(add_months(sysdate, -1))),
    최근거래금액 = (select /*+ index(거래) */ sum(거래금액)
                  from 거래
                  where 고객번호 = c.고객번호
                  and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (
    select 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1))
);

select * from table(dbms_xplan.display);

explain plan for
update 고객 c
set (최종거래일시, 최근거래횟수, 최근거래금액) = (
    select max(거래일시), count(*), sum(거래금액)
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (
    select 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1))
);

select * from table(dbms_xplan.display);

explain plan for
update 고객 c
set (최종거래일시, 최근거래횟수, 최근거래금액) = (
    select max(거래일시), count(*), sum(거래금액)
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1)))
where exists (
    select /*+ unnest hash_sj */ 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1))
);

select * from table(dbms_xplan.display);

explain plan for
update 고객 c
set (최종거래일시, 최근거래횟수, 최근거래금액) =
(
    select nvl(max(거래일시), c.최종거래일시),
           decode(count(*), 0, c.최근거래횟수, count(*)),
           nvl(sum(거래금액), c.최근거래금액)
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(add_months(sysdate, -1))
);

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 수정가능 조인 뷰
--------------------------------------------------------------------------------
explain plan for
update (
    select /*+ ordered use_hash(c) no_merge(t) */
           c.최종거래일시, c.최근거래횟수, c.최근거래금액,
           t.거래일시, t.거래횟수, t.거래금액
    from (
        select /*+ no_batch_table_access_by_rowid(거래) full(거래) */
            고객번호, max(거래일시) 거래일시, count(*) 거래횟수, sum(거래금액) 거래금액
        from 거래
        where 거래일시 >= trunc(add_months(sysdate, -1))
        group by 고객번호
    ) t, 고객 c
    where c.고객번호 = t.고객번호)
set 최종거래일시 = 거래일시,
    최근거래횟수 = 거래횟수,
    최근거래금액 = 거래금액;

select * from table(dbms_xplan.display);

create table emp2 as select * from scott.emp;
create table dept2 as select * from scott.dept;

create or replace view emp_dept_view as
select e.rowid emp_rid, e.*, d.rowid dept_rid, d.dname, d.loc
from emp2 e, dept2 d
where e.deptno = d.deptno;

update emp_dept_view set loc = 'SEOUL' where job = 'CLERK';

select empno, ename, job, sal, deptno, dname, loc
from emp_dept_view
order by job, deptno;

update emp_dept_view set comm = nvl(comm, 0) + (sal * 0.1) where sal <= 1500;

delete from emp_dept_view where job = 'CLERK';

alter table dept2 add constraint dept2_pk primary key (deptno);

update emp_dept_view set comm = nvl(comm, 0) + (sal * 0.1) where sal <= 1500;

drop table 거래;
drop table 고객;
--------------------------------------------------------------------------------
-- 키 보존 테이블이란?
--------------------------------------------------------------------------------
select rowid, emp_rid, dept_rid, empno, deptno from emp_dept_view;

alter table dept2 drop primary key;

select rowid, emp_rid, dept_rid, empno, deptno from emp_dept_view;

drop view emp_dept_view;
drop table emp2;
drop table dept2;
--------------------------------------------------------------------------------
-- ora-01779 오류 회피
--------------------------------------------------------------------------------
alter table dept add avg_sal number(7, 2);

update (
    select d.deptno, d.avg_sal as d_avg_sal, e.avg_sal as e_avg_sal
    from (
        select deptno, round(avg(sal), 2) avg_sal
        from emp
        group by deptno
    ) e, dept d
    where d.deptno = e.deptno
) set d_avg_sal = e_avg_sal;

update /*+ bypass_ujvc */ (
    select d.deptno, d.avg_sal as d_avg_sal, e.avg_sal as e_avg_sal
    from (
        select deptno, round(avg(sal), 2) avg_sal
        from emp
        group by deptno
    ) e, dept d
    where d.deptno = e.deptno
) set d_avg_sal = e_avg_sal;

rollback;

alter table dept drop column avg_sal;

create table 고객_t(
    고객번호 number(10),
    고객등급 varchar2(1)
);

create table 주문_t(
    고객번호 number(10),
    주문금액 number(10),
    할인금액 number(10)
);

update (
    select o.주문금액, o.할인금액, c.고객등급
    from 주문_t o, 고객_t c
    where o.고객번호 = c.고객번호
    and o.주문금액 >= 1000000
    and c.고객등급 = 'A')
set 할인금액 = 주문금액 * 0.2,
    주문금액 = 주문금액 * 0.8;

update (
    select o.주문금액, o.할인금액
    from 주문_t o, (
        select 고객번호
        from 고객_t
        where 고객등급 = 'A'
        group by 고객번호
    ) c
    where o.고객번호 = c.고객번호
    and o.주문금액 >= 1000000)
set 할인금액 = 주문금액 * 0.2,
    주문금액 = 주문금액 * 0.8;

drop table 주문_t;
drop table 고객_t;
--------------------------------------------------------------------------------
-- 6.1.6 merge 문 활용
--------------------------------------------------------------------------------
create table customer(
    cust_id varchar2(10) constraint customer_pk primary key,
    cust_nm varchar2(10),
    email varchar2(10),
    tel_no varchar2(10),
    region varchar2(10),
    addr varchar2(10),
    reg_dt date,
    mod_dt date,
    withdraw_dt date
);

create table customer_dw (
    cust_id varchar2(10) constraint customer_dw_pk primary key,
    cust_nm varchar2(10),
    email varchar2(10),
    tel_no varchar2(10),
    region varchar2(10),
    addr varchar2(10),
    reg_dt date,
    mod_dt date,
    withdraw_dt date
);

create table customer_delta
as
select * from customer
where mod_dt >= trunc(sysdate) -1
and mod_dt < trunc(sysdate);

merge into customer_dw t using customer_delta s
on (t.cust_id = s.cust_id)
when matched then update
    set t.cust_nm = s.cust_nm, t.email = s.email, t.tel_no = s.tel_no,
        t.region = s.region, t.addr = s.addr, t.reg_dt = s.reg_dt
when not matched then insert
    (cust_id, cust_nm, email, tel_no, region, addr, reg_dt)
    values (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);
--------------------------------------------------------------------------------
-- optional clasues
--------------------------------------------------------------------------------
merge into customer_dw t using customer_delta s
on (t.cust_id = s.cust_id)
when matched then update
    set t.cust_nm = s.cust_nm, t.email = s.email, t.tel_no = s.tel_no,
        t.region = s.region, t.addr = s.addr, t.reg_dt = s.reg_dt;

merge into customer_dw t using customer_delta s
on (t.cust_id = s.cust_id)
when not matched then insert
    (cust_id, cust_nm, email, tel_no, region, addr, reg_dt)
    values (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);

alter table dept add avg_sal number(7, 2);

update (
    select d.deptno, d.avg_sal as d_avg_sal, e.avg_sal as e_avg_sal
    from (
        select deptno, round(avg(sal), 2) avg_sal
        from emp
        group by deptno
    ) e, dept d
    where d.deptno = e.deptno)
set d_avg_sal = e_avg_sal;

rollback;

merge into dept d
using (select deptno, round(avg(sal), 2) avg_sal
       from emp
       group by deptno) e
on (d.deptno = e.deptno)
when matched then update set d.avg_sal = e.avg_sal;

rollback;

alter table dept drop column avg_sal;
--------------------------------------------------------------------------------
-- conditional operations
--------------------------------------------------------------------------------
merge into customer_dw t using customer_delta s
on (t.cust_id = s.cust_id)
when matched then update
    set t.cust_nm = s.cust_nm, t.email = s.email, t.tel_no = s.tel_no,
        t.region = s.region, t.addr = s.addr, t.reg_dt = s.reg_dt
    where reg_dt >= to_date('20000101', 'yyyymmdd')
when not matched then insert
    (cust_id, cust_nm, email, tel_no, region, addr, reg_dt)
        values (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt)
    where s.reg_dt < trunc(sysdate);
--------------------------------------------------------------------------------
-- delete clause
--------------------------------------------------------------------------------
merge into customer_dw t using customer_delta s
on (t.cust_id = s.cust_id)
when matched then update
    set t.cust_nm = s.cust_nm, t.email = s.email, t.tel_no = s.tel_no,
        t.region = s.region, t.addr = s.addr, t.reg_dt = s.reg_dt
    delete where t.withdraw_dt is not null
when not matched then insert
    (cust_id, cust_nm, email, tel_no, region, addr, reg_dt)
        values (s.cust_id, s.cust_nm, s.email, s.tel_no, s.region, s.addr, s.reg_dt);

drop table customer_dw;
drop table customer_delta;
drop table customer;
--------------------------------------------------------------------------------
-- merge into 활용 예
--------------------------------------------------------------------------------
begin
    select count(*) into :cnt from dept where deptno = :val1;

    if :cnt = 0 then
        insert into dept(deptno, dname, loc) values (:val1, :val2, :val3);
    else
        update dept set dname = :val2, loc = :val3 where deptno = :val1;
    end if;

    rollback;
end;
/

begin
    update dept set dname = :val2, loc = :val3 where deptno = :val1;

    if sql%rowcount = 0 then
        insert into dept(deptno, dname, loc) values (:val1, :val2, :val3);
    end if;

    rollback;
end;
/

begin
    merge into dept a
    using (select :val1 deptno, :val2 dname, :val3 loc from dual) b
    on (b.deptno = a.deptno)
    when matched then update
        set dname = b.dname, loc = b.loc
    when not matched then insert
        (a.deptno, a.dname, a.loc) values (b.deptno, b.dname, b.loc);

    rollback;
end;
/
--------------------------------------------------------------------------------
-- 수정가능 조인 뷰 vs. merge 문
--------------------------------------------------------------------------------
create table emp_src
as select * from emp;

merge into emp t2
using (select t.rowid as rid, s.ename
       from emp t, emp_src s
       where t.empno = s.empno
       and t.ename <> s.ename) s
on (t2.rowid = s.rid)
when matched then update set t2.ename = s.ename;

rollback;

merge into emp t
using emp_src s
on (t.empno = s.empno)
when matched then update set t.ename = s.ename
where t.ename <> s.ename;

rollback;

alter table emp_src add primary key (empno);

update (
    select s.ename as s_ename, t.ename as t_ename
    from emp t, emp_src s
    where t.empno = s.empno
    and t.ename <> s.ename
) set t_ename = s_ename;

alter table emp_src drop primary key;

update (
    select s.ename as s_ename, t.ename as t_ename
    from emp t,
         (select empno, max(ename) ename
          from emp_src
          group by empno) s
    where t.empno = s.empno
    and t.ename <> s.ename
) set t_ename = s_ename;

drop table emp_src;
--------------------------------------------------------------------------------
-- 6.2 direct path i/o 활용
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 6.2.1 direct path i/o
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 병렬 쿼리
--------------------------------------------------------------------------------
create table big_table
as
select a.no, b.*
from (select rownum no from dual connect by level <= 10) a,
     (select * from all_objects) b;

alter table big_table add constraint big_table_pk primary key (no, object_id);

select /*+ gather_plan_statistics full(t) parallel(t 4) */ *
from big_table t;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

create index big_table_x1 on big_table(no);

select /*+ gather_plan_statistics
           index_ffs(t big_table_x1) parallel_index(t big_table_x1 4) */ count(*)
from big_table t;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop table big_table;
--------------------------------------------------------------------------------
-- 6.2.2 direct path insert
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

declare
    cursor c is select * from source;
    type typ_source is table of c%rowtype;
    l_source typ_source;

    l_array_size number default 1000000;

    procedure insert_target(p_source in typ_source) is
    begin
        forall i in p_source.first..p_source.last
            insert /*+ append_values */ into target values p_source(i);
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

set timing off;

drop table source;
drop table target;
--------------------------------------------------------------------------------
-- 6.2.3 병렬 dml
--------------------------------------------------------------------------------
create table 고객(
    고객id varchar2(10) constraint 고객_pk primary key,
    고객상태코드 varchar2(2),
    최종거래일시 varchar2(8),
    탈퇴일시 varchar2(8)
);

create table 외부가입고객
as select * from 고객;

alter session enable parallel dml;

insert /*+ parallel(c 4) */ into 고객 c
select /*+ full(o) parallel(o 4) */ * from 외부가입고객 o;

rollback;

update /*+ full(c) parallel(c 4) */ 고객 c
set 고객상태코드 = 'WD'
where 최종거래일시 < '20100101';

rollback;

delete /*+ full(c) parallel(c 4) */ from 고객 c
where 탈퇴일시 < '20100101';

rollback;

alter session disable parallel dml;

insert /*+ append parallel(c 4) */ into 고객 c
select /*+ full(o) parallel(o 4) */ * from 외부가입고객 o;

rollback;

insert /*+ enable_parallel_dml parallel(c 4) */ into 고객 c
select /*+ full(o) parallel(o 4) */ * from 외부가입고객 o;

rollback;

update /*+ enable_parallel_dml full(c) parallel(c 4) */ 고객 c
set 고객상태코드 = 'WD'
where 최종거래일시 < '20100101';

rollback;

delete /*+ enable_parallel_dml full(c) parallel(c 4) */ from 고객
where 탈퇴일시 < '20100101';

rollback;
--------------------------------------------------------------------------------
-- 병렬 dml이 잘 작동하는지 확인하는 방법
--------------------------------------------------------------------------------
explain plan for
update /*+ enable_parallel_dml full(c) parallel(c 4) */ 고객 c
set 고객상태코드 = 'WD'
where 최종거래일시 < '20100101';

select * from table(dbms_xplan.display);

rollback;

explain plan for
update /*+ full(c) parallel(c 4) */ 고객 c
set 고객상태코드 = 'WD'
where 최종거래일시 < '20100101';

select * from table(dbms_xplan.display);

rollback;

drop table 고객;
drop table 외부가입고객;
--------------------------------------------------------------------------------
-- 6.3 파티션을 활용한 dml 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- range 파티션
--------------------------------------------------------------------------------
create table 주문(
    주문번호 number constraint 주문_pk primary key,
    주문일자 varchar2(8),
    고객id varchar2(5),
    배송일자 varchar2(8),
    주문금액 number
) partition by range(주문일자) (
    partition p2017_q1 values less than ('20170401'),
    partition p2017_q2 values less than ('20170701'),
    partition p2017_q3 values less than ('20171001'),
    partition p2017_q4 values less than ('20180101'),
    partition p2018_q1 values less than ('20180401'),
    partition p9999_mx values less than (maxvalue)
);

explain plan for
select * from 주문
where 주문일자 >= '20120401' and 주문일자 <= '20120630';

select * from table(dbms_xplan.display);

drop table 주문;
--------------------------------------------------------------------------------
-- 해시 파티션
--------------------------------------------------------------------------------
create table 고객(
    고객id varchar2(5) constraint 고객_pk primary key,
    고객명 varchar2(10)
) partition by hash(고객id) partitions 4;

explain plan for
select * from 고객
where 고객id = 'test';

select * from table(dbms_xplan.display);

drop table 고객;
--------------------------------------------------------------------------------
-- 리스트 파티션
--------------------------------------------------------------------------------
create table 인터넷매물(
    물건코드 varchar2(5),
    지역분류 varchar2(6)
) partition by list(지역분류) (
    partition p_지역1 values ('서울'),
    partition p_지역2 values ('경기', '인천'),
    partition p_지역3 values ('부산', '대구', '대전', '광주'),
    partition p_기타 values (default)
);

explain plan for
select * from 인터넷매물
where 지역분류 = '서울';

select * from table(dbms_xplan.display);

drop table 인터넷매물;
--------------------------------------------------------------------------------
-- 6.3.2 인덱스 파티션
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 로컬 파티션 인덱스
--------------------------------------------------------------------------------
create table 주문(
    주문번호 number constraint 주문_pk primary key,
    주문일자 varchar2(8),
    고객id varchar2(5),
    배송일자 varchar2(8),
    주문금액 number
) partition by range(주문일자) (
    partition p2017_q1 values less than ('20170401'),
    partition p2017_q2 values less than ('20170701'),
    partition p2017_q3 values less than ('20171001'),
    partition p2017_q4 values less than ('20180101'),
    partition p2018_q1 values less than ('20180401'),
    partition p9999_mx values less than (maxvalue)
);

create index 주문_x01 on 주문(주문일자, 주문금액) local;

create index 주문_x02 on 주문(고객id, 주문일자) local;
--------------------------------------------------------------------------------
-- 글로벌 파티션 인덱스
--------------------------------------------------------------------------------
create index 주문_x03 on 주문(주문금액, 주문일자) global
partition by range(주문금액) (
    partition p_01 values less than (100000),
    partition p_mx values less than (maxvalue)
);
--------------------------------------------------------------------------------
-- 비파티션 인덱스
--------------------------------------------------------------------------------
create index 주문_x04 on 주문(고객id, 배송일자);
--------------------------------------------------------------------------------
-- prefixed vs. nonprefixed
--------------------------------------------------------------------------------
select i.index_name, i.partitioned, p.partitioning_type, p.locality, p.alignment
from user_indexes i, user_part_indexes p
where i.table_name = '주문'
and   p.index_name(+) = i.index_name
order by i.index_name;

drop table 주문;
--------------------------------------------------------------------------------
-- 6.3.3 파티션을 활용한 대량 update 튜닝
--------------------------------------------------------------------------------
create table 거래(
    고객번호 number(10),
    거래일자 varchar2(8),
    거래순번 number(10),
    상태코드 varchar2(3)
) partition by range(거래일자) (
    partition p201412 values less than ('20150101'),
    partition p201501 values less than ('20150201'),
    partition p201502 values less than ('20150301'),
    partition p9999mx values less than (maxvalue)
);

create unique index 거래_pk on 거래(고객번호, 거래일자, 거래순번) local;
alter table 거래 add primary key (고객번호, 거래일자, 거래순번) using index 거래_pk;
create index 거래_x11 on 거래(거래일자, 고객번호) local;
create index 거래_x22 on 거래(상태코드, 거래일자) local;

explain plan for
update 거래
set 상태코드 = 'ZZZ'
where 상태코드 <> 'ZZZ'
and 거래일자 < '20150101';

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 파티션 exchange를 이용한 대량 데이터 변경
--------------------------------------------------------------------------------
create table 거래_t nologging
as select * from 거래 where 1 = 2;

insert /*+ append */ into 거래_t
select 고객번호, 거래일자, 거래순번,
       (case when 상태코드 <> 'ZZZ' then 'ZZZ' else 상태코드 end) 상태코드
from 거래
where 거래일자 < '20150101';

create unique index 거래_t_pk on 거래_t(고객번호, 거래일자, 거래순번) nologging;
create index 거래_t_x11 on 거래_t(거래일자, 고객번호) nologging;
create index 거래_t_x22 on 거래_t(상태코드, 거래일자) nologging;

alter table 거래
exchange partition p201412 with table 거래_t
including indexes without validation;

drop table 거래_t;

alter table 거래 modify partition p201412 logging;
alter index 거래_pk modify partition p201412 logging;
alter index 거래_x11 modify partition p201412 logging;
alter index 거래_x22 modify partition p201412 logging;
--------------------------------------------------------------------------------
-- 6.3.4 파티션을 활용한 대량 delete 튜닝
--------------------------------------------------------------------------------
explain plan for
delete from 거래
where 거래일자 < '20150101';

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 파티션 drop을 이용한 대량 데이터 삭제
--------------------------------------------------------------------------------
alter table 거래 drop partition p201412;

alter table 거래 split partition p201501
at ('20150101') into (partition p201412, partition p201501);

alter table 거래 drop partition for ('20141201');

alter table 거래 split partition p201501
at ('20150101') into (partition p201412, partition p201501);
--------------------------------------------------------------------------------
-- 파티션 truncate를 이용한 대량 데이터 삭제
--------------------------------------------------------------------------------
explain plan for
delete from 거래
where 거래일자 < '20150101'
and (상태코드 <> 'ZZZ' or 상태코드 is null);

select * from table(dbms_xplan.display);

create table 거래_t as
select * from 거래
where 거래일자 < '20150101'
and 상태코드 = 'ZZZ';

alter table 거래 truncate partition p201412;

alter table 거래 truncate partition for ('20141201');

insert into 거래
select * from 거래_t;

drop table 거래_t;

drop table 거래;
--------------------------------------------------------------------------------
-- 6.3.5 파티션을 활용한 대량 insert 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 비파티션 테이블일 때
--------------------------------------------------------------------------------
create table source_t
as select a.no, b.*
from (select rownum no from dual connect by level <= 100000) a,
     (select * from emp) b;

create table target_t
as select * from source_t
where 1 = 2;

create index target_t_x01 on target_t(no);

alter table target_t nologging;

alter index target_t_x01 unusable;

insert /*+ append */ into target_t
select * from source_t;

alter index target_t_x01 rebuild nologging;

alter table target_t logging;
alter index target_t_x01 logging;

drop table target_t;
drop table source_t;
--------------------------------------------------------------------------------
-- 파티션 테이블일 때
--------------------------------------------------------------------------------
create table source_t
partition by range(dt) (
    partition p_201710 values less than ('20171101'),
    partition p_201711 values less than ('20171201'),
    partition p_201712 values less than ('20180101')
) as select
        to_char(rownum) dummy,
        ('2017' || lpad(mod(rownum, 13), 2, '0') || lpad(mod(rownum, 31), 2, '0')) dt
     from dual connect by level <= 1000000;

create table target_t
partition by range(dt) (
    partition p_201710 values less than ('20171101'),
    partition p_201711 values less than ('20171201'),
    partition p_201712 values less than ('20180101'))
as select * from source_t
where 1 = 2;

create index target_t_x01 on target_t(dt, dummy) local;

alter table target_t modify partition p_201712 nologging;

alter index target_t_x01 modify partition p_201712 unusable;

insert /*+ append */ into target_t
select * from source_t
where dt between '20171201' and '20171231';

alter index target_t_x01 rebuild partition p_201712 nologging;

alter table target_t modify partition p_201712 logging;
alter index target_t_x01 modify partition p_201712 logging;

drop table source_t;
drop table target_t;
--------------------------------------------------------------------------------
-- 6.4 lock과 트랜잭션 동시성 제어
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 6.4.1 오라클 lock
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 대상 리소스가 사용중일 때, 진로 선택
--------------------------------------------------------------------------------
create table t as
select a.no, b.*
from (select rownum no from dual connect by level <= 10) a,
     (select * from emp) b;

-- session 1
select * from t for update; -- (1)
rollback;                   -- (3)

-- session 2
select * from t for update; -- (2)
rollback;                   -- (4)

-- session 1
select * from t for update; -- (1)
rollback;                   -- (3)

-- session 2
select * from t for update wait 3;

-- session 1
select * from t for update; -- (1)
rollback;                   -- (3)

-- session 2
select * from t for update nowait; -- (2)

drop table t;

-- session 1
select * from emp for update; -- (1)
rollback;                   -- (3)

-- session 2
lock table emp in exclusive mode nowait; -- (2)
--------------------------------------------------------------------------------
-- lock을 푸는 열쇠, 커밋
--------------------------------------------------------------------------------
commit write immediate wait;
commit write immediate nowait;
commit write batch wait;
commit write batch nowait;
--------------------------------------------------------------------------------
-- 6.4.2 트랜잭션 동시성 제어
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 비관적 동시성 제어
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    적립포인트 number(10),
    방문횟수 number(10),
    최근방문일시 varchar2(8),
    구매실적 number(10)
);

select 적립포인트, 방문횟수, 최근방문일시, 구매실적 from 고객
where 고객번호 = :cust_num;

-- 새로운 적립포인트 계산

update 고객
set 적립포인트 = :적립포인트
where 고객번호 = :cust_num;

select 적립포인트, 방문횟수, 최근방문일시, 구매실적 from 고객
where 고객번호 = :cust_num for update;

rollback;

drop table 고객;
--------------------------------------------------------------------------------
-- 큐(queue) 테이블 동시성 제어
--------------------------------------------------------------------------------
create table cust_rcpt_q(
    cust_id varchar2(10) constraint cust_rcpt_q_pk primary key,
    rcpt_amt number(10),
    yn_upd varchar2(1)
);

select cust_id, rcpt_amt from cust_rcpt_q
where yn_upd = 'Y' and rownum <= 100
for update wait 3;

rollback;

select cust_id, rcpt_amt from cust_rcpt_q
where yn_upd = 'Y'
for update skip locked;

rollback;

drop table cust_rcpt_q;
--------------------------------------------------------------------------------
-- 낙관적 동시성 제어
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    적립포인트 number(10),
    방문횟수 number(10),
    최근방문일시 varchar2(8),
    구매실적 number(10)
);

begin
    select 적립포인트, 방문횟수, 최근방문일시, 구매실적
    into :a, :b, :c, :d
    from 고객
    where 고객번호 = :cust_num;

    -- 새로운 적립포인트 계산

    update 고객
    set 적립포인트 = :적립포인트
    where 고객번호 = :cust_num
    and 적립포인트 = :a
    and 방문횟수 = :b
    and 최근방문일시 = :c
    and 구매실적 = :d;

    if sql%rowcount = 0 then
        null; -- alert('다른 사용자에 의해 변경되었습니다.');
    end if;
end;
/

drop table 고객;

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    적립포인트 number(10),
    방문횟수 number(10),
    최근방문일시 varchar2(8),
    구매실적 number(10),
    변경일시 varchar2(8)
);

begin
    select 적립포인트, 방문횟수, 최근방문일시, 구매실적, 변경일시
    into :a, :b, :c, :d, :mod_dt
    from 고객
    where 고객번호 = :cust_num;

    -- 새로운 적립포인트 계산

    update 고객
    set 적립포인트 = :적립포인트, 변경일시 = sysdate
    where 고객번호 = :cust_num
    and 변경일시 = :mod_dt;

    if sql%rowcount = 0 then
        null; -- alert('다른 사용자에 의해 변경되었습니다.');
    end if;
end;
/

begin
    select 적립포인트, 방문횟수, 최근방문일시, 구매실적, 변경일시
    into :a, :b, :c, :d, :mod_dt
    from 고객
    where 고객번호 = :cust_num;

    -- 새로운 적립포인트 계산

    select 고객번호
    into :dummy
    from 고객
    where 고객번호 = :cust_num
    and 변경일시 = :mod_dt
    for update nowait;

    update 고객
    set 적립포인트 = :적립포인트, 변경일시 = sysdate
    where 고객번호 = :cust_num
    and 변경일시 = :mod_dt;

    if sql%rowcount = 0 then
        null; -- alert('다른 사용자에 의해 변경되었습니다.');
    end if;
end;
/

drop table 고객;
--------------------------------------------------------------------------------
-- 동시성 제어 없는 낙관적 프로그래밍
--------------------------------------------------------------------------------
create table 상품(
    상품코드 varchar2(10) constraint 상품_pk primary key,
    가격 number(10)
);

create table 주문(
    상품코드 varchar2(10) constraint 상품_fk references 상품(상품코드),
    고객id varchar2(10),
    주문일시 varchar2(8),
    상점번호 number(10)
);

begin
    insert into 주문
    select :상품코드, :고객id, :주문일시, :상점번호
    from 상품
    where 상품코드 = :상품코드
    and 가격 = :가격;

    if sql%rowcount = 0 then
        null; -- alert('다른 사용자에 의해 변경되었습니다.');
    end if;
end;
/

drop table 주문;
drop table 상품;
--------------------------------------------------------------------------------
-- 로우 lock 대상 테이블 지정
--------------------------------------------------------------------------------
create table 계좌마스터(
    계좌번호 varchar2(10) constraint 계좌마스터_pk primary key,
    고객번호 number(10),
    예수금 number(10)
);

create table 주문(
    주문일자 varchar2(8),
    주문순번 number(10),
    계좌번호 varchar2(10) constraint 계좌마스터_fk references 계좌마스터(계좌번호),
    종목 varchar2(10),
    주문가격 number(10),
    주문수량 number(10),
    constraint 주문_pk primary key (주문일자, 주문순번)
);

select b.주문수량
from 계좌마스터 a, 주문 b
where a.고객번호 = :cust_no
and b.계좌번호 = a.계좌번호
and b.주문일자 = :ord_dt
for update;

rollback;

select b.주문수량
from 계좌마스터 a, 주문 b
where a.고객번호 = :cust_no
and b.계좌번호 = a.계좌번호
and b.주문일자 = :ord_dt
for update of b.주문수량;

rollback;
--------------------------------------------------------------------------------
-- 6.4.3 채번 방식에 따른 insert 성능 비교
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 자율 트랜잭션
--------------------------------------------------------------------------------
create table seq_tab
as select 123 as gubun, 0 as seq from dual;

create or replace function seq_nextval(l_gubun number) return number
as
    pragma autonomous_transaction;
    l_new_seq seq_tab.seq%type;
begin
    update seq_tab
    set seq = seq + 1
    where gubun = l_gubun;

    select seq into l_new_seq
    from seq_tab
    where gubun = l_gubun;

    commit;

    return l_new_seq;
end;
/

create table target_tab(
    id number(10) constraint target_tab_pk primary key,
    val1 number(10),
    val2 number(10),
    val3 number(10)
);

begin
    insert into target_tab values (seq_nextval(123), :x, :y, :z);
end;
/

drop table target_tab;
drop function seq_nextval;
--------------------------------------------------------------------------------
-- 시퀀스 오브젝트
--------------------------------------------------------------------------------
create sequence my_seq cache 1000;

exec sys.dbms_shared_pool.keep('scott.my_seq', 'q');

drop sequence my_seq;
--------------------------------------------------------------------------------
-- 시퀀스 lock
--------------------------------------------------------------------------------
-- 로우 캐시 lock
create sequence myseq cache 1000;

select cache_size, last_number
from user_sequences
where sequence_name = 'MYSEQ';

select myseq.nextval from dual;

select cache_size, last_number
from user_sequences
where sequence_name = 'MYSEQ';

drop sequence myseq;
--------------------------------------------------------------------------------
-- max + 1 조회
--------------------------------------------------------------------------------
create table 상품거래(
    거래일련번호 number(10) constraint 상품거래_pk primary key,
    계좌번호 varchar2(10),
    거래일시 varchar2(8),
    상품코드 varchar2(10),
    거래가격 number(10),
    거래수량 number(10)
);

insert into 상품거래(거래일련번호, 계좌번호, 거래일시, 상품코드, 거래가격, 거래수량)
values (
    (select max(거래일련번호) + 1 from 상품거래),
    :acnt_no,
    sysdate,
    :prod_cd,
    :trd_price,
    :trd_qty
);
--------------------------------------------------------------------------------
-- 12c 시퀀스 신기능
--------------------------------------------------------------------------------
-- 컬럼 기본값으로 시퀀스 지정
create sequence my_seq;

create table t(
    c1 number default my_seq.nextval not null,
    c2 varchar2(5)
);

insert into t(c1, c2) values (my_seq.nextval, 'X');
insert into t(c2) values ('X');

select * from t;

drop sequence my_seq;
drop table t;
-- identity 컬럼
create table t(
    c1 number generated always as identity,
    c2 varchar2(5)
);

insert into t(c2) values ('X');
insert into t(c1, c2) values (default, 'X');
insert into t(c1, c2) values (3, 'X');

select * from t;

drop table t;

create table t(
    c1 number generated by default as identity,
    c2 varchar2(5)
);

insert into t(c2) values ('X');
insert into t(c1, c2) values (default, 'X');
insert into t(c1, c2) values (3, 'X');

select * from t;

drop table t;
-- 세션 시퀀스
create sequence g_seq global;

create sequence s_seq session;

drop sequence g_seq;

drop sequence s_seq;
--------------------------------------------------------------------------------
-- 시퀀스 신기능 활용
--------------------------------------------------------------------------------
create table t(
    id varchar2(10),
    c1 varchar2(1),
    c2 varchar2(1)
);

create sequence g_seq global;
create sequence s_seq session;

select g_seq.nextval from dual;

insert into t(id, c1, c2) values (
    to_char(g_seq.currval, 'fm0000') || to_char(s_seq.nextval, 'fm0000'),
    'A',
    'B'
);

select * from t;

drop sequence g_seq;
drop sequence s_seq;
drop table t;

create sequence my_seq maxvalue 9999 scale extend;

select my_seq.nextval as last_value,
       substr(my_seq.nextval, 1, 3) as val1,
       substr(my_seq.nextval, 4, 3) as val2,
       substr(my_seq.nextval, 7) as val3,
       sys_context('userenv', 'instance') as inst_id,
       sys_context('userenv', 'sid') as sid
from dual;

drop sequence my_seq;

create sequence my_seq maxvalue 9999999 scale;

select my_seq.nextval as last_value,
       substr(my_seq.nextval, 1, 3) as val1,
       substr(my_seq.nextval, 4, 3) as val2,
       substr(my_seq.nextval, 7) as val3,
       sys_context('userenv', 'instance') as inst_id,
       sys_context('userenv', 'sid') as sid
from dual;

drop sequence my_seq;

create sequence my_seq;

select sys_context('userenv', 'instance') as 인스턴스번호,
       sys_context('userenv', 'sid') as 세션번호,
       my_seq.nextval as 시퀀스번호
from dual;

drop sequence my_seq;