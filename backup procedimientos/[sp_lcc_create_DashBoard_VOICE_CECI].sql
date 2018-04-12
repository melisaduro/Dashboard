USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_VOICE_CECI]    Script Date: 29/05/2017 15:19:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_create_DashBoard_VOICE_CECI] 
	@namesheet as varchar(256)
	,@typeMeasurI as varchar(256)
	,@scope as varchar(256)
	,@UpdateMeasur as bit
as

-------------------------------------------------------------------------------
--Inicialización de variables

--declare @typeMeasurI as varchar(256)='M2M'
--declare @namesheet as varchar(255)='C&T_4G_MAIN_CITIES M2M'
--declare @scope as varchar(256)='MAIN CITIES'
--declare @UpdateMeasur as bit = 1 

declare @group as bit
declare @database as varchar(256)
declare @sheetTech as varchar(256)
declare @table as varchar(256)
DECLARE @SQLString nvarchar(4000)
DECLARE @sheet nvarchar(256)

--if @scope='HIGHWAYS' set @scope='MAIN HIGHWAYS'

if @nameSheet like '%4G%' and @nameSheet not like '%HIGHWAYS%' and @nameSheet not like '%RAILWAYS%' set @database='[AGGRVoice4G]'
	else if @nameSheet like '%4G%' and @nameSheet like '%HIGHWAYS%' set @database='[AGGRVoice4G_ROAD]'
		else if @nameSheet like '%4G%' and @nameSheet like '%RAILWAYS%' set @database='[AGGRVoice4G]'
			else if @nameSheet like '%2G3G%' set @database='[AGGRVoice3G]'
				else set @database='NULL'
	
if @nameSheet like '%4G%' set @sheetTech=''
	else if @nameSheet like '%2G3G%' set @sheetTech=''

if @nameSheet like '%4G%ONLY%' and @nameSheet not like '%HIGHWAYS%' and @namesheet not like '%RAILWAY%' set @sheet='4G_ONLY'
	else if @nameSheet like '%4G_CA%' and @nameSheet not like '%HIGHWAYS%' and @namesheet not like '%RAILWAY%' set @sheet='4G_CA'
		else if @nameSheet like '%4G%' and @nameSheet not like '%HIGHWAYS%' and @namesheet not like '%RAILWAY%' set @sheet='4G'
			else if @nameSheet like '%2G3G%' and @nameSheet not like '%HIGHWAYS%' and @namesheet not like '%RAILWAY%' set @sheet='2G3G'
				else if @nameSheet like '%4G%ONLY%' and @nameSheet like '%HIGHWAYS%' set @sheet='4G_ONLY_ROAD'
					else if @nameSheet like '%4G%' and @nameSheet like '%HIGHWAYS%' and @nameSheet not like '%region%' set @sheet='4G_ROAD'
						else if @nameSheet like '%4G%' and @nameSheet like '%HIGHWAYS%' and @nameSheet like '%region%' set @sheet='4G_ROAD_REGION'
							else if @nameSheet like '%4G%ONLY%' and @nameSheet like '%RAILWAY%' set @sheet='4G_ONLY_RAILWAY'
								else if @nameSheet like '%4G%' and @nameSheet like '%RAILWAY%' set @sheet='4G_RAILWAY'

set @database =replace(replace(@database,'[',''),']','')

if  @nameSheet not like '%HIGHWAYS%' and @nameSheet not like '%RAILWAY%'
	set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+ @sheetTech
else if @nameSheet not like '%HIGHWAYS%REGION%' and @nameSheet like '%HIGHWAYS%'
	set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+'_ROAD'
else if @nameSheet like '%RAILWAY%'
	set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+'_RAILWAY'
else if @nameSheet like '%HIGHWAYS%REGION%' 
	set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+'_ROAD_REGION'
-------------------------------------------------------------------------------
-- Separar por Scopes 
if @scope ='MAIN HIGHWAYS REGION' set @group=1
else set @group=0

exec [dbo].[sp_lcc_create_Dashboard_Entities] @scope,'[DASHBOARD]',@table,@group

-- Modificación de la tabla lcc_entities_dashboard con la información relativa a la pestaña particular
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_entities_dashboard_temp'
if @scope ='MAIN HIGHWAYS REGION' 
begin 
	select e.*,'' as SHEET,'' as TECHNOLOGY, '' as [TYPE OF TEST], '' as [ALGORITHM],
			'' as [SPEECH_LANGUAGE], '' as SMARTPHONE_MODEL, '' as FIRMWARE_VERSION, '' as MCC, '' as OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e
