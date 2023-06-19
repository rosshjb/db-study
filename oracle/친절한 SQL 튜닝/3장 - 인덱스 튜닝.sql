--------------------------------------------------------------------------------
-- 3장 - 인덱스 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.1 테이블 액세스 최소화
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.1.1 테이블 랜덤 액세스
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 인덱스 rowid는 물리적 주소? 논리적 주소?
--------------------------------------------------------------------------------
create table 고객(
    고객명 varchar2(10) not null,
    지역 varchar2(10) not null
);

create index 고객_지역_idx on 고객(지역);

explain plan for 
select /*+ no_batch_table_access_by_rowid(고객) */ *
from 고객 where 지역 = '서울';

select * from table(dbms_xplan.display());

drop table 고객;
--------------------------------------------------------------------------------
-- 3.1.3 인덱스 손익분기점
--------------------------------------------------------------------------------
create table big_table
as select level no from dual connect by level <= 100000;

select /*+ full(t) */ count(*) from big_table t where no <= 1;
select /*+ full(t) */ count(*) from big_table t where no <= 10;
select /*+ full(t) */ count(*) from big_table t where no <= 100;
select /*+ full(t) */ count(*) from big_table t where no <= 1000;
select /*+ full(t) */ count(*) from big_table t where no <= 10000;
select /*+ full(t) */ count(*) from big_table t where no <= 100000;

drop table big_table;
--------------------------------------------------------------------------------
-- 온라인 프로그램 튜닝 vs. 배치 프로그램 튜닝 (todo)
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    실명확인번호 number(10) not null,
    고객구분코드 varchar2(4) not null
);

create index 고객_x01 on 고객(실명확인번호);
create index 고객_x02 on 고객(고객구분코드);

create table 고객변경이력(
    고객번호 number(10) not null,
    변경일시 date not null,
    전화번호 varchar2(10) not null,
    주소 varchar2(10) not null,
    상태코드 varchar2(10) not null,
    constraint 고객변경이력_pk primary key(고객번호, 변경일시)
);

-- todo : 실행계획 똑같이 안나옴
explain plan for
select /*+ leading(c) index(c 고객_x01) no_batch_table_access_by_rowid(c) */ c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c, 고객변경이력 h
where c.실명확인번호 = :rmnno
and h.고객번호 = c.고객번호
and h.변경일시 = (
    select /*+ index(m 고객변경이력_pk) no_unnest push_subq */ max(변경일시)
    from 고객변경이력 m
    where 고객번호 = c.고객번호
    and 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and 변경일시 < trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display());

create table 고객_임시(
    고객번호 number(10) not null,
    고객명 varchar2(10) not null,
    변경일시 date not null,
    전화번호 varchar2(10) not null,
    주소 varchar2(10) not null,
    상태코드 varchar2(10) not null,
    constraint 고객_임시_pk primary key(고객번호, 변경일시)
);

-- todo : 실행계획 똑같이 안나옴
explain plan for
insert into 고객_임시
select /*+ leading(c) index(c 고객_x02) no_batch_table_access_by_rowid(c) */
    c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c, 고객변경이력 h
where c.고객구분코드 = 'A001'
and h.고객번호 = c.고객번호
and h.변경일시 = (
    select /*+ index(m 고객변경이력_pk) no_unnest push_subq */ max(변경일시)
    from 고객변경이력 m
    where 고객번호 = c.고객번호
    and 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and 변경일시 < trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display());

explain plan for
insert into 고객_임시
select /*+ full(c) full(h) index_ffs(m.고객변경이력)
           ordered no_merge(m) use_hash(m) use_hash(h) */
    c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c,
    (
        select 고객번호, max(변경일시) 최종변경일시
        from 고객변경이력
        where 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
        and 변경일시 < trunc(sysdate, 'mm')
        group by 고객번호
    ) m,
    고객변경이력 h
where c.고객구분코드 = 'A001'
and m.고객번호 = c.고객번호
and h.고객번호 = m.고객번호
and h.변경일시 = m.최종변경일시;

select * from table(dbms_xplan.display());

explain plan for
insert into 고객_임시
select 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시
from (
    select /*+ full(c) full(h) leading(c) use_hash(h) */
        c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시,
        rank() over (partition by h.고객번호 order by h.변경일시 desc) no
    from 고객 c, 고객변경이력 h
    where c.고객구분코드 = 'A001'
    and h.변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and h.변경일시 < trunc(sysdate, 'mm')
    and h.고객번호 = c.고객번호)
where no = 1;

select * from table(dbms_xplan.display());

drop table 고객_임시;
drop table 고객변경이력;
drop table 고객;
--------------------------------------------------------------------------------
-- 3.1.4 인덱스 컬럼 추가
--------------------------------------------------------------------------------
create index emp_x01 on emp(deptno, job);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(emp)
           index(emp emp_x01) */ *
