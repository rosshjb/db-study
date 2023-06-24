--------------------------------------------------------------------------------
-- 4장 - 조인 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 4.1 nl 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 4.1.1 기본 메커니즘
--------------------------------------------------------------------------------
create table 사원(
    사원번호 varchar2(4) constraint 사원_pk primary key,
    사원명 varchar2(10),
    입사일자 varchar2(8)
);

create index 사원_x1 on 사원(입사일자);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    관리사원번호 varchar2(4) constraint 고객_사원_fk references 사원(사원번호)
);

create index 고객_x1 on 고객(관리사원번호);

explain plan for
select /*+ no_nlj_prefetch(c) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원명, c.고객명, c.전화번호
from 사원 e, 고객 c
where e.입사일자 >= '19960101'
and c.관리사원번호 = e.사원번호;

select * from table(dbms_xplan.display());

explain plan for
select /*+ ordered use_nl(c)
           no_nlj_prefetch(c) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원명, c.고객명, c.전화번호
from 사원 e, 고객 c
where e.입사일자 >= '19960101'
and c.관리사원번호 = e.사원번호;

select * from table(dbms_xplan.display());

drop table 고객;
drop table 사원;
--------------------------------------------------------------------------------
-- 4.1.3 nl 조인 수행 과정 분석
--------------------------------------------------------------------------------
create table 사원(
    사원번호 varchar2(4) constraint 사원_pk primary key,
    사원명 varchar2(10),
    입사일자 varchar2(8),
    부서코드 varchar2(4)
);

create index 사원_x11 on 사원(입사일자);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    최종주문금액 number(10),
    관리사원번호 varchar2(4) constraint 고객_사원_fk references 사원(사원번호)
);

create index 고객_x11 on 고객(관리사원번호);
create index 고객_x22 on 고객(최종주문금액);

explain plan for
select /*+ ordered use_nl(c) index(e) index(c)
           no_nlj_prefetch(c) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display());

drop table 고객;
drop table 사원;
--------------------------------------------------------------------------------
-- 4.1.5 nl 조인 특징 요약
--------------------------------------------------------------------------------
create table 사용자(
    사용자id varchar2(10),
    사용자명 varchar2(10)
);

create index 사용자id on 사용자(사용자id);

create table 게시판(
    게시글id number(10),
    게시판구분 varchar2(10),
    제목 varchar2(10),
    작성자id varchar2(10),
    등록일시 timestamp
);

create index 게시판idx on 게시판(게시판구분, 등록일시);

explain plan for
select /*+ ordered use_nl(b) index_desc(a (게시판구분, 등록일시))
           no_nlj_prefetch(b) opt_param('_nlj_batching_enabled', 0) */
    a.게시글id, a.제목, b.사용자명, a.등록일시
from 게시판 a, 사용자 b
where a.게시판구분 = 'NEWS'
and b.사용자id = a.작성자id
order by a.등록일시 desc;

select * from table(dbms_xplan.display);

drop table 게시판;
drop table 사용자;
--------------------------------------------------------------------------------
-- 4.1.7 nl 조인 확장 메커니즘
--------------------------------------------------------------------------------
create table 사원(
    사원번호 varchar2(4) constraint 사원_pk primary key,
    사원명 varchar2(10),
    입사일자 varchar2(8),
    부서코드 varchar2(4)
);

create index 사원_x11 on 사원(입사일자);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    최종주문금액 number(10),
    관리사원번호 varchar2(4) constraint 고객_사원_fk references 사원(사원번호)
);

create index 고객_x11 on 고객(관리사원번호);
create index 고객_x22 on 고객(최종주문금액);

explain plan for
select /*+ ordered use_nl(c) index(e) index(c)
           no_nlj_prefetch(c) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_nl(c) index(e) index(c)
           no_nlj_batching(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_nl(c) index(e) index(c)
           no_nlj_prefetch(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

drop table 고객;
drop table 사원;

create table 회원(
    회원번호 number(10) constraint 회원_pk primary key,
    회원명 varchar2(10)
);

create table 게시판(
    번호 number(10) constraint 게시판_pk primary key,
    제목 varchar2(10),
    게시판유형 varchar2(10),
    질문유형 varchar2(10),
    등록일시 timestamp,
    작성자번호 number(10) constraint 게시판_회원_fk references 회원(회원번호)
);

create index 게시판_idx on 게시판(게시판유형, 등록일시);

explain plan for
select /*+ ordered use_nl(b) */
    a.등록일시, a.번호, a.제목, b.회원명, a.게시판유형, a.질문유형
