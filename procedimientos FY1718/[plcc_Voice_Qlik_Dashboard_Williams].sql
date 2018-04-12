USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_Voice_Qlik_Dashboard_Williams]    Script Date: 12/04/2018 10:20:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[plcc_Voice_Qlik_Dashboard_Williams]

	  @monthYear as nvarchar(50)
	 ,@ReportWeek as nvarchar(50)
	 ,@last_measurement as varchar(256)
	 ,@id as varchar(50)		

AS
 
 
 ------------------------------------------------- EXPLICACIÓN CÓDIGO ----------------------------------------------------------


/* En la primera parte del código se sacan todos los Scopes, las carreteras y los AVEs saldrán con el acumulado de 4 y 3 vueltas respectivamente.
Se obtiene una tabla de entidades Vodafone (ya que si algo se invalida en este operador, directamente esa entidad no se entregaría) y se cruza 
con el resto de operadores para que, si estuviese invalidado en otro operador saliese a NULL.
   En la segunda parte del código se hace un Union ALL con el mismo código pero adaptado para sacar la última vuelta de las carreteras. Esto
se hace para el Scoring y el Q&D. En esta parte del código, si la última vuelta de las carreteras para algún operador estuviese invalidad directamente
nos quedamos con la última vuelta váldia
   Al final del código, y sin nada que ver con lo anterior, tenemos las ejecuciones de procedimientos para que CENTRAL pueda sacar la info
de carreteras por Región*/


-----------------------------------------------------------------------------------------------------------------------------------
 

 --declare @monthYear as nvarchar(50) = '201803'
 --declare @ReportWeek as nvarchar(50) = 'w12'
 --declare @last_measurement as varchar(256) = 'last_measurement_osp'
 --declare @id as varchar(50)='OSP'


----------------------------------------------- CREACIÓN INICIAL DE LAS TABLAS -------------------------------------------------------

exec sp_lcc_dropifexists '_Actualizacion_QLIK_DASH'
exec sp_lcc_dropifexists 'lcc_voice_final_Williams'
exec sp_lcc_dropifexists '_All_voice_Williams'

-- TABLA de SEGUIMIENTO de la ejecución del Procedimiento Kpis Qlik:
	
if (select name from sys.tables where type='u' and name='_Actualizacion_QLIK_DASH_Williams') is null
begin
	CREATE TABLE [dbo].[_Actualizacion_QLIK_DASH_Williams](
		[Status] [varchar](255) NULL,
		[Date] [datetime] NULL
	) ON [primary]
end

if (select name from sys.tables where name='_All_voice_Williams') is null
begin
CREATE TABLE [dbo].[_All_voice_Williams](
	[SCOPE] [varchar](255) NULL,
	[TECHNOLOGY] [varchar](256) NULL,
	[TEST_TYPE] [nvarchar](256) NULL,
	[SCOPE_DASH] [varchar](255) NULL,
	[SCOPE_QLIK] [varchar](255) NULL,
	[ENTITIES_BBDD] [varchar](259) NULL,
	[ENTITIES_DASHBOARD] [varchar](255) NULL,
	[Calls] [float] NULL,
	[Blocks] [float] NULL,
	[MOC_Calls] [float] NULL,
	[MOC_Blocks] [float] NULL,
	[MTC_Calls] [float] NULL,
	[MTC_Blocks] [float] NULL,
	[Drops] [float] NULL,
	[NUMBERS OF CALLS Non Sustainability (NB)] [float] NULL,
	[NUMBERS OF CALLS Non Sustainability (WB)] [float] NULL,
	[CST_AL_MO] [float] NULL,
	[CST_AL_MT] [float] NULL,
	[CST_ALERTING] [float] NULL,
	[CST_CO_MO] [float] NULL,
	[CST_CO_MT] [float] NULL,
	[CST_CONNECT] [float] NULL,
	[AVERAGE VOICE QUALITY NB (MOS)] [float] NULL,
	[Samples_DL+UL_NB] [float] NULL,
	[MOS_NB_Below2_5_samples] [float] NULL,
	[AVERAGE VOICE QUALITY (MOS)] [float] NULL,
	[Samples_DL+UL] [float] NULL,
	[MOS_Below2_5_samples] [float] NULL,
	[VOLTE_AVG_RTT] [float] NULL,
	[WB AMR Only] [float] NULL,
	[AVERAGE WB AMR Only] [float] NULL,
	[Calls_Started_3G_WO_Fails] [float] NULL,
	[Calls_Started_2G_WO_Fails] [float] NULL,
	[Calls_Mixed] [float] NULL,
	[Calls_Started_4G_WO_Fails] [float] NULL,
	[Calls_Started_VOLTE_WO_Fails] [float] NULL,
	[Call_duration_3G] [float] NULL,
	[Call_duration_2G] [float] NULL,
	[CSFB_to_GSM_samples] [float] NULL,
	[CSFB_to_UMTS_samples] [float] NULL,
	[CSFB_samples] [float] NULL,
	[VOLTE_Calls_withSRVCC] [float] NULL,
	[URBAN_EXTENSION] [varchar](1) NOT NULL,
	[Population] [float] NULL,
	[SAMPLED_URBAN] [varchar](1) NOT NULL,
	[NUMBER_TEST_KM] [varchar](1) NOT NULL,
	[ROUTE] [varchar](1) NOT NULL,
	[ALGORITHM] [varchar](255) NULL,
	[LANGUAGE] [varchar](255) NULL,
	[PHONE_MODEL] [varchar](255) NULL,
	[FIRM_VERSION] [varchar](255) NULL,
	[LAST_ACQUISITION] [varchar](258) NULL,
	[Operador] [varchar](8) NULL,
	[MCC] [int] NULL,
	[MNC] [varchar](30) NULL,
	[OPCOS] [varchar](255) NULL,
	[RAN_VENDOR] [nvarchar](16) NULL,
	[SCENARIOS] [varchar](1000) NULL,
	--[PROVINCIA] [nvarchar](255) NULL,
	[PROVINCIA_DASH] [nvarchar](255) NULL,
	--[CCAA] [varchar](256) NULL,
	[CCAA_DASH] [varchar](256) NULL,
	[Zona_OSP] [nvarchar](10) NULL,
	[Zona_VDF] [nvarchar](10) NULL,
	--[ORDEN_DASH] [varchar](255) NULL,
	[report_type] [varchar](256) NULL,
	[id] [varchar](3) NOT NULL,
	[MonthYear] [varchar](10) NOT NULL,
	[ReportWeek] [varchar](10) NOT NULL
) ON [PRIMARY]