from emp
where deptno = 30
and sal >= 2000;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

select /*+ gather_plan_statistics index(emp emp_x01) */ *
from emp where deptno = 30 and job = 'CLERK';

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop index emp_x01;
create index emp_x01 on emp(deptno, job, sal);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(emp)
           index(emp emp_x01) */ *
from emp
where deptno = 30
and sal >= 2000;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop index emp_x01;

create table 로밍렌탈(
    렌탈관리번호 number(10) primary key,
    고객명 varchar2(10),
    서비스관리번호 number(10),
    서비스번호 varchar2(12) not null,
    예약접수일시 date,
    방문국가코드1 varchar2(10), 방문국가코드2 varchar2(10), 방문국가코드3 varchar2(10),
    로밍승인번호 number(10),
    자동로밍여부 varchar2(1),
    사용여부 varchar2(1)
);

create index 로밍렌탈_n2 on 로밍렌탈(서비스번호);

explain plan for
select 렌탈관리번호, 고객명, 서비스관리번호, 서비스번호, 예약접수일시,
       방문국가코드1, 방문국가코드2, 방문국가코드3, 로밍승인번호, 자동로밍여부
from 로밍렌탈
where 서비스번호 like '010%' and 사용여부 = 'Y';

select * from table(dbms_xplan.display());

drop index 로밍렌탈_n2;
create index 로밍렌탈_n2 on 로밍렌탈(서비스번호, 사용여부);

explain plan for
select 렌탈관리번호, 고객명, 서비스관리번호, 서비스번호, 예약접수일시,
       방문국가코드1, 방문국가코드2, 방문국가코드3, 로밍승인번호, 자동로밍여부
from 로밍렌탈
where 서비스번호 like '010%' and 사용여부 = 'Y';

select * from table(dbms_xplan.display());

drop table 로밍렌탈;
--------------------------------------------------------------------------------
-- 3.1.5 인덱스만 읽고 처리
--------------------------------------------------------------------------------
create table 판매집계(
    부서번호 varchar2(10) constraint 판매집계_pk primary key,
    수량 number(10) not null
);

explain plan for
select /*+ index(판매집계 판매집계_pk) */ 부서번호, sum(수량)
from 판매집계 where 부서번호 like '12%'
group by 부서번호;

select * from table(dbms_xplan.display(format => 'advanced'));

alter table 판매집계 drop constraint 판매집계_pk;
alter table 판매집계 add constraint 판매집계_pk primary key (부서번호, 수량);

explain plan for
select /*+ index(판매집계 판매집계_pk) */ 부서번호, sum(수량)
from 판매집계 where 부서번호 like '12%'
group by 부서번호;

select * from table(dbms_xplan.display(format => 'advanced'));

drop table 판매집계;
--------------------------------------------------------------------------------
-- 3.1.6 인덱스 구조 테이블
--------------------------------------------------------------------------------
create table index_org_t(
    a number,
    b varchar(10),
    constraint index_org_t_pk primary key (a)
) organization index;

create table heap_org_t(
    a number,
    b varchar(10),
    constraint heap_org_t_pk primary key (a)
) organization heap;

drop table heap_org_t;
drop table index_org_t;

create table 영업실적_heap(
    사번 varchar2(5),
    일자 varchar2(8),
    판매금액 number(10) default 0 not null,
    constraint 영업실적_heap_pk primary key (사번, 일자)
) organization heap;

explain plan for
select substr(일자, 1, 6) 월도, sum(판매금액) 총판매금액, avg(판매금액) 평균판매금액
from 영업실적_heap where 사번 = 'S1234' and 일자 between '20180101' and '20181231'
group by substr(일자, 1, 6);

select * from table(dbms_xplan.display(format => 'advanced'));

create table 영업실적_index(
    사번 varchar2(5),
    일자 varchar2(8),
    판매금액 number(10) default 0 not null,
    constraint 영업실적_index_pk primary key (사번, 일자)
) organization index;

explain plan for
select substr(일자, 1, 6) 월도, sum(판매금액) 총판매금액, avg(판매금액) 평균판매금액
from 영업실적_index where 사번 = 'S1234' and 일자 between '20180101' and '20181231'
group by substr(일자, 1, 6);

select * from table(dbms_xplan.display(format => 'advanced'));

drop table 영업실적_heap;
drop table 영업실적_index;
--------------------------------------------------------------------------------
-- 3.1.7 클러스터 테이블
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 인덱스 클러스터 테이블
--------------------------------------------------------------------------------
create cluster c_dept#(
    deptno number(2)
) index;

create index c_dept#_idx on cluster c_dept#;

create table c_dept(
    deptno number(2) not null,
    dname varchar2(14) not null,
    loc varchar2(13)
) cluster c_dept#(deptno);

explain plan for
select * from c_dept where deptno = :deptno;

select * from table(dbms_xplan.display(format => 'advanced'));

