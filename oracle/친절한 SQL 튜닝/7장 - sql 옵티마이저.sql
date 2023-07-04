--------------------------------------------------------------------------------
-- 7장 - sql 옵티마이저
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 7.1 통계정보와 비용 계산 원리
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 7.1.2 통계정보
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 테이블 통계
--------------------------------------------------------------------------------
begin
    dbms_stats.gather_table_stats('scott', 'emp');
end;
/

select num_rows, blocks, avg_row_len, sample_size, last_analyzed
from all_tables
where owner = 'SCOTT'
and table_name = 'EMP';
--------------------------------------------------------------------------------
-- 인덱스 통계
--------------------------------------------------------------------------------
create index emp_x01 on emp(job);

begin
    dbms_stats.gather_index_stats(ownname => 'scott', indname => 'emp_x01');
end;
/

begin
    dbms_stats.gather_table_stats('scott', 'emp', cascade => true);
end;
/

select blevel, leaf_blocks, num_rows, distinct_keys,
       avg_leaf_blocks_per_key, avg_data_blocks_per_key, clustering_factor,
       sample_size, last_analyzed
from all_indexes
where owner = 'SCOTT'
and table_name = 'EMP'
and index_name = 'EMP_X01';

drop index emp_x01;
--------------------------------------------------------------------------------
-- 컬럼 통계
--------------------------------------------------------------------------------
select num_distinct, density, avg_col_len, low_value, high_value, num_nulls,
       last_analyzed, sample_size
from all_tab_columns
where owner = 'SCOTT'
and table_name = 'EMP'
and column_name = 'DEPTNO';
--------------------------------------------------------------------------------
-- 컬럼 히스토그램
--------------------------------------------------------------------------------
begin
    dbms_stats.gather_table_stats('scott', 'emp', cascade => false,
        method_opt => 'for columns ename size 10, deptno size 4');
end;
/

begin
    dbms_stats.gather_table_stats('scott', 'emp', cascade => false,
        method_opt => 'for all columns size 75');
end;
/

begin
    dbms_stats.gather_table_stats('scott', 'emp', cascade => false,
        method_opt => 'for all columns size auto');
end;
/

select endpoint_value, endpoint_number
from all_histograms
where owner = 'SCOTT'
and table_name = 'EMP'
and column_name = 'DEPTNO'
order by endpoint_value;
--------------------------------------------------------------------------------
-- 시스템 통계
--------------------------------------------------------------------------------
select sname, pname, pval1, pval2 from sys.aux_stats$;
--------------------------------------------------------------------------------
-- 7.2 옵티마이저에 대한 이해
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 7.2.1 옵티마이저 종류
--------------------------------------------------------------------------------
create table 고객(
    고객id varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    고객유형코드 varchar2(6)
);

create index 고객_x11 on 고객(고객유형코드);

explain plan for
select * from 고객
where 고객유형코드 = 'CC0123';

select * from table(dbms_xplan.display);

create index 고객_x22 on 고객(고객명);

explain plan for
select * from 고객
order by 고객명;

select * from table(dbms_xplan.display);

drop table 고객;

create table 사원(
    사원id varchar2(10) constraint 사원_pk primary key,
    사원명 varchar2(10) not null,
    연령 number,
    연봉 number
);

create index 사원_x11 on 사원(연령);
create index 사원_x22 on 사원(연봉);

explain plan for
select * from 사원
where 연령 >= 60
and 연봉 between 3000 and 6000;

select * from table(dbms_xplan.display);

drop table 사원;
--------------------------------------------------------------------------------
-- 7.2.2 옵티마이저 모드
--------------------------------------------------------------------------------
alter session set optimizer_mode = first_rows_1;
alter session set optimizer_mode = first_rows_10;
alter session set optimizer_mode = first_rows_100;
alter session set optimizer_mode = first_rows_1000;

create table t(
    col1 number,
    col2 number,
    col3 number
);

create index t_x1 on t(col1);

explain plan for
select /*+ first_rows(30) */ col1, col2, col3
from t
where col1 > 10 and col2 > 20 and col3 > 30;

