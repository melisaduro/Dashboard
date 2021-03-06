USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_VOICE_TABLES]    Script Date: 29/05/2017 15:20:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_DashBoard_VOICE_TABLES] 
	@database as varchar(256)
	,@nameSheet as varchar(256)
	,@LA as bit
as

-------------------------------------------------------------------------------
--Inicialización de variables

--declare @database as varchar(256) = '[AGGRVoice4G]'
--declare @namesheet as varchar(256)='4G'
--declare @LA as bit = 0

declare @sheetTech as varchar(256)
declare @table varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @LAfilter varchar(4000)
declare @RoundFilter varchar (256)
--declare @EntitiesNOLAfilter varchar(2000)

if @nameSheet like '4G_ONLY_road' set @sheetTech='_4G_ROAD'
	else if @nameSheet like '4G_road' set @sheetTech='_ROAD'
		else if @nameSheet like '4G_ROAD_REGION' set @sheetTech='_ROAD_REGION'
			else if @nameSheet like '4G_ONLY_railway' set @sheetTech='_4G_RAILWAY'
				else if @nameSheet like '4G_railway' set @sheetTech='_RAILWAY'
					else if @nameSheet like '4G_ONLY' set @sheetTech='_4G'
						else if @nameSheet like '4G' set @sheetTech=''
							else if @nameSheet like '2G3G' set @sheetTech=''
								else if @nameSheet like 'VOLTE' set @sheetTech='_VOLTE'
									else if @nameSheet like 'VOLTE_ROAD' set @sheetTech='_VOLTE_ROAD'

---- Variable para eliminar las entidades en las que no se ha medido LA y queremos destarcar
--if @nameSheet like '%2G3G%'
--	set @EntitiesNOLAfilter= 'and a.entidad not like ''coruna'''
--else
--	set @EntitiesNOLAfilter=' and (a.entidad not like ''alicante'' and a.entidad not like ''sevilla'' and a.entidad not like ''barcelona'')'

if @la = 1 --set @LAfilter ='a.entorno  not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 

set @lafilter='((convert(int,SUBSTRING(a.meas_date,1,2))<16 and a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G''))
or (convert(int,SUBSTRING(a.meas_date,1,2))=16 and convert(int,SUBSTRING(a.meas_date,4,2))<=7 and  a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G''))
or (convert(int,SUBSTRING(a.meas_date,1,2))>16 and a.entorno like ''%%'' or a.entorno is null)
or (convert(int,SUBSTRING(a.meas_date,1,2))=16 and convert(int,SUBSTRING(a.meas_date,4,2))>7 and a.entorno like ''%%'' or a.entorno is null))'

else set @LAfilter= '(a.entorno like ''%%'' or a.entorno is null)' --+ @EntitiesNOLAfilter

if @namesheet like '%road%' or @namesheet like '%railway%' set @RoundFilter = 'and a.ronda=b.ronda and	a.entidad_orig=b.entidad_orig'
else set @RoundFilter=''