drop table c_dept;
drop index c_dept#_idx;
drop cluster c_dept#;
--------------------------------------------------------------------------------
-- 해시 클러스터 테이블
--------------------------------------------------------------------------------
create cluster c_dept#(
    deptno number(2)
) hashkeys 4;

create table c_dept(
    deptno number(2) not null,
    dname varchar2(14) not null,
    loc varchar2(13)
) cluster c_dept#(deptno);

explain plan for
select * from c_dept where deptno = :deptno;

select * from table(dbms_xplan.display(format => 'advanced'));

drop table c_dept;
drop cluster c_dept#;
--------------------------------------------------------------------------------
-- 3.2 부분범위 처리 활용
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.2.1 부분범위 처리
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 쿼리 툴에서 부분범위 처리
--------------------------------------------------------------------------------
create table big_table as
select * from dba_objects, (select level no from dual connect by level <= 100);

select * from big_table;

show arraysize;

select object_id, object_name from big_table;

drop table big_table;
--------------------------------------------------------------------------------
-- 3.2.3 OLTP 환경에서 부분범위 처리에 의한 성능개선 원리
--------------------------------------------------------------------------------
create table 게시판(
    게시글id varchar2(10) constraint 게시판_pk primary key,
    제목 varchar2(10) not null,
    작성자 varchar2(10) not null,
    등록일시 timestamp not null,
    게시판구분코드 varchar2(1) not null
);