from (
    select a.*, rownum no
    from (
        select 등록일시, 번호, 제목, 작성자번호, 게시판유형, 질문유형
        from 게시판
        where 게시판유형 = :type
        order by 등록일시 desc
    ) a
    where rownum <= (:page * 10) -- 등록일시 내림차순일 때 특정 페이지의 게시글 최대 10건 가져옴.
) a, 회원 b
where a.no >= (:page - 1) * 10 + 1
and b.회원번호 = a.작성자번호
order by a.등록일시 desc;

select * from table(dbms_xplan.display);

drop table 게시판;
drop table 회원;
--------------------------------------------------------------------------------
-- nl 조인 자가 진단
--------------------------------------------------------------------------------
create table pra_hst_stc(
    sale_org_id varchar2(10),
    strd_grp_id varchar2(10),
    strd_id varchar2(10),
    stc_dt date
);

create index pra_hst_stc_idx on pra_hst_stc(stc_dt, sale_org_id, strd_grp_id, strd_id);

create table odm_trms(
    strd_grp_id varchar2(10),
    strd_id varchar2(10)
);

create index ord_trms_idx on odm_trms(strd_grp_id, strd_id);

explain plan for
select /*+ leading(a) use_nl(b) index_rs_desc(a) index(b) */ *
from pra_hst_stc a, odm_trms b
where a.sale_org_id = :sale_org_id
and b.strd_grp_id = a.strd_grp_id
and b.strd_id = a.strd_id
order by a.stc_dt desc;

select * from table(dbms_xplan.display);

drop table pra_hst_stc;
drop table odm_trms;
--------------------------------------------------------------------------------
-- 4.2 소트 머지 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 4.2.2 기본 메커니즘
--------------------------------------------------------------------------------
create table 사원(
    사원번호 varchar2(4) constraint 사원_pk primary key,
    사원명 varchar2(10),
    입사일자 varchar2(8),
    부서코드 varchar2(4)
);

create index 사원_x11 on 사원(입사일자);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    최종주문금액 number(10),
    관리사원번호 varchar2(4) constraint 고객_사원_fk references 사원(사원번호)
);

create index 고객_x11 on 고객(관리사원번호);
create index 고객_x22 on 고객(최종주문금액);

explain plan for
select /*+ ordered use_merge(c) full(e) full(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 4.2.3 소트 머지 조인 제어하기
--------------------------------------------------------------------------------
explain plan for
select /*+ ordered use_merge(c) index(e) index(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

drop table 고객;
drop table 사원;
--------------------------------------------------------------------------------
-- 4.3 해시 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 4.3.1 기본 메커니즘
--------------------------------------------------------------------------------
create table 사원(
    사원번호 varchar2(4) constraint 사원_pk primary key,
    사원명 varchar2(10),
    입사일자 varchar2(8),
    부서코드 varchar2(4)
);

create index 사원_x11 on 사원(입사일자);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    최종주문금액 number(10),
    관리사원번호 varchar2(4) constraint 고객_사원_fk references 사원(사원번호)
);

create index 고객_x11 on 고객(관리사원번호);
create index 고객_x22 on 고객(최종주문금액);

explain plan for
select /*+ ordered use_hash(c) full(e) full(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_hash(c) index(e) index(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 4.3.4 해시 조인 실행계획 제어
--------------------------------------------------------------------------------
explain plan for
select /*+ use_hash(e c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(e) use_hash(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_hash(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(e) use_hash(c) swap_join_inputs(c)
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(c) */
    e.사원번호, e.사원명, e.입사일자,
    c.고객번호, c.고객명, c.전화번호, c.최종주문금액
from 사원 e, 고객 c
where c.관리사원번호 = e.사원번호
and e.입사일자 >= '19960101'
and e.부서코드 = 'Z123'
and c.최종주문금액 >= 20000;

select * from table(dbms_xplan.display);

drop table 고객;
drop table 사원;
--------------------------------------------------------------------------------
-- 세 개 이상 테이블 해시 조인
--------------------------------------------------------------------------------
create table t1(key varchar2(10) constraint t1_pk primary key);
create table t2(key varchar2(10) constraint t2_pk primary key);
create table t3(key varchar2(10) constraint t3_pk primary key);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3)
           swap_join_inputs(t2) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3)
           swap_join_inputs(t3) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3)
           swap_join_inputs(t2) swap_join_inputs(t3) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3)
           no_swap_join_inputs(t3) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(t1, t2, t3) use_hash(t2) use_hash(t3)
           swap_join_inputs(t2) no_swap_join_inputs(t3) */ *
from t1, t2, t3
where t1.key = t2.key
and t2.key = t3.key;