select * from table(dbms_xplan.display);

drop table t;
--------------------------------------------------------------------------------
-- 7.2.3 옵티마이저에 영향을 미치는 요소
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 옵티마이저 관련 파라미터
--------------------------------------------------------------------------------
select name, value, isdefault, default_value
from v$sys_optimizer_env;
--------------------------------------------------------------------------------
-- 7.2.5 개발자의 역할
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 필요한 최소 블록만 읽도록 쿼리 작성
--------------------------------------------------------------------------------
create table 회원(
    회원번호 number constraint 회원_pk primary key,
    회원명 varchar2(10)
);

create table 게시판유형(
    게시판유형 varchar2(5) constraint 게시판유형_pk primary key,
    게시판유형명 varchar2(10)
);

create table 질문유형(
    질문유형 varchar2(5) constraint 질문유형_pk primary key,
    질문유형명 varchar2(10),
    질문유형코드 varchar2(5)
);

create table 게시판(
    번호 number constraint 게시판_pk primary key,
    등록일자 varchar2(8),
    제목 varchar2(10),
    작성자번호 number constraint 회원_fk references 회원(회원번호),
    게시판유형 varchar2(5) constraint 게시판_fk references 게시판유형(게시판유형),
    질문유형 varchar2(5) constraint 질문유형_fk references 질문유형(질문유형)
);

create index 게시판_x11 on 게시판(작성자번호, 게시판유형, 질문유형, 등록일자);

create table 댓글(
    게시판번호 number constraint 댓글_게시판_fk references 게시판(번호),
    댓글번호 number,
    회원번호 number constraint 댓글_회원_fk references 회원(회원번호),
    댓글내용 varchar2(10),
    constraint 댓글_pk primary key (게시판번호, 댓글번호)
);

create or replace function get_icon(code varchar2) return varchar2
as
    v_icon varchar2(10);
begin
    return code || 'icon';
end;
/

explain plan for
select *
from (
    select rownum no, 등록일자, 번호, 제목, 회원명,
           게시판유형명, 질문유형명, 아이콘, 댓글개수
    from (
        select a.등록일자, a.번호, a.제목, b.회원명, c.게시판유형명, d.질문유형명,
               get_icon(d.질문유형코드) 아이콘,
               (select count(댓글번호) from 댓글 e
                where e.게시판번호 = a.번호) 댓글개수
        from 게시판 a, 회원 b, 게시판유형 c, 질문유형 d
        where a.게시판유형 = :type
        and b.회원번호 = a.작성자번호
        and c.게시판유형 = a.게시판유형
        and d.질문유형 = a.질문유형
        order by a.등록일자 desc, a.질문유형, a.번호)
    where rownum <= (:page * 10)
) where no >= (:page - 1) * 10 + 1;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_nl(b) use_nl(c) use_nl(d) */
    a.등록일자, a.번호, a.제목, b.회원명, c.게시판유형명, d.질문유형명,
    get_icon(d.질문유형코드) 아이콘,
    (select count(댓글번호) from 댓글 e
     where e.게시판번호 = a.번호) 댓글개수
from (
    select a.*, rownum no
    from (
        select 등록일자, 번호, 제목, 작성자번호, 게시판유형, 질문유형
        from 게시판
        where 게시판유형 = :type
        and 작성자번호 is not null
        and 게시판유형 is not null
        and 질문유형 is not null
        order by 등록일자 desc, 질문유형, 번호) a
    where rownum <= (:page * 10)
) a, 회원 b, 게시판유형 c, 질문유형 d
where a.no >= (:page - 1) * 10 + 1
and b.회원번호 = a.작성자번호
and c.게시판유형 = a.게시판유형
and d.질문유형 = a.질문유형
order by a.등록일자 desc, a.질문유형, a.번호;

select * from table(dbms_xplan.display);

drop table 댓글;
drop table 게시판;
drop table 게시판유형;
drop table 질문유형;
drop table 회원;
drop function get_icon;