set @database= replace(replace(@database,'[',''),']','')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Voice_calls
SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_calls_'+@nameSheet+'_temp''
				select  a.entidad as entidad_c
						,a.mnc as mnc_c
						,a.Meas_Date as Meas_Date_c
						,sum(a.[MO_Succeeded]) +  sum(a.[MT_Succeeded])+sum(a.[MO_Blocks]) + sum(a.[MT_Blocks])+sum(a.[MO_Drops])+sum(a.[MT_Drops]) as CALLS_ATTEMPTS
						,sum(a.[MO_Blocks]) + sum(a.[MT_Blocks]) as CALLS_FAILURES
						,sum(a.[MO_Succeeded]) + sum(a.[MO_Blocks]) + sum(a.[MO_Drops]) as CALLS_ATTEMPTS_MO
						,sum(a.[MO_Blocks]) as CALLS_FAILURES_MO
						,sum(a.[MT_Succeeded]) + sum(a.[MT_Blocks]) + sum(a.[MT_Drops]) as CALLS_ATTEMPTS_MT
						,sum(a.[MT_Blocks]) as CALLS_FAILURES_MT
						,sum(a.[MO_Drops])+sum(a.[MT_Drops]) as CALLS_DROPS
						,sum(a.[SQNS_NB]) as CALLS_NB
						,sum(a.[SQNS_WB]) as CALLS_WB
						,sum(a.[Started_ended_3G_Comp]) as CALLS_3G
						,sum(a.[Started_ended_2G_Comp]) as CALLS_2G
						,sum(a.[Calls_Mixed_Comp]) as CALLS_MIXED
						,sum(a.[Started_4G_Comp]) as CALLS_4G
						,sum(a.[Duration_3G]) as DURATION_3G
						,sum(a.[Duration_2G]) as DURATION_2G
						,sum(a.[GSM_calls_After_CSFB_Comp]) as CALLS_2G_CSFB
						,sum(a.[UMTS_calls_After_CSFB_Comp]) as CALLS_3G_CSFB
				into [DASHBOARD].[dbo].lcc_Voice_calls_'+@nameSheet+'_temp
				FROM  [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+ @sheetTech +'] a
				where  '+ @LAfilter +'
				group by a.mnc,a.entidad,a.Meas_Date order by a.mnc';
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Voice_CST
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+ @sheetTech

exec [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_CST] @sheetTech,@table,@LAfilter

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_CST_'+@nameSheet+'_temp1''
				select  a.entidad
						,a.mnc
						,a.Meas_Date
						,sum(a.MO_CallType+a.MT_CallType) as Calls_Completed
						,1.0*(sum(1.0*a.[CST_MO_Alerting]*a.[Calls_AVG_ALERT_MO])/sum(a.[Calls_AVG_ALERT_MO])) as CST_MO_ALERTING
						,1.0*(sum(1.0*a.[CST_MT_Alerting]*a.[Calls_AVG_ALERT_MT])/sum(a.[Calls_AVG_ALERT_MT])) as CST_MT_ALERTING
						,1.0*((1.0*sum(a.[CST_MOMT_Alerting]*(a.[Calls_AVG_ALERT_MO]+a.[Calls_AVG_ALERT_MT]))/sum(a.[Calls_AVG_ALERT_MT]+a.[Calls_AVG_ALERT_MO]))) as CST_ALERTING
						,1.0*sum(1.0*a.[CST_MO_Connect]*a.[Calls_AVG_CONNECT_MO])/sum(a.[Calls_AVG_CONNECT_MO]) as CST_MO_CONNECT
						,1.0*sum(1.0*a.[CST_MT_Connect]*a.[Calls_AVG_CONNECT_MT])/sum(a.[Calls_AVG_CONNECT_MT]) as CST_MT_CONNECT
						,1.0*sum(1.0*a.[CST_MOMT_Connect]*(a.[Calls_AVG_CONNECT_MO]+a.[Calls_AVG_CONNECT_MT]))/sum(a.[Calls_AVG_CONNECT_MT]+a.[Calls_AVG_CONNECT_MO]) as CST_CONNECT
				into [DASHBOARD].[dbo].lcc_Voice_CST_'+@nameSheet+'_temp1
				FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+ @sheetTech +'] a
				where  '+ @LAfilter +'
				group by a.mnc,a.entidad,a.Meas_Date
				order by a.mnc
				'
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_CST_'+@nameSheet+'_temp''
				select  a.entidad as entidad_cst
						,a.mnc as mnc_cst
						,a.Meas_Date as Meas_Date_cst
						,a.CST_MO_ALERTING
						,a.CST_MT_ALERTING
						,a.CST_ALERTING
						,b.P_95_MO_Alert as CST_95TH_MO_ALERTING
						,b.P_95_MT_Alert as CST_95TH_MT_ALERTING
						,b.P_95_MOMT_Alert as CST_95TH_ALERTING
						,a.CST_MO_CONNECT
						,a.CST_MT_CONNECT
						,a.CST_CONNECT
						,b.P_95_MO_Conn as CST_95TH_MO_CONNECT
						,b.P_95_MT_Conn as CST_95TH_MT_CONNECT
						,b.P_95_MOMT_Conn as CST_95TH_CONNECT
				into [DASHBOARD].[dbo].lcc_Voice_CST_'+@nameSheet+'_temp
				FROM [DASHBOARD].[dbo].lcc_Voice_CST_'+@nameSheet+'_temp1 a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Voice_CST' + @sheetTech +'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Voice_MOS
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+ @sheetTech

exec [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_MOS] @sheetTech,@table,@LAfilter

SET @SQLString =N'
				/*--exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_MOS_'+@nameSheet+'_aux''	
				--select a.*
				--into dashboard.dbo.lcc_Voice_MOS_'+@nameSheet+'_aux	
				--from (	select a.*, b.[MO_Succeeded] + b.[MO_Drops] as MO_CallType, b.[MT_Succeeded] + b.[MT_Drops] as MT_CallType
				--	-- b.MO_CallType,b.MT_CallType 
				--	from [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+ @sheetTech+'] a	
				--	--	left outer join [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+ @sheetTech +'] b
				--		left outer join [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+ @sheetTech +'] b
				--		on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date and a.parcel=b.parcel 
				--		'+@RoundFilter+') a
				--where  '+ @LAfilter +'*/

				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_MOS_'+@nameSheet+'_temp1''	
				select  a.entidad
						,a.mnc
						,a.Meas_Date
						,1.0*(sum(a.[MOS_ALL]*a.Calls_MOS))/sum(a.Calls_MOS) as MOS_NB
						,sum(a.[Registers_NB]) as NUM_SAMPLES_NB
						,sum(a.[MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_NB
						,1.0*(sum(isnull(a.[MOS],0)*a.[Registers]+isnull(a.[MOS_NB],0)*a.[Registers_NB]))/sum(a.[Registers]+a.[Registers_NB]) as MOS_OVER_old
						--,1.0*(sum(a.[MOS_ALL]*a.MO_CallType+a.[MOS_ALL]*a.MT_CallType))/sum(a.MO_CallType+a.MT_CallType) as MOS_OVER
						,1.0*(sum(a.[MOS_ALL]*a.Calls_MOS))/sum(a.Calls_MOS) as MOS_OVER
						,sum(a.[Registers]+a.[Registers_NB]) as NUM_SAMPLES_OVER
						,sum(a.[MOS_Samples_Under_2.5]+a.[MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_OVER
						,sum(a.[Calls_WB_only]) as CALLS_WB_AMR
						,1.0*sum(a.[MOS_WBOnly]*a.[Calls_AVG_WB_ONLY])/sum(a.[Calls_AVG_WB_ONLY]) as AVG_QUALITY_WB_AMR
				into [DASHBOARD].[dbo].lcc_Voice_MOS_'+@nameSheet+'_temp1 
				FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+ @sheetTech+'] a
				where  '+ @LAfilter +'
				group by a.mnc,a.entidad,a.Meas_Date'
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_MOS_'+@nameSheet+'_temp''
				select  a.entidad as entidad_mos
						,a.mnc as mnc_mos
						,a.Meas_Date as Meas_Date_mos
						,a.MOS_NB
						,a.NUM_SAMPLES_NB
						,b.DESV_NB as STDV_NB
						,a.NUM_SAMPLES_25_NB
						,b.P_05_NB as NB_5TH
						,a.MOS_OVER
						,a.NUM_SAMPLES_OVER
						,b.DESV_OverAll as STDV_OVER
						,a.NUM_SAMPLES_25_OVER
						,b.P_05_OverAll as OVER_5TH
						,a.CALLS_WB_AMR
						,a.AVG_QUALITY_WB_AMR
						,case when a.CALLS_WB_AMR = 0 then null
							when a.CALLS_WB_AMR > 0 then b.Median_WB
							end as MEDIAN_QUALITY_WB_AMR
				into [DASHBOARD].[dbo].lcc_Voice_MOS_'+@nameSheet+'_temp
				FROM [DASHBOARD].[dbo].lcc_Voice_MOS_'+@nameSheet+'_temp1 a	
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Voice_MOS' + @sheetTech +'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
				';
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
if @database like '%volte%'
begin
	-- Voice_VOLTE
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_VOLTE_'+@nameSheet+'_temp''
					select  a.entidad as entidad_v
							,a.mnc as mnc_v
							,a.Meas_Date as Meas_Date_v
							,case when sum(a.Count_Speech_Delay)>0 then sum(a.Count_Speech_Delay*a.volte_speech_delay)/sum(a.Count_Speech_Delay) 
								else 0 end as VOLTE_Speech_Delay
							,sum (a.Started_VOLTE) as VOICE_CALLS_STARTED_AND_TERMINATED_ON_VOLTE
							,sum(a.SRVCC) as CALLS_WITH_SRVCC_PROCEDURE
					into [DASHBOARD].[dbo].lcc_Voice_VOLTE_'+@nameSheet+'_temp
					FROM  [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_VOLTE'+ @sheetTech +'] a
					where  '+ @LAfilter +'
					group by a.mnc,a.entidad,a.Meas_Date order by a.mnc';
	EXECUTE sp_executesql @SQLString
end
-- Limpieza de tablas temporales
SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_CST_'+@nameSheet+'_temp1'' 
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_MOS_'+@nameSheet+'_temp1''
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Voice_MOS_'+@nameSheet+'_aux'''
EXECUTE sp_executesql @SQLString