select * from table(dbms_xplan.display);

drop table t3;
drop table t2;
drop table t1;
--------------------------------------------------------------------------------
-- 4.4 서브쿼리 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 4.4.1 서브쿼리 변환이 필요한 이유
--------------------------------------------------------------------------------
create table 고객분류(
    고객분류코드 varchar2(5) constraint 고객분류_pk primary key,
    고객분류명 varchar2(10)
);

create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    고객분류코드 varchar2(5) constraint 고객_fk references 고객분류(고객분류코드),
    가입일시 timestamp,
    최종변경일시 timestamp
);

create table 고객변경이력(
    고객번호 number(10) constraint 고객변경이력_fk references 고객(고객번호),
    시작일시 timestamp,
    종료일시 timestamp,
    변경사유코드 varchar2(3),
    constraint 고객변경이력_pk primary key (고객번호, 시작일시)
);

create table 거래(
    고객번호 number(10) constraint 거래_fk references 고객(고객번호),
    거래일시 timestamp,
    거래금액 number(10),
    constraint 거래_pk primary key (고객번호, 거래일시)
);

explain plan for
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래,
       (select 고객분류명 from 고객분류 where 고객분류코드 = c.고객분류코드)
from 고객 c,
     (
        select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래
        from 거래
        where 거래일시 >= trunc(sysdate, 'mm')
        group by 고객번호
     ) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호
and exists (
    select 'x'
    from 고객변경이력 h
    where h.고객번호 = c.고객번호
    and h.변경사유코드 = 'ZCH'
    and c.최종변경일시 between h.시작일시 and h.종료일시
);

select * from table(dbms_xplan.display);
-- 중첩된 서브쿼리
explain plan for
select c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
    select 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display);

explain plan for
select c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm');

select * from table(dbms_xplan.display);

explain plan for
select 'x'
from 거래
where 고객번호 = :cust_no
and 거래일시 >= trunc(sysdate, 'mm');

select * from table(dbms_xplan.display);

-- 인라인 뷰
explain plan for
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c,
     (
        select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래
        from 거래
        where 거래일시 >= trunc(sysdate, 'mm')
        group by 고객번호
     ) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호;

select * from table(dbms_xplan.display);

explain plan for
select c.고객번호, c.고객명, t.평균거래, t.최소거래, t.최대거래
from 고객 c,
     -- sys_vw_temp t
     (select 'sys_vw_temp' 고객번호,'sys_vw_temp' 평균거래, 'sys_vw_temp' 최소거래, 'sys_vw_temp' 최대거래
      from dual) t
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and t.고객번호 = c.고객번호;

select * from table(dbms_xplan.display);

explain plan for
select 고객번호, avg(거래금액) 평균거래, min(거래금액) 최소거래, max(거래금액) 최대거래
from 거래
where 거래일시 >= trunc(sysdate, 'mm')
group by 고객번호;

select * from table(dbms_xplan.display);

drop table 거래;
drop table 고객변경이력;
drop table 고객;
drop table 고객분류;
--------------------------------------------------------------------------------
-- 4.4.2 서브쿼리와 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 필터 오퍼레이션
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    가입일시 timestamp
);

create index 고객_x01 on 고객(가입일시);

create table 거래(
    고객번호 number(10) constraint 거래_fk references 고객(고객번호),
    거래일시 timestamp
);

create index 거래_x01 on 거래(고객번호, 거래일시);
alter table 거래 add constraint 거래_pk primary key (고객번호, 거래일시) using index 거래_x01;

explain plan for
select
    /*+ no_batch_table_access_by_rowid(c) */
    c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
    select /*+ no_unnest index(거래) */ 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 서브쿼리 unnesting
--------------------------------------------------------------------------------
explain plan for
select /*+ no_batch_table_access_by_rowid(c) */
    c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
    select /*+ unnest nl_sj */ 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display);

create index 거래_x02 on 거래(거래일시);

explain plan for
select /*+ leading(거래@subq) use_nl(c) */
    c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
    select /*+ no_batch_table_access_by_rowid(거래) qb_name(subq) unnest */ 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_merge(t)  leading(t)  use_nl(c) no_batch_table_access_by_rowid(c) */
    c.고객번호, c.고객명
from (
    select /*+ no_push_pred no_batch_table_access_by_rowid(거래) no_use_hash_aggregation */ distinct 고객번호
    from 거래
    where 거래일시 >= trunc(sysdate, 'mm')
) t, 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and c.고객번호 = t.고객번호;

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(c)
           no_batch_table_access_by_rowid(거래@subq) */
    c.고객번호, c.고객명