end
else
begin
	select e.*,i.SHEET,i.TECHNOLOGY, i.[TYPE OF TEST],i.[ALGORITHM],
			i.[SPEECH_LANGUAGE],i.SMARTPHONE_MODEL,i.FIRMWARE_VERSION,i.MCC,i.OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e,
		[AGRIDS].[dbo].lcc_dashboard_info_voice i
	where e.scope=i.scope and @nameSheet=i.sheet
end


-------------------------------------------------------------------------------
if @UpdateMeasur = 1 
begin
	-- Modificación de las tablas para replicar la información de las medidas invalidadas. Se toma la inmediatamente anterior.
	if @scope not like '%HIGHWAYS%' and @scope not like '%RAILWAY%'
	exec [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR] @Sheet, 'VOICE',@database
end
-------------------------------------------------------------------------------
-- Lincado de las tablas temporales
SET @SQLString= N'
	exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'_step1''
	declare @typeMeasur as varchar(256)=''' +@typeMeasurI + '''
	select	d.entidad as entidad_1
			,d.mnc as mnc_1
			,d.Meas_Date as Meas_Date_1
			,d.type_scope as SCOPE
			,d.TECHNOLOGY as TECHNOLOGY
			,d.[TYPE OF TEST] as TEST_TYPE
			,d.SCOPE as TARGET_SCOPE
			,d.ENTITIES_DASHBOARD
			,c.CALLS_ATTEMPTS
			,c.CALLS_FAILURES
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then c.CALLS_ATTEMPTS_MO
					end as CALLS_ATTEMPTS_MO
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then c.CALLS_FAILURES_MO
					end as CALLS_FAILURES_MO
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then c.CALLS_ATTEMPTS_MT
					end as CALLS_ATTEMPTS_MT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then c.CALLS_FAILURES_MT
					end as CALLS_FAILURES_MT
			,c.CALLS_DROPS
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then c.CALLS_NB
					end as CALLS_NB
			,case	when @typeMeasur=''M2M'' then c.CALLS_WB
					when @typeMeasur=''M2F'' then null
					end as CALLS_WB
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_MO_ALERTING
					end as CST_MO_ALERTING
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_MT_ALERTING
					end as CST_MT_ALERTING
			,cst.CST_ALERTING as CST_ALERTING
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_95TH_MO_ALERTING
					end as CST_95TH_MO_ALERTING
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_95TH_MT_ALERTING
					end as CST_95TH_MT_ALERTING
			,cst.CST_95TH_ALERTING as CST_95TH_ALERTING
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_MO_CONNECT
					end as CST_MO_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_MT_Connect
					end as CST_MT_CONNECT
			,cst.CST_CONNECT as CST_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_95TH_MO_CONNECT
					end as CST_95TH_MO_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_95TH_MT_CONNECT
					end as CST_95TH_MT_CONNECT
			,cst.CST_95TH_CONNECT as CST_95TH_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then m.MOS_NB
					end as MOS_NB
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then m.NUM_SAMPLES_NB
					end as NUM_SAMPLES_NB
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then m.STDV_NB
					end as STDV_NB
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then m.NUM_SAMPLES_25_NB
					end as NUM_SAMPLES_25_NB
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then m.NB_5TH
					end as NB_5TH
	into [DASHBOARD].[dbo].[lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'_step1]
	from [DASHBOARD].[dbo].lcc_entities_dashboard_temp d
	left outer join [DASHBOARD].[dbo].lcc_Voice_calls_'+@sheet+'_temp c 
		on d.mnc=c.mnc_c and d.entidad=c.entidad_c and d.Meas_Date=c.Meas_Date_c
	left outer join [DASHBOARD].[dbo].lcc_Voice_CST_'+@sheet+'_temp cst
		on d.mnc=cst.mnc_cst and d.entidad=cst.entidad_cst and d.Meas_Date=cst.Meas_Date_cst
	left outer join [DASHBOARD].[dbo].lcc_Voice_MOS_'+@sheet+'_temp m
		on d.mnc=m.mnc_mos and d.entidad=m.entidad_mos and d.Meas_Date=m.Meas_Date_mos'
EXECUTE sp_executesql @SQLString	

SET @SQLString= N'
	declare @typeMeasur as varchar(256)=''' +@typeMeasurI + '''
	exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'''
	select	a.*
			,case	when @typeMeasur=''M2M'' then m.MOS_OVER
					when @typeMeasur=''M2F'' then null
					end as MOS_OVER
			,case	when @typeMeasur=''M2M'' then m.NUM_SAMPLES_OVER
					when @typeMeasur=''M2F'' then null
					end as NUM_SAMPLES_OVER
			,case	when @typeMeasur=''M2M'' then m.STDV_OVER
					when @typeMeasur=''M2F'' then null
					end as STDV_OVER
			,case	when @typeMeasur=''M2M'' then m.NUM_SAMPLES_25_OVER
					when @typeMeasur=''M2F'' then null
					end as NUM_SAMPLES_25_OVER
			,case	when @typeMeasur=''M2M'' then m.OVER_5TH
					when @typeMeasur=''M2F'' then null
					end as OVER_5TH
			--,'''' as V_AVG_RTT
			,case	when @typeMeasur=''M2M'' then m.CALLS_WB_AMR
					when @typeMeasur=''M2F'' then null
					end as CALLS_WB_AMR
			,case	when @typeMeasur=''M2M'' then m.AVG_QUALITY_WB_AMR
					when @typeMeasur=''M2F'' then null
					end as AVG_QUALITY_WB_AMR
			,m.MEDIAN_QUALITY_WB_AMR as MEDIAN_QUALITY_WB_AMR
			,c.CALLS_3G
			,c.CALLS_2G
			,c.CALLS_MIXED
			,c.CALLS_4G
			--,'''' as V_CALLS_VOLTE
			,c.DURATION_3G as DURATION_3G
			,c.DURATION_2G as DURATION_2G
			,c.CALLS_2G_CSFB
			,c.CALLS_3G_CSFB
			--,'''' as CALLS_SRVCC


			NEW !!!!!!!!!!!!!!!
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_10TH_MO_CONNECT
					end as CST_10TH_MO_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_10TH_MT_CONNECT
					end as CST_10TH_MT_CONNECT
			,cst.CST_10TH_CONNECT as CST_10TH_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_90TH_MO_CONNECT
					end as CST_90TH_MO_CONNECT
			,case	when @typeMeasur=''M2M'' then null
					when @typeMeasur=''M2F'' then cst.CST_90TH_MT_CONNECT
					end as CST_90TH_MT_CONNECT
			,cst.CST_90TH_CONNECT as CST_90TH_CONNECT
			,c.[% HR]
			,c.[% FR]
			,c.[% EFR]
			,c.[% AMR HR]
			,c.[% AMR FR]
			,c.[% AMR WB]
			,c.[% AMR WB HD]


			,'''' as URBAN_EXTENSION
			,d.POPULATION as POPULATION_COVERED
			,'''' as SAMPLED_URBAN
			,'''' as NUMBER_TEST_KM
			,'''' as ROUTE
			,d.[ALGORITHM] as ALGORITHM
			,d.[SPEECH_LANGUAGE] as LANGUAGE
			,d.SMARTPHONE_MODEL as PHONE_MODEL
			,d.FIRMWARE_VERSION as FIRM_V
			,''20'' + d.Meas_Date as LAST_ACQUISITION
			,d.OPERATOR
			,d.MCC as MCC
			,d.MNC
			,d.OPCOS as OPCOS
			,d.RAN_VENDOR as RAN_VENDOR
	into [DASHBOARD].[dbo].[lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+']
	from [DASHBOARD].[dbo].[lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'_step1] a
		left outer join [DASHBOARD].[dbo].lcc_entities_dashboard_temp d
		on d.mnc=a.mnc_1 and d.entidad=a.entidad_1 and d.Meas_Date=a.Meas_Date_1
		left outer join [DASHBOARD].[dbo].lcc_Voice_calls_'+@sheet+'_temp c 
		on a.mnc_1=c.mnc_c and a.entidad_1=c.entidad_c and a.Meas_Date_1=c.Meas_Date_c
		left outer join [DASHBOARD].[dbo].lcc_Voice_MOS_'+@sheet+'_temp m
		on a.mnc_1=m.mnc_mos and a.entidad_1=m.entidad_mos and a.Meas_Date_1=m.Meas_Date_mos
		
		NEW !!!!!!
		left outer join [DASHBOARD].[dbo].lcc_Voice_CST_'+@sheet+'_temp cst
		on a.mnc=cst.mnc_cst and a.entidad=cst.entidad_cst and a.Meas_Date=cst.Meas_Date_cst
		'
EXECUTE sp_executesql @SQLString	

-- Limpieza de tablas temporales
SET @SQLString= N'
	exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'_step1'''
EXECUTE sp_executesql @SQLString	

SET @SQLString= N' 
	alter table [DASHBOARD].[dbo].[lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'] drop column entidad_1,mnc_1,Meas_Date_1';
EXECUTE sp_executesql @SQLString	

-- Muestra de resultados
SET @SQLString= N'
				select a.* 
				from [DASHBOARD].[dbo].[lcc_dashboard_results_voice_'+ @sheet +'_'+@typeMeasurI+'] a
					,[DASHBOARD].[dbo].lcc_entities_dashboard_temp b
				where a.entities_dashboard=b.entities_dashboard and a.mnc=b.mnc
				order by convert(int,b.order_dashboard),convert(int,b.order_operator)'
EXECUTE sp_executesql @SQLString