create index 게시판_x01 on 게시판(게시판구분코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(게시판) index(게시판 게시판_x01) */
    게시글id, 제목, 작성자, 등록일시
from 게시판
where 게시판구분코드 = 'A'
order by 등록일시 desc;

select * from table(dbms_xplan.display());

create index 게시판_x02 on 게시판(게시판구분코드, 등록일시);

explain plan for
select /*+ no_batch_table_access_by_rowid(게시판) index_rs_desc(게시판 게시판_x02) */
    게시글id, 제목, 작성자, 등록일시
from 게시판
where 게시판구분코드 = 'A'
order by 등록일시 desc;

select * from table(dbms_xplan.display());

drop table 게시판;
--------------------------------------------------------------------------------
-- 배치 I/O
--------------------------------------------------------------------------------
create index emp_x01 on emp(deptno, job, empno);

set autotrace traceonly explain;

select * from emp e where deptno = 20 order by job, empno;

select /*+ batch_table_access_by_rowid(e) */ *
from emp e where deptno = 20 order by job, empno;

select /*+ index_rs_asc(e emp_x01) */ *
from emp e where deptno = 20 order by empno;

select /*+ index(e emp_x01) */ * from emp e where deptno = 20;

drop index emp_x01;

set autotrace off;

create table 상태변경이력(
    장비번호 number(10) not null,
    장비명 varchar2(10) not null,
    변경일시 date not null,
    상태코드 varchar2(10) not null,
    장비구분코드 varchar2(4) not null,
    constraint 상태변경이력_pk primary key (장비번호, 변경일시)
);

explain plan for
select /*+ index(h 상태변경이력_pk) */ 장비번호, 변경일시, 상태코드
from 상태변경이력 h
where 장비번호 = :eqp_no
and rownum <= 10;

select * from table(dbms_xplan.display());

create table 장비(
    장비번호 number(10) constraint 장비_pk primary key,
    장비명 varchar2(10) not null,
    상태코드 varchar2(10) not null,
    장비구분코드 varchar2(4) not null
);

explain plan for
select 장비번호, 장비명, 상태코드,
       (select /*+ index_desc(h 상태변경이력_pk) */ 변경일시
        from 상태변경이력 h
        where 장비번호 = p.장비번호
        and rownum <= 1) 최종변경일시
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(h 상태변경이력_pk) */ 장비번호, 변경일시, 상태코드
from 상태변경이력 h
where 장비번호 = :eqp_no;

select * from table(dbms_xplan.display());

drop table 장비;
drop table 상태변경이력;
--------------------------------------------------------------------------------
-- 3.3 인덱스 스캔 효율화
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.3.1 인덱스 탐색
--------------------------------------------------------------------------------
create table tt(
    c1 varchar2(1) not null,
    c2 number(1) not null
);

create index tt_x01 on tt(c1, c2);

explain plan for
select * from tt where c1 = 'B';

select * from table(dbms_xplan.display());

explain plan for
select * from tt where c1 = 'B' and c2 = 3;

select * from table(dbms_xplan.display());

explain plan for
select * from tt where c1 = 'B' and c2 >= 3;

select * from table(dbms_xplan.display());

explain plan for
select * from tt where c1 = 'B' and c2 <= 3;

select * from table(dbms_xplan.display());

explain plan for
select * from tt where c1 = 'B' and c2 between 2 and 3;

select * from table(dbms_xplan.display());

explain plan for
select * from tt where c1 between 'A' and 'C' and c2 between 2 and 3;

select * from table(dbms_xplan.display());

drop table tt;
--------------------------------------------------------------------------------
-- 3.3.2 인덱스 스캔 효율성
--------------------------------------------------------------------------------
create table tt(
    c1 varchar2(1 char) not null,
    c2 varchar2(1 char) not null,
    c3 varchar2(1 char) not null,
    c4 varchar2(1 char) not null
);

create index tt_x01 on tt(c1, c2, c3, c4);

explain plan for
select * from tt
where c1 = '성' and c2 = '능' and c3 = '검';

select * from table(dbms_xplan.display());

explain plan for
select * from tt
where c1 = '성' and c2 = '능' and c4 = '선';

select * from table(dbms_xplan.display());

drop table tt;
--------------------------------------------------------------------------------
-- 3.3.4 비교 연산자 종류와 컬럼 순서에 따른 군집성
--------------------------------------------------------------------------------
create table tt(
    c1 number(1) not null,
    c2 varchar2(1 char) not null,
    c3 varchar2(1 char) not null,
    c4 varchar2(1 char) not null
);

create index tt_x01 on tt(c1, c2, c3, c4);

explain plan for
select * from tt
where c1 = 1 and c2 = 'A' and c3 = '나' and c4 = 'a';

select * from table(dbms_xplan.display());

explain plan for
select * from tt
where c1 = 1 and c2 = 'A' and c3 = '나' and c4 >= 'a';

select * from table(dbms_xplan.display());

explain plan for
select * from tt
where c1 = 1 and c2 = 'A' and c3 between '가' and '다' and c4 = 'a';

select * from table(dbms_xplan.display());

explain plan for
select * from tt
where c1 = 1 and c2 <= 'B' and c3 = '나' and c4 between 'a' and 'b';

select * from table(dbms_xplan.display());

explain plan for
select * from tt
where c1 between 1 and 3 and c2 = 'A' and c3 = '나' and c4 = 'a';

select * from table(dbms_xplan.display());

drop table tt;
--------------------------------------------------------------------------------
-- 3.3.5 인덱스 선행 컬럼이 등치(=) 조건이 아닐 때 생기는 비효율
--------------------------------------------------------------------------------
create table 매물아파트매매(
    해당층 number(10),
    평당가 varchar2(10),
    입력일 date,
    해당동 varchar2(10),
    매물구분 varchar2(1),
    연사용일수 number(10),
    중개업소코드 varchar2(10),
    아파트시세코드 varchar2(20),
    평형 varchar2(2),
    평형타입 varchar2(1),
    인터넷매물 varchar2(1),
    constraint 매물아파트매매_pk primary key (아파트시세코드, 평형, 평형타입, 인터넷매물)
);

insert into 매물아파트매매(인터넷매물, 아파트시세코드, 평형, 평형타입) values ('1', 'A01011350900056', '59', 'A');
insert into 매물아파트매매(인터넷매물, 아파트시세코드, 평형, 평형타입) values ('2', 'A01011350900056', '59', 'A');
insert into 매물아파트매매(인터넷매물, 아파트시세코드, 평형, 평형타입) values ('3', 'A01011350900056', '59', 'A');
commit;

explain plan for
select /*+ no_batch_table_access_by_rowid(매물아파트매매) index(매물아파트매매) */
    해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A' and 인터넷매물 between '1' and '3'
order by 입력일 desc;

select * from table(dbms_xplan.display());

alter table 매물아파트매매 drop constraint 매물아파트매매_pk;
alter table 매물아파트매매 add constraint 매물아파트매매_pk primary key (인터넷매물, 아파트시세코드, 평형, 평형타입);

explain plan for
select /*+ no_batch_table_access_by_rowid(매물아파트매매) index(매물아파트매매) */
    해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 인터넷매물 between '1' and '3' and 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A'
order by 입력일 desc;

select * from table(dbms_xplan.display());
--------------------------------------------------------------------------------
-- 3.3.6 between을 in-list로 전환
--------------------------------------------------------------------------------
select /*+ no_batch_table_access_by_rowid(매물아파트매매) gather_plan_statistics index(매물아파트매매) */
    해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 인터넷매물 in ('1', '2', '3')
and 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A'
order by 입력일 desc;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

select /*+ no_batch_table_access_by_rowid(매물아파트매매) gather_plan_statistics index(매물아파트매매) */
    해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 인터넷매물 = '1' and 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A'
union all
select 해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 인터넷매물 = '2' and 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A'
union all
select 해당층, 평당가, 입력일, 해당동, 매물구분, 연사용일수, 중개업소코드
from 매물아파트매매
where 인터넷매물 = '3' and 아파트시세코드 = 'A01011350900056' and 평형 = '59' and 평형타입 = 'A'
order by 입력일 desc;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

create table 통합코드(
    코드구분 varchar2(5),
    코드 varchar2(10),
    constraint 통합코드_pk primary key (코드구분, 코드)
);

insert into 통합코드(코드구분, 코드) values ('CD064', '1');
insert into 통합코드(코드구분, 코드) values ('CD064', '2');
insert into 통합코드(코드구분, 코드) values ('CD064', '3');
commit;

select /*+ ordered use_nl(b) gather_plan_statistics no_index_ffs(a) index(a) */
    b.해당층, b.평당가, b.입력일, b.해당동, b.매물구분, b.연사용일수, b.중개업소코드
from 통합코드 a, 매물아파트매매 b
where a.코드구분 = 'CD064' -- 인터넷매물구분
and a.코드 between '1' and '3'
and b.인터넷매물 = a.코드
and b.아파트시세코드 = 'A01011350900056' and b.평형 = '59' and b.평형타입 = 'A'
order by b.입력일 desc;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop table 통합코드;

drop table 매물아파트매매;
--------------------------------------------------------------------------------
-- between 조건을 in-list로 전환할 때 주의 사항
--------------------------------------------------------------------------------
create table 고객(
    고객등급 varchar2(1),
    고객번호 number(10),
    constraint 고객_pk primary key (고객등급, 고객번호)
);

select /*+ gather_plan_statistics */ * from 고객
where 고객등급 between 'C' and 'D'
and 고객번호 = 123;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

select /*+ gather_plan_statistics */ * from 고객
where 고객등급 in ('C', 'D')
and 고객번호 = 123;

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop table 고객;
--------------------------------------------------------------------------------
-- 3.3.7 index skip scan 활용
--------------------------------------------------------------------------------
create table 월별고객별판매집계
as
select rownum 고객번호,
       '2018' || lpad(ceil(rownum/100000), 2, '0') 판매월,
       decode(mod(rownum, 12), 1, 'A', 'B') 판매구분,
       round(dbms_random.value(1000, 100000), -2) 판매금액
from dual
connect by level <= 1200000;

create index 월별고객별판매집계_idx1 on 월별고객별판매집계(판매구분, 판매월);

select /*+ gather_plan_statistics no_index_ffs(t) index(t 월별고객별판매집계_idx1) */ count(*)
from 월별고객별판매집계 t
where 판매구분 = 'A'
and 판매월 between '201801' and '201812';

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

create index 월별고객별판매집계_idx2 on 월별고객별판매집계(판매월, 판매구분);

select /*+ gather_plan_statistics no_index_ss(t) index(t 월별고객별판매집계_idx2) */ count(*)
from 월별고객별판매집계 t
where 판매월 between '201801' and '201812'
and 판매구분 = 'A';

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

select /*+ gather_plan_statistics index(t 월별고객별판매집계_idx2) */ count(*)
from 월별고객별판매집계 t
where 판매월 in ('201801', '201802', '201803', '201804', '201805', '201806',
                '201807', '201808', '201809', '201810', '201811', '201812')
and 판매구분 = 'A';

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

select /*+ gather_plan_statistics index_ss(t 월별고객별판매집계_idx2) */ count(*)
from 월별고객별판매집계 t
where 판매월 between '201801' and '201812'
and 판매구분 = 'A';

select * from table(dbms_xplan.display_cursor(format => 'advanced allstats last'));

drop table 월별고객별판매집계;
--------------------------------------------------------------------------------
-- 3.3.8 in 조건은 '='인가
--------------------------------------------------------------------------------
create table 고객별가입상품(
    고객번호 number(10),
    상품id varchar2(7),
    가입일자 date
);

create index 고객별가입상품_x1 on 고객별가입상품(상품id, 고객번호);

explain plan for
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ * from 고객별가입상품
where 고객번호 = :cust_no
and 상품id in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ * from 고객별가입상품
where 고객번호 = :cust_no
and 상품id = 'NH00037'
union all
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ * from 고객별가입상품
where 고객번호 = :cust_no
and 상품id = 'NH00041'
union all
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ * from 고객별가입상품
where 고객번호 = :cust_no
and 상품id = 'NH00050';

select * from table(dbms_xplan.display());

drop index 고객별가입상품_x1;

create index 고객별가입상품_x1 on 고객별가입상품(고객번호, 상품id);

explain plan for
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ * from 고객별가입상품
where 고객번호 = :cust_no
and 상품id in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

drop table 고객별가입상품;
--------------------------------------------------------------------------------
-- 더 쉬운 예
--------------------------------------------------------------------------------
create table 상품(
    상품id varchar2(7) constraint 상품_pk primary key,
    상품구분코드 varchar2(2),
    상품명 varchar2(10)
);

create index 상품_x01 on 상품(상품id, 상품구분코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(상품) */ * from 상품
where 상품id = :prod_id
and 상품구분코드 in ('GX', 'KR');

select * from table(dbms_xplan.display());

drop table 상품;
--------------------------------------------------------------------------------
-- num_index_keys 힌트 활용
--------------------------------------------------------------------------------
create table 고객별가입상품(
    고객번호 number(10),
    상품id varchar2(7),
    가입일자 date
);

create index 고객별가입상품_x1 on 고객별가입상품(고객번호, 상품id);

explain plan for
select /*+ num_index_keys(a 고객별가입상품_x1 1) no_batch_table_access_by_rowid(a) */ *
from 고객별가입상품 a
where 고객번호 = :cust_no
and 상품id in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ *
from 고객별가입상품
where 고객번호 = :cust_no
and rtrim(상품id) in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(고객별가입상품) */ *
from 고객별가입상품
where 고객번호 = :cust_no
and 상품id || '' in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

explain plan for
select /*+ num_index_keys(a 고객별가입상품_x1 2) no_batch_table_access_by_rowid(a) */ *
from 고객별가입상품 a
where 고객번호 = :cust_no
and 상품id in ('NH00037', 'NH00041', 'NH00050');

select * from table(dbms_xplan.display());

drop table 고객별가입상품;
--------------------------------------------------------------------------------
-- 3.3.9 between과 like 스캔 범위 비교
--------------------------------------------------------------------------------
create table 월별고객별판매집계(
    판매월 varchar2(6),
    판매구분 varchar2(1),
    constraint 월별고객별판매집계_pk primary key (판매월, 판매구분)
);

explain plan for
select * from 월별고객별판매집계
where 판매월 between '201901' and '201912'
and 판매구분 = 'B';

select * from table(dbms_xplan.display());

explain plan for
select * from 월별고객별판매집계
where 판매월 like '2019%'
and 판매구분 = 'B';

select * from table(dbms_xplan.display());

explain plan for
select * from 월별고객별판매집계
where 판매월 between '201901' and '201912'
and 판매구분 = 'A';

select * from table(dbms_xplan.display());

explain plan for
select * from 월별고객별판매집계
where 판매월 like '2019%'
and 판매구분 = 'A';

select * from table(dbms_xplan.display());

drop table 월별고객별판매집계;
--------------------------------------------------------------------------------
-- 3.3.10 범위검색 조건을 남용할 때 생기는 비효율
--------------------------------------------------------------------------------
create table 가입상품(
    고객id varchar2(10) not null,
    회사코드 varchar2(3) not null,
    지역코드 varchar2(2) not null,
    상품명 varchar2(10) not null
);

create index 가입상품_x01 on 가입상품(회사코드, 지역코드, 상품명);

explain plan for
select /*+ no_batch_table_access_by_rowid(가입상품) */
    고객id, 상품명, 지역코드
from 가입상품
where 회사코드 = :com
and 지역코드 = :reg
and 상품명 like :prod || '%';

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(가입상품) */
    고객id, 상품명, 지역코드
from 가입상품
where 회사코드 = :com
and 상품명 like :prod || '%';

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(가입상품) */
    고객id, 상품명, 지역코드
from 가입상품
where 회사코드 = :com
and 지역코드 like :reg || '%'
and 상품명 like :prod || '%';

select * from table(dbms_xplan.display());

drop table 가입상품;

create table 일별종목거래(
    거래일자 date,
    종목코드 varchar2(6),
    투자자유형코드 varchar2(10),
    주문매체구분코드 varchar2(10),
    주문매체코드 varchar2(10),
    체결건수 number(10),
    체결수량 number(10),
    거래대금 number(10),
    constraint 일별종목거래_pk primary key (거래일자, 종목코드, 투자자유형코드, 주문매체구분코드)
);

explain plan for
select /*+ no_batch_table_access_by_rowid(일별종목거래) */
       거래일자, 종목코드, 투자자유형코드,
       주문매체코드, 체결건수, 체결수량, 거래대금
from 일별종목거래
where 거래일자 between :시작일자 and :종료일자
and 종목코드 between :종목1 and :종목2
and 투자자유형코드 between :투자자유형1 and :투자자유형2
and 주문매체구분코드 between :주문매체구분1 and :주문매체구분2;

select * from table(dbms_xplan.display());

drop table 일별종목거래;
--------------------------------------------------------------------------------
-- 3.3.11 다양한 옵션 조건 처리 방식의 장단점 비교
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- or 조건 활용
--------------------------------------------------------------------------------
create table 거래(
    거래id number(10) primary key,
    고객id number(10),
    거래일자 date,
    결제일자 date
);

create index 거래_idx3 on 거래(고객id, 거래일자);

explain plan for
select * from 거래
where (:cust_id is null or 고객id = :cust_id)
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display());

drop index 거래_idx3;

create index 거래_idx3 on 거래(거래일자, 고객id);

explain plan for
select * from 거래
where 거래일자 between :dt1 and :dt2
and (:cust_id is null or 고객id = :cust_id);

select * from table(dbms_xplan.display());

drop index 거래_idx3;

create index 거래_idx11 on 거래(고객id, 거래일자);
create index 거래_idx22 on 거래(고객id, 결제일자);

explain plan for
select /*+ use_concat no_batch_table_access_by_rowid(거래)
           index(거래@sel$1 거래_idx22) index(거래@sel$1_2 거래_idx11) */ * from 거래
where 고객id = :cust_id
and (
    (:dt_type = 'A' and 거래일자 between :dt1 and :dt2)
    or
    (:dt_type = 'B' and 결제일자 between :dt1 and :dt2)
);

select * from table(dbms_xplan.display(format => 'advanced'));

drop table 거래;
--------------------------------------------------------------------------------
-- like/between 조건 활용
--------------------------------------------------------------------------------
create table 상품(
    상품명 varchar2(10),
    상품대분류코드 varchar2(4),
    상품분류코드 varchar2(4),
    상품코드 varchar2(4),
    등록일시 date
);

create index 상품_idx11 on 상품(등록일시, 상품분류코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(상품) */ * from 상품
where 등록일시 >= trunc(sysdate)
and 상품분류코드 like :prd_cls_cd || '%';

select * from table(dbms_xplan.display());

drop index 상품_idx11;

create index 상품_idx11 on 상품(상품명, 상품분류코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(상품) */ * from 상품
where 상품명 = :prd_nm
and 상품분류코드 like :prd_cls_cd || '%';

select * from table(dbms_xplan.display());

drop index 상품_idx11;

create index 상품_idx11 on 상품(상품대분류코드, 상품코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(상품) */ * from 상품
where 상품대분류코드 = :prd_lcls_cd
and 상품코드 like :prd_cd || '%';

select * from table(dbms_xplan.display());

drop table 상품;

-- 인덱스 선두 컬럼
create table 거래(
    고객id varchar2(10),
    거래일자 date
);

create index tr_idx on 거래(고객id, 거래일자);

explain plan for
select * from 거래
where 고객id = :cust_id || '%'
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display());

drop index tr_idx;

create index tr_idx on 거래(거래일자, 고객id);

explain plan for
select * from 거래
where 거래일자 between :dt1 and :dt2
and 고객id = :cust_id || '%';

select * from table(dbms_xplan.display());

drop index tr_idx;
-- null 허용 컬럼
create index tr_idx on 거래(고객id, 거래일자);

explain plan for
select * from 거래
--where 고객id like :cust_id || '%'
where 고객id like '%'
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display());

select * from dual where null like :var || '%';

drop table 거래;
-- 숫자형 컬럼
create table 거래(
    거래일자 date,
    고객id number(10)
);

create index tr_idx on 거래(거래일자, 고객id);

explain plan for
select * from 거래
where 거래일자 = :trd_dt
and 고객id like :cust_id || '%';

select * from table(dbms_xplan.display);

drop table 거래;
-- 가변 길이 컬럼
create table 고객
as
select '김훈' 고객명 from dual
union all
select '김훈남' 고객명 from dual;

alter table 고객 add constraint 고객_pk primary key (고객명);

select /*+ gather_plan_statistics */ * from 고객
where 고객명 like :cust_nm || '%';

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */ * from 고객
where 고객명 like :cust_nm || '%'
and length(고객명) = length(nvl(:cust_nm, 고객명));

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */ * from 고객
where 고객명 like :cust_nm;

select * from table(dbms_xplan.display_cursor());

drop table 고객;
--------------------------------------------------------------------------------
-- union all 활용
--------------------------------------------------------------------------------
create table 거래(
    거래일자 date,
    고객id number(10),
    dummy varchar2(1)
);

create index 거래_idx11 on 거래(거래일자);
create index 거래_idx22 on 거래(고객id, 거래일자);

explain plan for
select /*+ no_batch_table_access_by_rowid(거래) index_rs(거래 거래_idx11) */ * from 거래
where :cust_id is null
and 거래일자 between :dt1 and :dt2
union all
select /*+ no_batch_table_access_by_rowid(거래) index_rs(거래 거래_idx22) */ * from 거래
where :cust_id is not null
and 고객id = :cust_id
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display());
--------------------------------------------------------------------------------
-- nvl/decode 함수 활용
--------------------------------------------------------------------------------
explain plan for
select /*+ no_batch_table_access_by_rowid(거래)
           index(@set$2a13af86_2 거래@set$2a13af86_2 거래_idx11)
           index(@SET$2a13af86_1 거래@set$2a13af86_1 거래_idx22) */ * from 거래
where 고객id = nvl(:cust_id, 고객id)
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display(format => '+alias'));