END



-------------------------------------------------------------------------------------------------------------------------------------
--TABLA QLIK (N/A)
--if (select name from qlik.sys.tables where name='lcc_voice_final_qlik_Williams') is null
--begin
--	CREATE TABLE [QLIK].[dbo].[lcc_voice_final_qlik_Williams](
--	[Scope_Rest] [varchar](255) NULL,
--	[operator] [varchar](8) NULL,
--	[meas_tech] [varchar](256) NULL,
--	[entity] [varchar](256) NULL,
--	[report_type] [varchar](256) NULL,
--	[id] [varchar](3) NOT NULL,
--	[Calls] [float] NULL,
--	[Blocks] [float] NULL,
--	[MOC_Calls] [float] NULL,
--	[MOC_Blocks] [float] NULL,
--	[MTC_Calls] [float] NULL,
--	[MTC_Blocks] [float] NULL,
--	[Drops] [float] NULL,
--	[NUMBERS OF CALLS Non Sustainability (NB)] [float] NULL,
--	[NUMBERS OF CALLS Non Sustainability (WB)] [float] NULL,
--	[CST_AL_MO] [float] NULL,
--	[CST_AL_MT] [float] NULL,
--	[CST_CO_MO] [float] NULL,
--	[CST_CO_MT] [float] NULL,
--	[CST_ALERTING] [float] NULL,
--	[CST_CONNECT] [float] NULL,
--	[AVERAGE VOICE QUALITY (MOS)] [float] NULL,
--	[AVERAGE VOICE QUALITY NB (MOS)] [float] NULL,
--	[Samples_DL+UL] [float] NULL,
--	[Samples_DL+UL_NB] [float] NULL,
--	[MOS_Below2_5_samples] [float] NULL,
--	[MOS_NB_Below2_5_samples] [float] NULL,
--	[WB AMR Only] [float] NULL,
--	[Calls_Started_3G_WO_Fails] [float] NULL,
--	[Calls_Started_2G_WO_Fails] [float] NULL,
--	[Calls_Mixed] [float] NULL,
--	[Calls_Started_4G_WO_Fails] [float] NULL,
--	[Call_duration_3G] [float] NULL,
--	[Call_duration_2G] [float] NULL,
--	[CSFB_to_GSM_samples] [float] NULL,
--	[CSFB_to_UMTS_samples] [float] NULL,
--	[CSFB_samples] [float] NULL,
--	[Zona_OSP] [nvarchar](5) NULL,
--	[Zona_VDF] [nvarchar](7) NULL,
--	[Provincia_comp] [nvarchar](255) NULL,
--	[Type_Voice] [nvarchar](3) NOT NULL,
--	[Population] [float] NULL,
--	[MonthYear] [varchar](6) NOT NULL,
--	[ReportWeek] [nvarchar](3) NOT NULL,
--	[Percentil95_CST_MO_AL] [float] NULL,
--	[Percentil95_CST_MT_AL] [float] NULL,
--	[Percentil95_CST_MOMT_AL] [float] NULL,
--	[Percentil95_CST_MO_CO] [float] NULL,
--	[Percentil95_CST_MT_CO] [float] NULL,
--	[Percentil95_CST_MOMT_CO] [float] NULL,
--	[Percentil5_MOS_OVERALL] [float] NULL,
--	[Percentil5_MOS_NB] [float] NULL,
--	[Percentil95_CST_MO_AL_SCOPE] [float] NULL,
--	[Percentil95_CST_MT_AL_SCOPE] [float] NULL,
--	[Percentil95_CST_MOMT_AL_SCOPE] [float] NULL,
--	[Percentil95_CST_MO_CO_SCOPE] [float] NULL,
--	[Percentil95_CST_MT_CO_SCOPE] [float] NULL,
--	[Percentil95_CST_MOMT_CO_SCOPE] [float] NULL,
--	[Percentil5_MOS_OVERALL_SCOPE] [float] NULL,
--	[Percentil5_MOS_NB_SCOPE] [float] NULL,
--	[Percentil95_CST_MO_AL_SCOPE_QLIK] [float] NULL,
--	[Percentil95_CST_MT_AL_SCOPE_QLIK] [float] NULL,
--	[Percentil95_CST_MOMT_AL_SCOPE_QLIK] [float] NULL,
--	[Percentil95_CST_MO_CO_SCOPE_QLIK] [float] NULL,
--	[Percentil95_CST_MT_CO_SCOPE_QLIK] [float] NULL,
--	[Percentil95_CST_MOMT_CO_SCOPE_QLIK] [float] NULL,
--	[Percentil5_MOS_OVERALL_SCOPE_QLIK] [float] NULL,
--	[Percentil5_MOS_NB_SCOPE_QLIK] [float] NULL,
--	[Scope_Qlik] [varchar](255) NULL
--) ON [PRIMARY]

--END

-------------------------------------------------------------------------------------------------------------------------------------

