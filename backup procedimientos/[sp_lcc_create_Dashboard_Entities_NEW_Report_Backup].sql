USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report_Backup]    Script Date: 29/05/2017 14:09:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report_Backup](
	@scope as varchar(256)
	,@database as varchar(256)
	,@table as varchar(256)
	,@group as bit
	,@report as varchar(256)
)
AS

-------------------------------------------------------------------------------
-- Inicialización de variables
--declare @scope as varchar(256) = 'MAIN CITIES'
--declare @database as varchar(256) = '[DASHBOARD]'
--declare @table as varchar(256)	= 'UPDATE_aggrvoice4g_lcc_aggr_sp_MDD_Voice_Llamadas'
--declare @group as bit =0
--declare @scope as varchar(256) = 'TOURISTIC AREA'
--declare @database as varchar(256) = '[DASHBOARD]'
--declare @table as varchar(256)	= 'UPDATE_AGGRVoice3G_lcc_aggr_sp_MDD_Voice_Llamadas'
--declare @group as bit =0
--declare @report as varchar(256) = 'VDF'

declare @entidad as varchar(256)
DECLARE @SQLString nvarchar(4000)

-------------------------------------------------------------------------------
-- Operadores
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Operator_dashboard'
create table [DASHBOARD].[dbo].lcc_Operator_dashboard(
		[mnc][varchar](256) NULL,
		[OPERATOR][varchar](256) NULL,
		[ORDER_OPERATOR][int]
)

insert into [DASHBOARD].[dbo].lcc_Operator_dashboard
values('01','VODAFONE',1)
insert into [DASHBOARD].[dbo].lcc_Operator_dashboard
values('07','MOVISTAR',2)
insert into [DASHBOARD].[dbo].lcc_Operator_dashboard
values('03','ORANGE',3)
insert into [DASHBOARD].[dbo].lcc_Operator_dashboard
values('04','YOIGO',4)
		
-------------------------------------------------------------------------------
-- Entidades a tratar
if @group = 0 
begin
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_step1''
					select 	s.*
							,e.*
					into [DASHBOARD].[dbo].lcc_entities_dashboard_step1
					from [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW s, [DASHBOARD].[dbo].lcc_Operator_dashboard e
					where s.scope=''' + @scope + '''
						and s.report='''+ @report +'''
					order by s.ORDER_DASHBOARD,e.ORDER_OPERATOR';
	EXECUTE sp_executesql @SQLString

	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard''
					select s.SCOPE
							,s.ENTITIES_BBDD as entidad
							,s.ENTITIES_DASHBOARD
							,a.Meas_date as Meas_date
							,s.type_scope
							,s.EXTENSION
							,'''' as SAMPLED_PERCENTAGE
							,s.POPULATION
							,s.OPERATOR
							,s.mnc
							,s.ORDER_OPERATOR
							,s.ORDER_DASHBOARD
							,case when OPERATOR = ''VODAFONE'' then s.RAN_VENDOR_VDF
									when OPERATOR = ''MOVISTAR'' then s.RAN_VENDOR_MOV
									when OPERATOR = ''ORANGE'' then s.RAN_VENDOR_OR
									when OPERATOR = ''YOIGO'' then s.RAN_VENDOR_YOI
									end as RAN_VENDOR
					into [DASHBOARD].[dbo].lcc_entities_dashboard
					from [DASHBOARD].[dbo].lcc_entities_dashboard_step1 s
					left outer join
					(select distinct a.entidad, a.Meas_Date
					from '+@database+'.[dbo].['+@table+'] a,
						(select entidad, max((100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2))) as Meas_date_2
						from '+@database+'.[dbo].['+@table+']
						group by entidad) b
						where a.entidad=b.entidad and (100*substring(a.Meas_Date,1,2) +200000 + 1*substring(a.Meas_Date,4,2))=b.Meas_date_2
					) a
					on  s.ENTITIES_BBDD=a.entidad
					where s.scope=''' + @scope + '''
					and s.report='''+ @report +'''
					order by s.ORDER_DASHBOARD,s.ORDER_OPERATOR
					';
	EXECUTE sp_executesql @SQLString
	drop table [DASHBOARD].[dbo].lcc_entities_dashboard_step1

	if @scope not like '%highways%'
	begin 
		set @SQLString=N'	
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_all_dates_step1''
						select distinct entidad,
								(100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2)) as Meas_date, 
								convert (int,replace(meas_week,''W'','''')) as week,
								convert (int,left((100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2)),4)) as year
						into [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates_step1
						from '+@database+'.[dbo].['+@table+']
						order by entidad, meas_Date'
		EXECUTE sp_executesql @SQLString


		set @SQLString=N'	
							exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_all_dates''
							select * ,ROW_NUMBER() OVER(PARTITION BY entidad ORDER BY entidad,meas_Date asc) AS id
							into [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates
							from [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates_step1'
		EXECUTE sp_executesql @SQLString
	end
	
end
else if @group=1
begin 
	if @scope like 'MAIN CITIES' or @scope like 'SMALLER CITIES'
	begin
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_step1''
						select 	s.*
								,e.*
						into [DASHBOARD].[dbo].lcc_entities_dashboard_step1
						from [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW s, [DASHBOARD].[dbo].lcc_Operator_dashboard e
						where s.scope=''MAIN CITIES'' or s.scope=''SMALLER CITIES''
							and s.report='''+@report+'''
 						order by s.ORDER_DASHBOARD,e.ORDER_OPERATOR';
		EXECUTE sp_executesql @SQLString

		set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard''
					select s.SCOPE
							,s.ENTITIES_BBDD as entidad
							,s.ENTITIES_DASHBOARD
							,a.Meas_date as Meas_date
							,s.type_scope
							,s.OPERATOR
							,s.mnc
					into [DASHBOARD].[dbo].lcc_entities_dashboard
					from [DASHBOARD].[dbo].lcc_entities_dashboard_step1 s
					left outer join
					(select distinct a.entidad, a.Meas_Date
					from '+@database+'.[dbo].['+@table+'] a,
						(select entidad, max((100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2))) as Meas_date_2
						from '+@database+'.[dbo].['+@table+']
						group by entidad) b
						where a.entidad=b.entidad and (100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2))=b.Meas_date_2
					) a
					on  s.ENTITIES_BBDD=a.entidad
					where s.scope=''MAIN CITIES'' or s.scope=''SMALLER CITIES''
					order by s.ORDER_DASHBOARD,s.ORDER_OPERATOR';
		EXECUTE sp_executesql @SQLString
		drop table [DASHBOARD].[dbo].lcc_entities_dashboard_step1
	end

	if @scope = 'MAIN HIGHWAYS REGION'
	begin
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard''
						select 	'''+@scope+''' as Scope
								,s.entidad
								,s.entidad as ENTITIES_DASHBOARD
								,''RW'' as Meas_Date
								,'''' as type_scope
								,e.mnc
								,e.operator
								,'''' as EXTENSION
								,'''' as POPULATION
								,'''' as RAN_VENDOR
								,'''' as ORDER_DASHBOARD
								,'''' as ORDER_OPERATOR
						into [DASHBOARD].[dbo].lcc_entities_dashboard
						from [DASHBOARD].[dbo].lcc_Operator_dashboard e,
							(select distinct entidad 
							from '+@database+'.[dbo].['+@table+']) s
						order by entidad,mnc';
		EXECUTE sp_executesql @SQLString
	end
end

-- Limpieza de tablas temporales
drop table [DASHBOARD].[dbo].lcc_Operator_dashboard
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_entities_dashboard_all_dates_step1'