from 고객 c
where c.가입일시 >= trunc(add_months(sysdate, -1), 'mm')
and exists (
    select /*+ unnest hash_sj qb_name(subq) */ 'x'
    from 거래
    where 고객번호 = c.고객번호
    and 거래일시 >= trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display);

drop table 거래;
drop table 고객;
--------------------------------------------------------------------------------
-- rownum - 잘 쓰면 약, 잘못 쓰면 독
--------------------------------------------------------------------------------
create table 게시판(
    글번호 number(10),
    제목 varchar2(10),
    작성자 varchar2(10),
    등록일시 timestamp,
    게시판구분 varchar2(10)
);

create index 게시판_idx on 게시판(게시판구분, 등록일시);

create table 수신대상자(
    글번호 number(10),
    수신자 number(10),
    수신대상자 number(10)
);

explain plan for
select /*+ no_batch_table_access_by_rowid(게시판) */
    글번호, 제목, 작성자, 등록일시
from 게시판
where 게시판구분 = '공지'
and 등록일시 >= trunc(sysdate-1)
and rownum <= :n;

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(b) */
    글번호, 제목, 작성자, 등록일시
from 게시판 b
where 게시판구분 = '공지'
and 등록일시 >= trunc(sysdate - 1)
and exists (
    select 'x'
    from 수신대상자
    where 글번호 = b.글번호
    and 수신자 = :memb_no
    and rownum <= 1
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(b) */
    글번호, 제목, 작성자, 등록일시
from 게시판 b
where 게시판구분 = '공지'
and 등록일시 >= trunc(sysdate - 1)
and exists (
    select 'x'
    from 수신대상자
    where 글번호 = b.글번호
    and 수신자 = :memb_no
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(b) */
    글번호, 제목, 작성자, 등록일시
from 게시판 b
where 게시판구분 = '공지'
and 등록일시 >= trunc(sysdate - 1)
and exists (
    select /*+ unnest nl_sj */ 'x'
    from 수신대상자
    where 글번호 = b.글번호
    and 수신자 = :memb_no
    and rownum <= 1
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(b) */
    글번호, 제목, 작성자, 등록일시
from 게시판 b
where 게시판구분 = '공지'
and 등록일시 >= trunc(sysdate - 1)
and exists (
    select /*+ unnest nl_sj */ 'x'
    from 수신대상자
    where 글번호 = b.글번호
    and 수신자 = :memb_no
);

select * from table(dbms_xplan.display);

drop table 수신대상자;
drop table 게시판;
--------------------------------------------------------------------------------
-- 서브쿼리 pushing
--------------------------------------------------------------------------------
create table 상품분류(
    상품분류코드 varchar2(2) constraint 상품분류_pk primary key,
    상위분류코드 varchar2(2)
);

create table 상품(
    상품번호 number(10) constraint 상품_pk primary key,
    상품분류코드 varchar2(2) constraint 상품분류코드_fk references 상품분류(상품분류코드),
    등록일시 timestamp
);

create table 주문(
    상품번호 number(10) constraint 주문_fk references 상품(상품번호),
    주문일시 timestamp,
    주문금액 number(10),
    constraint 주문_pk primary key (상품번호, 주문일시)
);

explain plan for
select /*+ leading(p) use_nl(t)
           index(t) no_nlj_prefetch(t) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(t) */
    count(distinct p.상품번호), sum(t.주문금액)
from 상품 p, 주문 t
where p.상품번호 = t.상품번호
and p.등록일시 >= trunc(add_months(sysdate, -3), 'mm')
and t.주문일시 >= trunc(sysdate - 7)
and exists (
    select /*+ no_unnest no_push_subq */ 'x' from 상품분류
    where 상품분류코드 = p.상품분류코드
    and 상위분류코드 = 'AK'
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(p) use_nl(t)
           index(t) no_nlj_prefetch(t) opt_param('_nlj_batching_enabled', 0)
           no_batch_table_access_by_rowid(t) */
    count(distinct p.상품번호), sum(t.주문금액)
from 상품 p, 주문 t
where p.상품번호 = t.상품번호
and p.등록일시 >= trunc(add_months(sysdate, -3), 'mm')
and t.주문일시 >= trunc(sysdate - 7)
and exists (
    select /*+ no_unnest push_subq */ 'x' from 상품분류
    where 상품분류코드 = p.상품분류코드
    and 상위분류코드 = 'AK'
);

select * from table(dbms_xplan.display);

drop table 주문;
drop table 상품;
drop table 상품분류;
--------------------------------------------------------------------------------
-- 4.4.3 뷰(view)와 조인
--------------------------------------------------------------------------------