if (select name from [DASHBOARD].sys.tables where name='lcc_voice_final_dashboard_Williams') is not null
BEGIN
	If(Select MonthYear+ReportWeek+id from [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams where MonthYear+ReportWeek+id = @monthYear+@ReportWeek+@id group by MonthYear+ReportWeek+id)<> ''
	BEGIN
		--print('Entra delete')
	  delete from [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams where MonthYear+ReportWeek+id = @monthYear+@ReportWeek+@id
	END
	If(Select MonthYear+ReportWeek from [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams where MonthYear+ReportWeek <> @monthYear+@ReportWeek group by MonthYear+ReportWeek)<>''
	BEGIN
		--print('Entra drop')
	  drop table [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams
	END	
END



if (select name from [DASHBOARD].sys.tables where name='lcc_voice_final_dashboard_Williams') is null
begin
	CREATE TABLE [DASHBOARD].[dbo].[lcc_voice_final_dashboard_Williams](
	[SCOPE] [varchar](255) NULL,
	[TECHNOLOGY] [varchar](256) NULL,
	[TEST_TYPE] [nvarchar](256) NULL,
	[TARGET ON SCOPE] [varchar](255) NULL,
	[CITIES_ROUTE_LINES_PLACE] [varchar](255) NULL,
	[CALL ATTEMPTS] [float] NULL,
	[ACCESS FAILURES] [float] NULL,
	[MO_CALL ATTEMPS] [float] NULL,
	[MO_CALL FAILURES] [float] NULL,
	[MT_CALL ATTEMPS] [float] NULL,
	[MT_CALL FAILURES] [float] NULL,
	[VOICE DROPPED] [float] NULL,
	[NUMBERS OF CALLS Non Sustainability (NB)] [float] NULL,
	[NUMBERS OF CALLS Non Sustainability (WB)] [float] NULL,
	[CALL SETUP TIME AVG - MO - ALERTING] [float] NULL,
	[CALL SETUP TIME AVG - MT - ALERTING] [float] NULL,
	[CALL SETUP TIME AVG - ALERTING] [float] NULL,
	[CALL SETUP TIME 95TH - MO - ALERTING] [float] NULL,
	[CALL SETUP TIME 95TH - MT - ALERTING] [float] NULL,
	[CALL SETUP TIME 95TH - ALERTING] [float] NULL,
	[CALL SETUP TIME AVG - MO - CONNECT] [float] NULL,
	[CALL SETUP TIME AVG - MT - CONNECT] [float] NULL,
	[CALL SETUP TIME AVG - CONNECT] [float] NULL,
	[CALL SETUP TIME 95TH - MO - CONNECT] [float] NULL,
	[CALL SETUP TIME 95TH - MT - CONNECT] [float] NULL,
	[CALL SETUP TIME 95TH - CONNECT] [float] NULL,
	[AVERAGE VOICE QUALITY NB (MOS)] [float] NULL,
	[Samples_DL+UL_NB] [float] NULL,
	[STARDARD DESVIATION - NB] [float] NULL,
	[NUMBERS OF VOICE SAMPLES < 2.5 - NB] [float] NULL,
	[5TH PERCENTILE - NB] [float] NULL,
	[AVERAGE VOICE QUALITY (MOS)] [float] NULL,
	[Samples_DL+UL] [float] NULL,
	[STARDARD DESVIATION - OVERALL] [float] NULL,
	[NUMBERS OF VOICE SAMPLES < 2.5 - OVERALL] [float] NULL,
	[5TH PERCENTILE - OVERALL] [float] NULL,
	[VOLTE AVG. SPEECH DELAY] [float] NULL,
	[NUMBERS OF CALL USING WB AMR CODEC ONLY] [float] NULL,
	[AVERAGE VOICE QUALITY WB AMR CODEC ONLY] [float] NULL,
	[MEDIAN VOICE QUALITY WB AMR CODEC ONLY] [float] NULL,
	[VOICE CALLS STARTED AND TERMINATED ON 3G] [float] NULL,
	[VOICE CALLS STARTED AND TERMINATED ON 2G] [float] NULL,
	[VOICE CALLS - MIXED] [float] NULL,
	[VOICE CALLS STARTED ON 4G] [float] NULL,
	[VOICE CALLS STARTED AND TERMINATED ON VOLTE] [float] NULL,
	[3G TOTAL DURATION] [float] NULL,
	[2G TOTAL DURATION] [float] NULL,
	[CALLS ON 2G LAYER AFTER CSFB PROCEDURE] [float] NULL,
	[CALLS ON 3G LAYER AFTER CSFB PROCEDURE] [float] NULL,
	[CALLS WWITH SRVCC PROCEDURE] [float] NULL,
	[URBAN_EXTENSION] [numeric](13, 2) NULL,
	[Population] [float] NULL,
	[SAMPLED_URBAN] [float] NULL,
	[NUMBER_TEST_KM] [float] NULL,
	[ROUTE] [varchar](1) NULL,
	[ALGORITHM] [varchar](255) NULL,
	[LANGUAGE] [varchar](255) NULL,
	[PHONE_MODEL] [varchar](255) NULL,
	[FIRM_VERSION] [varchar](255) NULL,
	[LAST_ACQUISITION] [varchar](258) NULL,
	[Operador] [varchar](8) NULL,
	[MCC] [int] NULL,
	[MNC] [varchar](256) NULL,
	[OPCOS] [varchar](255) NULL,
	[RAN_VENDOR] [nvarchar](16) NULL,
	[SCENARIOS] [varchar](1000) NULL,
	[PROVINCIA] [nvarchar](255) NULL,
	[CCAA] [varchar](256) NULL,
	[ZONA] [nvarchar](256) NULL,
	[id] [varchar](3) NULL,
	[ReportWeek] [varchar](10) NULL,
	[MonthYear] [varchar](10) NULL
) ON [PRIMARY]

END


----------------

insert into [dbo].[_Actualizacion_Qlik_DASH_Williams]
select '1.1 RI Voz Iniciado', getdate()

----------------
declare @filtro_operador as varchar(500)

 if @id='VDF'
	begin
		--set @filtro_youtube=''
		set @filtro_operador='Vodafone'
	end
else
	begin
		set @filtro_operador='Orange'
	end

-----------------------------------------------PRIMERA PARTE DEL CÓDIGO-------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
truncate table [_All_Voice]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Nos creamos una tabla base con toda la información llave de cada entidad y todas las entidades vodafone--------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

exec('

exec AddedValue.dbo.sp_lcc_dropifexists ''_base_entities_voice_Williams''

Select 	entities.operator as operator,
		entities.meas_Tech as meas_Tech,
		l.calltype as TEST_TYPE,
		l.report_type as report_type,
		entities.entity as entity,
		i.entities_dashboard as ENTITIES_DASHBOARD,
		Case when (entities.entity like ''AVE-%'' or entities.entity in (''MAD-VLC'',''MAD-BCN'',''MAD-SEV'') or entities.meas_Tech like ''%Road%'') then ''TRANSPORT'' else i.type_scope end as ''SCOPE'',
		Case when (entities.entity =''AVE-Madrid-Barcelona'' or entities.entity =''MAD-BCN'' or entities.entity =''AVE-Madrid-Valencia'' or entities.entity =''MAD-VLC'' or entities.entity = ''AVE-Madrid-Sevilla'' OR entities.entity = ''MAD-SEV'') then ''RAILWAYS''
			 when (entities.meas_Tech like ''%Road%'' and (entities.entity like ''A[1-9]-%'' or entities.entity in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''MAIN HIGHWAYS''
			 when (entities.meas_Tech like ''%Road%'' AND (entities.entity not like ''A[1-9]-%'' and entities.entity not in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''SECONDARY ROADS''
			 else i.scope end as ''SCOPE_DASH'',
		Case when (entities.entity like ''AVE-%'' or entities.entity in (''MAD-VLC'',''MAD-BCN'',''MAD-SEV'')) then ''RAILWAYS''
			 when (entities.meas_Tech like ''%Road%'' and (entities.entity like ''A[1-9]-%'' or entities.entity in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''MAIN HIGHWAYS''
			 when (entities.meas_Tech like ''%Road%'' AND (entities.entity not like ''A[1-9]-%'' and entities.entity not in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''SECONDARY ROADS''
			 else v.scope end as ''Scope_Qlik'',
		v.Provincia as Provincia_comp,
		case when entities.operator=''Vodafone'' then v.RAN_VENDOR_VDF 
			 when entities.operator=''Movistar'' then v.RAN_VENDOR_MOV 
			 when entities.operator=''Orange'' then v.RAN_VENDOR_OR 
			 when entities.operator=''Yoigo'' then v.RAN_VENDOR_YOI end as ''RAN_VENDOR'',
		v.CCAA as CCAA_Comp,
		v.Region_VF as Zona_VDF,
		v.Region_OSP as Zona_OSP,
		v.pob13 as population,
		t.SHEET as SHEET,
		t.TECHNOLOGY as TECHNOLOGY,
		t.[TYPE OF TEST] as [TYPE OF TEST],
		t.ALGORITHM as ALGORITHM,
		t.SPEECH_LANGUAGE as SPEECH_LANGUAGE,
		t.SMARTPHONE_MODEL as SMARTPHONE_MODEL,
		t.FIRMWARE_VERSION as FIRMWARE_VERSION,
		t.OPCOS as OPCOS,
		t.MCC as MCC,
		t.SCENARIO as SCENARIO

into _base_entities_voice_Williams
from 

		(Select entities_vdf.*, op.operator

		from (

		    --Sacamos una tabla con todas las entidades que tiene vodafone (si una entidad no la tiene vodafone es que no se entrega) y las replicamos para cada uno de los operadores

				Select distinct(entity),report_type,meas_tech
				from [QLIK].dbo._RI_Voice_Completed_Qlik 
				where  '+@last_measurement+' > 0 and (operator = ''Orange'' or operator = ''Movistar'' or operator = ''Vodafone'')
				and meas_tech in (''VOLTE All'',''VOLTE RealVOLTE'') and scope like ''%williams%''

				) entities_vdf,

				(select operator from [QLIK].dbo._RI_Voice_Completed_Qlik group by operator) op
		) entities

left outer join (Select * from [QLIK].dbo._RI_Voice_Completed_Qlik where '+@last_measurement+' > 0 and meas_LA=0 and meas_tech not like ''%cover%'') l on (entities.entity=l.entity and entities.operator=l.operator and entities.report_type=l.report_type and entities.meas_tech = l.meas_tech) 
	

left outer join 

		agrids.dbo.vlcc_dashboard_info_scopes_new i on (entities.entity = i.entities_BBDD and i.report = case when '''+@id+'''=''OSP'' then ''MUN'' else '''+@id+''' end)

left outer join 

	    [AGRIDS_v2].dbo.lcc_ciudades_tipo_Project_V9 v on (entities.entity = v.entity_name)

left outer join		
		[AGRIDS].dbo.vlcc_dashboard_info_Voice t on (t.entities_bbdd=entities.entity and t.technology=entities.meas_tech and t.report = case when '''+@id+'''=''OSP'' then ''MUN'' else '''+@id+''' end)

group by entities.operator,v.RAN_VENDOR_VDF,v.RAN_VENDOR_MOV,v.RAN_VENDOR_OR,v.RAN_VENDOR_YOI,entities.meas_Tech,entities.entity,i.Scope,v.scope, v.Region_OSP, v.Region_VF,i.entities_dashboard,
		 v.Provincia, v.CCAA,v.pob13,i.type_scope,l.calltype,l.report_type,t.SHEET,t.TECHNOLOGY,t.[TYPE OF TEST],t.ALGORITHM,
		t.SPEECH_LANGUAGE,t.SMARTPHONE_MODEL,t.FIRMWARE_VERSION,t.OPCOS,t.MCC,t.SCENARIO')

--select entity from _base_entities_voice_Williams
--group by entity
-- 2. Nos creamos una tabla con toda la información, tanto para QLIK como para el DASHBOARD-------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

	
exec(' insert into _All_Voice_Williams
		Select 
		entities.SCOPE,
		entities.meas_tech as TECHNOLOGY,
		Case when entities.SCOPE_DASH in (''SMALLER CITIES'',''MAIN CITIES'',''TOURISTIC AREA'',''MAIN HIGHWAYS'',''ADD-ON CITIES'',''ADD-ON CITIES EXTRA'',''SECONDARY ROADS'',''ADD-ON CITIES WILLIAMS'') then ''M2M''
			 else ''M2F'' end as TEST_TYPE,
		entities.SCOPE_DASH,
		entities.Scope_QLIK as SCOPE_QLIK,
		entities.entity as ENTITIES_BBDD,
		entities.ENTITIES_DASHBOARD,
		sum(q.Calls) as Calls,
		sum(q.Blocks) as Blocks,
		sum(q.MOC_Calls) as MOC_Calls,
		sum(q.MOC_Blocks) as MOC_Blocks,
		sum(q.MTC_Calls) as MTC_Calls,
		sum(q.MTC_Blocks) as MTC_Blocks,
		sum(q.Drops) as Drops,
		sum(q.[NUMBERS OF CALLS Non Sustainability (NB)]) as [NUMBERS OF CALLS Non Sustainability (NB)],
		sum(q.[NUMBERS OF CALLS Non Sustainability (WB)]) as [NUMBERS OF CALLS Non Sustainability (WB)],
		sum(q.[CST_MO_AL_NUM])/nullif(SUM(q.CST_MO_AL_samples),0) as CST_AL_MO,
		sum(q.[CST_MT_AL_NUM])/nullif(SUM(q.CST_MT_AL_samples),0) as CST_AL_MT,
		sum(q.CST_ALERTING_NUM)/nullif(SUM(q.CST_MO_AL_samples+q.CST_MT_AL_samples),0) as CST_ALERTING,
		sum(q.[CST_MO_CO_NUM])/nullif(SUM(q.CST_MO_CO_samples),0) as CST_CO_MO,
		sum(q.[CST_MT_CO_NUM])/nullif(SUM(q.CST_MT_CO_samples),0) as CST_CO_MT,
		sum(q.CST_CONNECT_NUM)/nullif(SUM(q.CST_MO_CO_samples+q.CST_MT_CO_samples),0) as CST_CONNECT,
		sum(q.MOS_NB_Num)/nullif(sum (q.MOS_NB_Den),0) AS [AVERAGE VOICE QUALITY NB (MOS)],
		sum(q.[Samples_DL+UL_NB]) as [Samples_DL+UL_NB],
		sum(q.[MOS_NB_Samples_Under_2.5]) AS MOS_NB_Below2_5_samples,
		sum(q.MOS_Num)/nullif(sum(q.MOS_Samples),0) AS [AVERAGE VOICE QUALITY (MOS)],	
		sum(q.[Samples_DL+UL]) as [Samples_DL+UL],
		sum(q.[MOS_Overall_Samples_Under_2.5]) as MOS_Below2_5_samples,
		case when sum(q.VOLTE_SpeechDelay_Den)>0 then sum(q.[VOLTE_SpeechDelay_Num])/(sum(q.[VOLTE_SpeechDelay_Den])) end as VOLTE_AVG_RTT,
		sum(q.[WB AMR Only]) as [WB AMR Only],  
		sum(q.[WB_AMR_Only_Num])/nullif(sum(q.[WB_AMR_Only_Den]),0) as [AVERAGE WB AMR Only],
		sum(q.Calls_Started_3G_WO_Fails) as Calls_Started_3G_WO_Fails, 
		sum(q.Calls_Started_2G_WO_Fails) as Calls_Started_2G_WO_Fails,
		sum(q.Calls_Mixed) as Calls_Mixed,
		sum(q.Calls_Started_4G_WO_Fails) as Calls_Started_4G_WO_Fails,
		sum(q.VOLTE_Calls_Started_Ended_VOLTE) as Calls_Started_VOLTE_WO_Fails,
		sum(q.Call_duration_3G) as Call_duration_3G,
		sum(q.Call_duration_2G) as Call_duration_2G,
		sum(q.CSFB_to_GSM_samples) as CSFB_to_GSM_samples,
		sum(q.CSFB_to_UMTS_samples) as CSFB_to_UMTS_samples,
		sum(q.CSFB_samples) as CSFB_samples,
		sum(q.VOLTE_Calls_withSRVCC) as VOLTE_Calls_withSRVCC,
		'''' as URBAN_EXTENSION,		
		entities.population as [Population],
		--Prodedimiento km2 medidos
		'''' as SAMPLED_URBAN,
		'''' as NUMBER_TEST_KM,
		'''' as [ROUTE],
		entities.[ALGORITHM] as [ALGORITHM],
		entities.[SPEECH_LANGUAGE] as [LANGUAGE],
		entities.SMARTPHONE_MODEL as PHONE_MODEL,
		entities.FIRMWARE_VERSION as FIRM_VERSION,
		''20'' + max(q.Meas_Date) as LAST_ACQUISITION,
		entities.operator as Operador,
		entities.MCC as MCC,
		Case when entities.operator = ''Vodafone'' then 1
			 when entities.operator = ''Movistar'' then 7
			 when entities.operator = ''Orange'' then 3
			 when entities.operator = ''Yoigo'' then 4 end as MNC,
		entities.OPCOS as OPCOS,
		entities.RAN_VENDOR as RAN_VENDOR,
		entities.SCENARIO as SCENARIOS,
		entities.Provincia_comp as PROVINCIA_DASH,
		--v.PROVINCIA_DASHBOARD as PROVINCIA_DASH,
		entities.CCAA_comp as CCAA_DASH,
		--v.CCAA_DASHBOARD as CCAA_DASH,
		entities.Zona_OSP as Zona_OSP,
		entities.Zona_VDF as Zona_VDF,
		--v.ORDER_DASHBOARD as ORDEN_DASH,
		entities.report_type as report_type,
		'''+@id+''' as id,
	    '''+@monthYear+''' as MonthYear,
	    '''+@ReportWeek+''' as ReportWeek	

from _base_entities_voice_Williams entities
		
left join		  
		  (Select * from [QLIK].dbo._RI_Voice_Completed_Qlik 
		  where '+@last_measurement+' > 0 
		  and meas_tech in (''VOLTE All'',''VOLTE RealVOLTE'') 
		  and scope like ''%williams%''
		  and meas_LA=0) q 

on (q.entity = entities.entity 
	and q.operator = entities.operator 
	and q.meas_tech = entities.meas_tech 
	and q.report_type = entities.report_type)
 
group by entities.SCOPE,entities.meas_tech,entities.SCOPE_DASH,entities.Scope_QLIK,entities.entity,entities.entities_dashboard,entities.population,entities.operator,entities.RAN_VENDOR,entities.Provincia_comp,entities.CCAA_comp,entities.Zona_OSP,entities.Zona_VDF,entities.report_type,
		entities.[ALGORITHM],entities.[SPEECH_LANGUAGE],entities.SMARTPHONE_MODEL,entities.FIRMWARE_VERSION,entities.MCC,entities.OPCOS,entities.SCENARIO	
')

		
--select ENTITIES_BBDD
--from _All_Voice_Williams
--group by ENTITIES_BBDD
---------------------------------------------------------------------------------------------------------------------
 --AÑADIMOS LOS PERCENTILES Y DESVIACIONES TIPICAS PARA VST Y MOS------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

exec('

	insert into [dbo].[_Actualizacion_Qlik_DASH_Williams]
	select ''Fin 1.2 Añadidos Kpis Voz'', getdate()

----------------


exec [AddedValue].[dbo].[plcc_voice_statistics_Williams] '+@last_measurement+'
exec [AddedValue].[dbo].[plcc_voice_statistics_Columns_new_Williams] '''+@monthYear+''' ,'''+@ReportWeek+'''



----------------

insert into [dbo].[_Actualizacion_Qlik_DASH_Williams]
select ''Fin 1.3 Percentiles Ejecutados'', getdate()')


-----------------------------------------------------------------------------------------------------------------------
-- Contruimos la tabla final con todos los KPIs de voz ----------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
exec('
Select q.*
	  ,p.[Percentil95_CST_MOMT_AL]
	  ,p.[Percentil95_CST_MOMT_CO]
      ,p.[Percentil5_MOS_OVERALL]
      ,p.[Percentil5_MOS_NB]
      ,p.[Median_MOS_WB]
      ,p.[Percentil95_CST_MOMT_AL_SCOPE]
      ,p.[Percentil95_CST_MOMT_CO_SCOPE]
      ,p.[Percentil5_MOS_OVERALL_SCOPE]
      ,p.[Percentil5_MOS_NB_SCOPE]
      ,p.[Median_MOS_WB_SCOPE]
      ,r.[Desviacion_NB]
      ,r.[Desviacion_OVERALL]
      ,r.[Desviacion_NB_SCOPE]
      ,r.[Desviacion_OVERALL_SCOPE]
    
into lcc_voice_final_Williams	  
from _All_Voice_Williams q 
		        left join _Percentiles_Voz_Williams p 
		        on (q.ENTITIES_BBDD=p.entidad 
		        	and q.mnc = p.mnc
					and q.id= Case when p.Report_QLIK=''MUN'' then ''OSP'' else ''VDF'' end 
					and q.technology=p.meas_tech 
					and q.monthyear = p.monthyear 
					and q.ReportWeek=p.ReportWeek)
				

				left join _Desviaciones_Voz_Williams r 
		        on (q.ENTITIES_BBDD=r.entidad 
		        	and q.mnc = r.mnc
					and q.id= Case when r.Report_QLIK=''MUN'' then ''OSP'' else ''VDF'' end 
					and q.technology=r.meas_tech 
					and r.monthyear = q.monthyear 
					and r.ReportWeek=q.ReportWeek)

where q.monthyear = '''+@monthYear+''' and q.ReportWeek = '''+@ReportWeek+'''

')

--select ENTITIES_BBDD
--from lcc_voice_final_Williams
--group by ENTITIES_BBDD
--SELECT * FROM lcc_voice_final_Williams
--WHERE entities_bbdd='AISA'
--SELECT * FROM _Percentiles
----------------

insert into [dbo].[_Actualizacion_Qlik_DASH_Williams]
select 'Fin 1.4 Tabla final rellena', getdate()


-----------------------------------------------------------------------------------------------------------------------
-- Contruimos la tabla especifica para QLIK o para el DASHBOARD en funcion de la entrada ------------------------------
-----------------------------------------------------------------------------------------------------------------------

-- Rellenamos la tabla del Dashboard
------------------------------------

print('Rellenamos la tabla del Dashboard')
	

exec('
	insert into [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams
	select 
		p.scope as SCOPE,
		case when p.technology  like (''VOLTE ALL%'') then ''VOLTE_CAP'' when p.technology like (''VOLTE RealVOLTE%'') then ''VOLTE_REAL'' when p.technology  like ''%4GOnly%'' then ''4G_ONLY'' when p.technology =''Road 4G'' then ''4G'' else p.technology end as TECHNOLOGY,
		p.test_type as TEST_TYPE,
		p.SCOPE_DASH as [TARGET ON SCOPE],
		p.entities_dashboard as [CITIES_ROUTE_LINES_PLACE],
		p.calls as [CALL ATTEMPTS],
		p.blocks as [ACCESS FAILURES],
		case when p.test_type=''M2F'' then p.MOC_Calls else NULL end as [MO_CALL ATTEMPS],
		case when p.test_type=''M2F'' then p.MOC_Blocks else NULL end as [MO_CALL FAILURES],
		case when p.test_type=''M2F'' then p.MTC_Calls else NULL end  as [MT_CALL ATTEMPS],
		case when p.test_type=''M2F'' then p.MTC_Blocks else NULL end as [MT_CALL FAILURES],
		p.Drops as [VOICE DROPPED],
		p.[NUMBERS OF CALLS Non Sustainability (NB)],
		p.[NUMBERS OF CALLS Non Sustainability (WB)],
		case when p.test_type=''M2F'' then p.CST_AL_MO else NULL end as [CALL SETUP TIME AVG - MO - ALERTING],
		case when p.test_type=''M2F'' then p.CST_AL_MT else NULL end as [CALL SETUP TIME AVG - MT - ALERTING],
		p.CST_ALERTING as [CALL SETUP TIME AVG - ALERTING],
		NULL as [CALL SETUP TIME 95TH - MO - ALERTING],
		NULL as [CALL SETUP TIME 95TH - MT - ALERTING],
		p.[Percentil95_CST_MOMT_AL] as [CALL SETUP TIME 95TH - ALERTING],
		case when p.test_type=''M2F'' then p.CST_CO_MO else NULL end as [CALL SETUP TIME AVG - MO - CONNECT],
		case when p.test_type=''M2F'' then p.CST_CO_MT else NULL end as [CALL SETUP TIME AVG - MT - CONNECT],
		p.CST_CONNECT as [CALL SETUP TIME AVG - CONNECT],
		NULL as [CALL SETUP TIME 95TH - MO - CONNECT],
		NULL as [CALL SETUP TIME 95TH - MT - CONNECT],
		p.[Percentil95_CST_MOMT_CO] as [CALL SETUP TIME 95TH - CONNECT],
		p.[AVERAGE VOICE QUALITY NB (MOS)],
		p.[Samples_DL+UL_NB],
		case when p.test_type=''M2F'' then p.[Desviacion_NB] else null end as [STARDARD DESVIATION - NB],
		case when p.test_type=''M2F'' then p.MOS_NB_Below2_5_samples else null end as [NUMBERS OF VOICE SAMPLES < 2.5 - NB],
		case when p.test_type=''M2F'' then p.[Percentil5_MOS_NB] else null end as [5TH PERCENTILE - NB],
		p.[AVERAGE VOICE QUALITY (MOS)],	
		p.[Samples_DL+UL],
		case when p.test_type=''M2M'' then p.[Desviacion_OVERALL] ELSE NULL END as [STARDARD DESVIATION - OVERALL],
		case when p.test_type=''M2M'' then p.MOS_Below2_5_samples ELSE NULL END as [NUMBERS OF VOICE SAMPLES < 2.5 - OVERALL],
		case when p.test_type=''M2M'' then p.[Percentil5_MOS_OVERALL] ELSE NULL END as [5TH PERCENTILE - OVERALL],
		p.VOLTE_AVG_RTT as [VOLTE AVG. SPEECH DELAY],
		p.[WB AMR Only] as [NUMBERS OF CALL USING WB AMR CODEC ONLY],  
		p.[AVERAGE WB AMR Only] as [AVERAGE VOICE QUALITY WB AMR CODEC ONLY],
		case when p.operador=''YOIGO'' then NULL
			 when p.[WB AMR Only]=0 then NULL
			 else p.[Median_MOS_WB] end as [MEDIAN VOICE QUALITY WB AMR CODEC ONLY],
		p.Calls_Started_3G_WO_Fails as [VOICE CALLS STARTED AND TERMINATED ON 3G], 
		p.Calls_Started_2G_WO_Fails as [VOICE CALLS STARTED AND TERMINATED ON 2G],
		p.Calls_Mixed as [VOICE CALLS - MIXED],
		p.Calls_Started_4G_WO_Fails as [VOICE CALLS STARTED ON 4G],
		p.Calls_Started_VOLTE_WO_Fails as [VOICE CALLS STARTED AND TERMINATED ON VOLTE],
		p.Call_duration_3G as [3G TOTAL DURATION],
		p.Call_duration_2G as [2G TOTAL DURATION],
		p.CSFB_to_GSM_samples as  [CALLS ON 2G LAYER AFTER CSFB PROCEDURE],
		p.CSFB_to_UMTS_samples as [CALLS ON 3G LAYER AFTER CSFB PROCEDURE],
		p.VOLTE_Calls_withSRVCC as [CALLS WWITH SRVCC PROCEDURE],
		km.[AreaTotal(km2)] as URBAN_EXTENSION,
		p.[Population],
		convert(float,km.Porcentaje_medido)/100 as SAMPLED_URBAN,
		convert(float,p.calls)/convert(float,km.[AreaTotal(km2)])/(convert(float,km.Porcentaje_medido)/100) as NUMBER_TEST_KM,
		p.[ROUTE],
		p.[ALGORITHM],
		p.[LANGUAGE],
		p.PHONE_MODEL,
		p.FIRM_VERSION,
		p.LAST_ACQUISITION,
		p.Operador,
		p.MCC,
		right(p.MNC,1),
		p.OPCOS,
		p.RAN_VENDOR,
		p.SCENARIOS,
		p.PROVINCIA_DASH as PROVINCIA,
		p.CCAA_DASH as CCAA,
		case when p.id=''VDF'' then p.Zona_VDF else p.Zona_OSP end as ZONA,
		'''+@id+''' as id,
		'''+@ReportWeek+''' as ReportWeek,
	    '''+@monthYear+''' as MonthYear
	   
		
		
	from lcc_voice_final_Williams p 
		left join lcc_km2_chequeo_mallado km on (p.ENTITIES_BBDD=km.entidad and (p.technology=km.techVoice or replace(p.technology,''4GOnly'',''4G'')=km.techVoice or replace(p.technology,''VOLTE ALL'',''VOLTE'')=km.techVoice or replace(p.technology,''VOLTE RealVOLTE'',''VOLTE'')=km.techVoice)
												and p.LAST_ACQUISITION=''20'' + km.date_reporting and p.report_type = km.report_type)
	where p.technology not like ''%3G%''
		and p.technology not like ''%VOLTE 4G%''
		and p.scope is not null
		and p.SCOPE_DASH not like ''%ROUND%''
		
')

--select * from [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams

--select [CITIES_ROUTE_LINES_PLACE] from [DASHBOARD].dbo.lcc_voice_final_dashboard_Williams
--group by [CITIES_ROUTE_LINES_PLACE]
---- Rellenamos la tabla de Qlik (N/A)
---------------------------------

--print('Rellenamos la tabla de Qlik')


--exec('

--if (select name from qlik.sys.tables where name=''lcc_voice_final_qlik_Williams'') is not null
--BEGIN	
--	If(Select MonthYear+ReportWeek+id from [QLIK].[dbo].lcc_voice_final_qlik_Williams where MonthYear+ReportWeek+id = '''+@monthYear+''' + '''+@ReportWeek+''' + '''+@id+''' group by MonthYear+ReportWeek+id)<> ''''
--	BEGIN
--	   delete from [QLIK].[dbo].lcc_voice_final_qlik_Williams where MonthYear = '''+@monthYear+''' and ReportWeek = '''+@ReportWeek+''' and id = '''+@id+'''
--	END
--END


--insert into [QLIK].[dbo].lcc_voice_final_qlik_Williams
--select  SCOPE_QLIK as Scope_Rest,
--		Operador as operator,
--		TECHNOLOGY as meas_tech,
--		ENTITIES_BBDD as entity,
--		report_type,
--		id,
--		Calls,
--		Blocks,
--		MOC_Calls,
--		MOC_Blocks,
--		MTC_Calls,
--		MTC_Blocks,
--		Drops,
--		[NUMBERS OF CALLS Non Sustainability (NB)],
--		[NUMBERS OF CALLS Non Sustainability (WB)],
--		CST_AL_MO,
--		CST_AL_MT,
--		CST_CO_MO,
--		CST_CO_MT,
--		CST_ALERTING,
--		CST_CONNECT,
--		[AVERAGE VOICE QUALITY (MOS)],
--		[AVERAGE VOICE QUALITY NB (MOS)],
--		[Samples_DL+UL],
--		[Samples_DL+UL_NB],
--		MOS_Below2_5_samples,
--		MOS_NB_Below2_5_samples,
--		[WB AMR Only],
--		Calls_Started_3G_WO_Fails,
--		Calls_Started_2G_WO_Fails,
--		Calls_Mixed,
--		Calls_Started_4G_WO_Fails,
--		Call_duration_3G,
--		Call_duration_2G,
--		CSFB_to_GSM_samples,
--		CSFB_to_UMTS_samples,
--		CSFB_samples,
--		Zona_OSP,
--		Zona_VDF,
--		PROVINCIA_DASH as Provincia_comp,
--		TEST_TYPE as Type_Voice,
--		Population,
--		MonthYear,
--		ReportWeek,
--		Percentil95_CST_MO_AL,
--		Percentil95_CST_MT_AL,
--		Percentil95_CST_MOMT_AL,
--		Percentil95_CST_MO_CO,
--		Percentil95_CST_MT_CO,
--		Percentil95_CST_MOMT_CO,
--		Percentil5_MOS_OVERALL,
--		Percentil5_MOS_NB,
--		Percentil95_CST_MO_AL_SCOPE,
--		Percentil95_CST_MT_AL_SCOPE,
--		Percentil95_CST_MOMT_AL_SCOPE,
--		Percentil95_CST_MO_CO_SCOPE,
--		Percentil95_CST_MT_CO_SCOPE,
--		Percentil95_CST_MOMT_CO_SCOPE,
--		Percentil5_MOS_OVERALL_SCOPE,
--		Percentil5_MOS_NB_SCOPE,
--		Percentil95_CST_MO_AL_SCOPE_QLIK,
--		Percentil95_CST_MT_AL_SCOPE_QLIK,
--		Percentil95_CST_MOMT_AL_SCOPE_QLIK,
--		Percentil95_CST_MO_CO_SCOPE_QLIK,
--		Percentil95_CST_MT_CO_SCOPE_QLIK,
--		Percentil95_CST_MOMT_CO_SCOPE_QLIK,
--		Percentil5_MOS_OVERALL_SCOPE_QLIK,
--		Percentil5_MOS_NB_SCOPE_QLIK,
--		Case When SCOPE_QLIK in (''Main Cities'', ''Smaller Cities'') then ''BIG CITIES''
--			 When SCOPE_QLIK in (''ADD-ON CITIES'', ''TOURISTIC AREA'') then ''SMALL CITIES''
--			 When SCOPE_QLIK = ''MAIN HIGHWAYS'' and Technology = ''Road 4G_1'' then ''ROADS'' end as SCOPE_QLIK


--from lcc_voice_final_Williams p


--')



insert into [dbo].[_Actualizacion_Qlik_DASH_Williams]
select '1.1 RI Voz Finalizado', getdate()

--select 'Acabado con éxito'