explain plan for
select /*+ no_batch_table_access_by_rowid(거래)
           index(@set$2a13af86_1 거래 거래_idx22)
           index(@set$2a13af86_2 거래 거래_idx11) */ * from 거래
where 고객id = decode(:cust_id, null, 고객id, :cust_id)
and 거래일자 between :dt1 and :dt2;

select * from table(dbms_xplan.display(format => '+alias'));

select * from dual where null = null;
select * from dual where null is null;

drop table 거래;
--------------------------------------------------------------------------------
-- 3.3.12 함수호출부하 해소를 위한 인덱스 구성
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- pl/sql 함수의 성능적 특성
--------------------------------------------------------------------------------
create table 회원(
    회원번호 number(10) constraint 회원_pk primary key,
    회원명 varchar2(10),
    생년 varchar2(10),
    생월일 varchar2(10),
    전화번호 varchar2(10),
    우편번호 varchar2(10)
);

create or replace function encryption(i_data in varchar2) return varchar2
is
    encrypted varchar2(100);
begin
    select standard_hash(i_data) into encrypted from dual;
    return encrypted;
end;
/

explain plan for
select 회원번호, 회원명, 생년, 생월일, encryption(전화번호)
from 회원
where 회원번호 = :member_no;

select * from table(dbms_xplan.display());

explain plan for
select 회원번호, 회원명, 생년, 생월일, encryption(전화번호)
from 회원
where 생월일 like '01%';

select * from table(dbms_xplan.display());

create table 기본주소(
    우편번호 varchar2(10),
    순번 number(10),
    시도 varchar2(100),
    구군 varchar2(100),
    읍면동 varchar2(100),
    constraint 기본주소_pk primary key (우편번호, 순번)
);

create or replace function get_addr(i_zip_code in varchar2) return varchar2
is
    addr varchar2(100);
begin
    select 시도 || ' ' || 구군 || ' ' || 읍면동
    into addr
    from 기본주소
    where 우편번호 = i_zip_code
    and 순번 = 1;

    return addr;
end;
/

explain plan for
select 회원번호, 회원명, 생년, 생월일, get_addr(우편번호) as 기본주소
from 회원
where 생월일 like '01%';

select * from table(dbms_xplan.display());

explain plan for
select a.회원번호, a.회원명, a.생년, a.생월일,
      (select b.시도 || ' ' || b.구군 || ' ' || b.읍면동
       from 기본주소 b
       where b.우편번호 = a.우편번호
       and b.순번 = 1) 기본주소
from 회원 a
where 생월일 like '01%';

select * from table(dbms_xplan.display());

explain plan for
select a.회원번호, a.회원명, a.생년, a.생월일,
       b.시도 || ' ' || b.구군 || ' ' || b.읍면동 as 기본주소
from 회원 a, 기본주소 b
where a.생월일 like '01%'
and b.우편번호(+) = a.우편번호
and b.순번(+) = 1;

select * from table(dbms_xplan.display());

drop function get_addr;

drop table 기본주소;
drop table 회원;
--------------------------------------------------------------------------------
-- 효과적인 인덱스 구성을 통한 함수 호출 최소화
--------------------------------------------------------------------------------
create table 회원(
    회원번호 number(10) constraint 회원_pk primary key,
    회원명 varchar2(10),
    생년 varchar2(4),
    생월일 varchar2(10),
    등록일자 date,
    암호화된_전화번호 varchar2(100)
);

explain plan for
select /*+ full(a) */ 회원번호, 회원명, 생년, 생월일, 등록일자
from 회원 a
where 암호화된_전화번호 = encryption(:phone_no);

select * from table(dbms_xplan.display());

explain plan for
select /*+ full(a) */ 회원번호, 회원명, 생년, 생월일, 등록일자
from 회원 a
where 생년 = '1987'
and 암호화된_전화번호 = encryption(:phone_no);

select * from table(dbms_xplan.display());

create index 회원_x011 on 회원(생년);
create index 회원_x022 on 회원(생년, 생월일, 암호화된_전화번호);
create index 회원_x033 on 회원(생년, 암호화된_전화번호);

explain plan for
select /*+ index(a 회원_x011) no_batch_table_access_by_rowid(a) */
    회원번호, 회원명, 생년, 생월일, 등록일자
from 회원 a
where 생년 = '1987'
and 암호화된_전화번호 = encryption(:phone_no);

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(a 회원_x022) no_batch_table_access_by_rowid(a) */
    회원번호, 회원명, 생년, 생월일, 등록일자
from 회원 a
where 생년 = '1987'
and 암호화된_전화번호 = encryption(:phone_no);

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(a 회원_x033) no_batch_table_access_by_rowid(a) */
    회원번호, 회원명, 생년, 생월일, 등록일자
from 회원 a
where 생년 = '1987'
and 암호화된_전화번호 = encryption(:phone_no);

select * from table(dbms_xplan.display());

drop function encryption;

drop table 회원;
--------------------------------------------------------------------------------
-- 3.4 인덱스 설계
--------------------------------------------------------------------------------
