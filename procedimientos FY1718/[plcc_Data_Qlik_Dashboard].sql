USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_Data_Qlik_Dashboard]    Script Date: 12/04/2018 10:19:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[plcc_Data_Qlik_Dashboard]

	  @monthYear as nvarchar(50)
	 ,@ReportWeek as nvarchar(50)
	 ,@last_measurement as varchar(256)
	 ,@id as varchar(50)

AS
-----------------------------------------------------------EXPLICACIÓN-----------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

/* En la primera parte del código se sacan todos los Scopes, las carreteras y los AVEs saldrán con el acumulado de 4 y 3 vueltas respectivamente.
Se obtiene una tabla de entidades Vodafone (ya que si algo se invalida en este operador, directamente esa entidad no se entregaría) y se cruza 
con el resto de operadores para que, si estuviese invalidado en otro operador saliese a NULL.
   En la segunda parte del código se hace un Union ALL con el mismo código pero adaptado para sacar la última vuelta de las carreteras. Esto
se hace para el Scoring y el Q&D. En esta parte del código, si la última vuelta de las carreteras para algún operador estuviese invalidad directamente
nos quedamos con la última vuelta váldia
   Al final del código, y sin nada que ver con lo anterior, tenemos las ejecuciones de procedimientos para que CENTRAL pueda sacar la info
de carreteras por Región*/

-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------




--declare @monthYear as nvarchar(50) = '201803'        --MES Y AÑO DE ACTUALIZACIÓN
--declare @ReportWeek as nvarchar(50) = 'W12'          --SEMANA DE ACTUALIZACIÓN
--declare @last_measurement as varchar(256) = 'last_measurement_osp'
--declare @id as varchar(50)='OSP'


----- Para el Dashboard de VDF solo sacamos los test de Youtube con la version 11, para el de OSP sacamos todos -------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
declare @filtro_youtube as varchar(500)
declare @filtro_operador as varchar(500)
declare @condicion_dash as varchar (4000)
declare @cruceKM as varchar(4000)
declare @cruceKM_4GOnly as varchar(4000)
declare @cruceKM_CAOnly as varchar(4000)
declare @selectKM as varchar(4000)



 if @id='VDF'
	begin
		--set @filtro_youtube=''
		set @filtro_youtube=' and cast(SUBSTRING(q.[YTB_Version],1, (CHARINDEX(''.'',q.[YTB_Version])+2)) as float) >=11'
		set @filtro_operador='Vodafone'
	end
else
	begin
		set @filtro_youtube=''
		set @filtro_operador='Orange'
	end


-- El Dashboar y Qlik no trabajan con la siguiente información ---------
------------------------------------------------------------------------


set @condicion_dash = 'scope not like ''%williams%'' and meas_tech not in (''NoCA_Device'',''3GOnly_3G'',''3GOnly_4G'',''Road 3GOnly'')'


----------------------------------  DEFINIMOS LA TABLA DE DATOS SI AÚN NO EXISTE --------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

exec sp_lcc_dropifexists '_Actualizacion_QLIK_DASH'

-- TABLA de SEGUIMIENTO de la ejecución del Procedimiento Kpis Qlik:
	
	if (select name from sys.tables where type='u' and name='_Actualizacion_QLIK_DASH') is null
	begin
		CREATE TABLE [dbo].[_Actualizacion_QLIK_DASH](
			[Status] [varchar](255) NULL,
			[Date] [datetime] NULL
		) ON [primary]

		insert into [dbo].[_Actualizacion_QLIK_DASH]
		select 'Inicio ejecucion procedimiento Dash Qlik Datos', getdate()
	end

exec sp_lcc_dropifexists '_All_Data'

if (select name from sys.tables where name='_All_Data') is null
begin
CREATE TABLE [dbo].[_All_Data](
	[SCOPE] [varchar](255) NULL,
	[TECHNOLOGY] [varchar](256) NULL,
	[SCOPE_DASH] [varchar](255) NULL,
	[SCOPE_QLIK] [varchar](255) NULL,
	[ENTIDAD] [varchar](256) NULL,
	[ENTITIES_DASHBOARD] [varchar](255) NULL,
	[Att_DL_CE] [float] NULL,
	[Fails_Acc_DL_CE] [float] NULL,
	[Fails_Ret_DL_CE] [float] NULL,
	[D1] [float] NULL,
	[D2] [float] NULL,
	[Num_Thput_3M] [float] NULL,
	[Num_Thput_1M] [float] NULL,
	[Peak_Data_DL_CE] [float] NULL,
	[SessionTime_DL_CE] [float] NULL,
	[final_date] [varchar](3) NULL,
	[Att_UL_CE] [float] NULL,
	[Fails_Acc_UL_CE] [float] NULL,
	[Fails_Ret_UL_CE] [float] NULL,
	[D3] [float] NULL,
	[Peak_Data_UL_CE] [float] NULL,
	[SessionTime_UL_CE] [float] NULL,
	[Att_DL_NC] [float] NULL,
	[Fails_Acc_DL_NC] [float] NULL,
	[Fails_Ret_DL_NC] [float] NULL,
	[Sessions_Thput_384K_DL_NC] [float] NULL,
	[MEAN_DATA_USER_RATE_DL_NC] [float] NULL,
	[Peak_Data_DL_NC] [float] NULL,
	[Att_UL_NC] [float] NULL,
	[Fails_Acc_UL_NC] [float] NULL,
	[Fails_Ret_UL_NC] [float] NULL,
	[Sessions_Thput_384K_UL_NC] [float] NULL,
	[MEAN_DATA_USER_RATE_UL_NC] [float] NULL,
	[Peak_Data_UL_NC] [float] NULL,
	[Latency_Att] [float] NULL,
	[LAT_AVG] [float] NULL,
	[Web_Att] [float] NULL,
	[Web_Failed] [float] NULL,
	[Web_Dropped] [float] NULL,
	[Web_SessionTime_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME] [float] NULL,
	[Web_HTTPS_Att] [float] NULL,
	[Web_HTTPS_Failed] [float] NULL,
	[Web_HTTPS_Dropped] [float] NULL,
	[Web_SessionTime_HTTPS_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME_HTTPS] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME_HTTPS] [float] NULL,
	[Web_Public_Att] [float] NULL,
	[Web_Public_Failed] [float] NULL,
	[Web_Public_Dropped] [float] NULL,
	[Web_SessionTime_Public_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME_Public] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME_Public] [float] NULL,
	[Att_YTB_SD] [float] NULL,
	[YTB_Fails_SD] [float] NULL,
	[YTB_Dropped_SD] [float] NULL,
	[YTB_B1_SD] [float] NULL,
	[YTB_B2_SD] [float] NULL,
	[Att_YTB_HD] [float] NULL,
	[YTB_Fails_HD] [float] NULL,
	[YTB_Dropped_HD] [float] NULL,
	[YTB_B1_HD] [float] NULL,
	[YTB_AVG_START_TIME] [float] NULL,
	[YTB_B2_HD] [float] NULL,
	[YTB_B2_HD_%] [float] NULL,
	[YTB_B3_HD] [float] NULL,
	[YTB_B5_HD] [int] NULL,
	[YTB_B4_HD] [float] NULL,
	[YTB_B6_HD] [float] NULL,
	[YTB_STARTED_TERMINATED_HD] [float] NULL,
	[Att_YTB_HD_vers11] [float] NULL,
	[YTB_Fails_HD_vers11] [float] NULL,
	[YTB_Dropped_HD_vers11] [float] NULL,
	[YTB_B1_HD_vers11] [float] NULL,
	[YTB_AVG_START_TIME_vers11] [float] NULL,
	[YTB_B2_HD_vers11] [float] NULL,
	[YTB_B2_HD_%_vers11] [float] NULL,
	[YTB_B3_HD_vers11] [float] NULL,
	[YTB_B5_HD_vers11] [int] NULL,
	[YTB_B4_HD_vers11] [float] NULL,
	[YTB_B6_HD_vers11] [float] NULL,
	[YTB_STARTED_TERMINATED_HD_vers11] [float] NULL,
	[Att_YTB_HD_Video1] [float] NULL,
	[YTB_Fails_HD_Video1] [float] NULL,
	[YTB_B1_HD_Video1] [float] NULL,
	[YTB_AVG_START_TIME_Video1] [float] NULL,
	[YTB_B2_HD_Video1] [float] NULL,
	[YTB_B2_HD_%_Video1] [float] NULL,
	[YTB_B3_HD_Video1] [float] NULL,
	[YTB_B5_HD_Video1] [int] NULL,
	[YTB_B4_HD_Video1] [float] NULL,
	[YTB_B6_HD_Video1] [float] NULL,
	[YTB_STARTED_TERMINATED_HD_Video1] [float] NULL,
	[Att_YTB_HD_Video2] [float] NULL,
	[YTB_Fails_HD_Video2] [float] NULL,
	[YTB_B1_HD_Video2] [float] NULL,
	[YTB_AVG_START_TIME_Video2] [float] NULL,
	[YTB_B2_HD_Video2] [float] NULL,
	[YTB_B2_HD_%_Video2] [float] NULL,
	[YTB_B3_HD_Video2] [float] NULL,
	[YTB_B5_HD_Video2] [int] NULL,
	[YTB_B4_HD_Video2] [float] NULL,
	[YTB_B6_HD_Video2] [float] NULL,
	[YTB_STARTED_TERMINATED_HD_Video2] [float] NULL,
	[Att_YTB_HD_Video3] [float] NULL,
	[YTB_Fails_HD_Video3] [float] NULL,
	[YTB_B1_HD_Video3] [float] NULL,
	[YTB_AVG_START_TIME_Video3] [float] NULL,
	[YTB_B2_HD_Video3] [float] NULL,
	[YTB_B2_HD_%_Video3] [float] NULL,
	[YTB_B3_HD_Video3] [float] NULL,
	[YTB_B5_HD_Video3] [int] NULL,
	[YTB_B4_HD_Video3] [float] NULL,
	[YTB_B6_HD_Video3] [float] NULL,
	[YTB_STARTED_TERMINATED_HD_Video3] [float] NULL,
	[Att_YTB_HD_Video4] [float] NULL,
	[YTB_Fails_HD_Video4] [float] NULL,
	[YTB_B1_HD_Video4] [float] NULL,
	[YTB_AVG_START_TIME_Video4] [float] NULL,
	[YTB_B2_HD_Video4] [float] NULL,
	[YTB_B2_HD_%_Video4] [float] NULL,
	[YTB_B3_HD_Video4] [float] NULL,
	[YTB_B5_HD_Video4] [int] NULL,
	[YTB_B4_HD_Video4] [float] NULL,
	[YTB_B6_HD_Video4] [float] NULL,
	[YTB_STARTED_TERMINATED_HD_Video4] [float] NULL,
	[Population] [float] NULL,
	[URBAN_EXTENSION] [varchar](1) NOT NULL,
	[SAMPLED_URBAN] [varchar](1) NOT NULL,
	[NUMBER_TEST_KM] [varchar](1) NOT NULL,
	[ROUTE] [varchar](1) NOT NULL,
	[PHONE_MODEL] [varchar](255) NULL,
	[FIRM_VERSION] [varchar](255) NULL,
	[HANDSET_CAPABILITY] [varchar](255) NULL,
	[TEST_MODALITY] [varchar](255) NULL,
	[MCC] [int] NULL,
	[OPCOS] [varchar](256) NULL,
	[SCENARIOS] [varchar](1000) NULL,
	[LAST_ACQUISITION] [varchar](258) NULL,
	[Operador] [varchar](256) NULL,
	[MNC] [varchar](256) NULL,
	[RAN_VENDOR] [nvarchar](256) NULL,
	--[PROVINCIA] [nvarchar](255) NULL,
	[PROVINCIA_DASH] [nvarchar](255) NULL,
	--[CCAA] [varchar](256) NULL,
	[CCAA_DASH] [varchar](256) NULL,
	[Zona_OSP] [varchar](256) NULL,
	[Zona_VDF] [varchar](256) NULL,
	--[ORDEN_DASH] [varchar](255) NULL,
	--[report_type] [varchar](256) NULL,
	[id] [varchar](256) NOT NULL,
	[MonthYear] [varchar](256) NOT NULL,
	[ReportWeek] [varchar](256) NOT NULL)
END


if (select name from qlik.sys.tables where name='lcc_data_final_qlik') is null
begin
	CREATE TABLE [QLIK].[dbo].[lcc_data_final_qlik](
	[Scope_Rest] [varchar](255) NULL,
	[Operator] [varchar](8) NULL,
	[meas_tech] [varchar](17) NOT NULL,
	[entity] [varchar](256) NULL,
	[final_date] [varchar](3) NULL,
	[id] [varchar](3) NOT NULL,
	[Att_DL_CE] [float] NULL,
	[Failed_Acc_DL_CE] [float] NULL,
	[Failed_Ret_DL_CE] [float] NULL,
	[D1] [float] NULL,
	[D2] [float] NULL,
	[Num_Thput_3M] [float] NULL,
	[Num_Thput_1M] [float] NULL,
	[SessionTime_DL_CE] [float] NULL,
	[Att_UL_CE] [float] NULL,
	[Failed_Acc_UL_CE] [float] NULL,
	[Failed_Ret_UL_CE] [float] NULL,
	[D3] [float] NULL,
	[SessionTime_UL_CE] [float] NULL,
	[Att_DL_NC] [float] NULL,
	[Failed_Acc_DL_NC] [float] NULL,
	[Failed_Ret_DL_NC] [float] NULL,
	[MEAN DATA USER RATE_DL_NC] [float] NULL,
	[Att_UL_NC] [float] NULL,
	[Failed_Acc_UL_NC] [float] NULL,
	[Failed_Ret_UL_NC] [float] NULL,
	[MEAN DATA USER RATE_UL_NC] [float] NULL,
	[Latency_Att] [float] NULL,
	[LAT_AVG] [float] NULL,
	[LAT_MED] [float] NULL,
	[LAT_D4] [float] NULL,
	[LAT_MEDIAN] [float] NULL,
	[Web_Att] [float] NULL,
	[Web_Failed] [float] NULL,
	[Web_Dropped] [float] NULL,
	[Web_SessionTime_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME] [float] NULL,
	[Web_HTTPS_Att] [float] NULL,
	[Web_HTTPS_Failed] [float] NULL,
	[Web_HTTPS_Dropped] [float] NULL,
	[Web_SessionTime_HTTPS_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME_HTTPS] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME_HTTPS] [float] NULL,
	[Web_Public_Att] [float] NULL,
	[Web_Public_Failed] [float] NULL,
	[Web_Public_Dropped] [float] NULL,
	[Web_SessionTime_Public_D5] [float] NULL,
	[WEB_IP_ACCESS_TIME_Public] [float] NULL,
	[WEB_HTTP_TRANSFER_TIME_Public] [float] NULL,
	[Att_YTB_SD] [float] NULL,
	[YTB_Failed_SD] [float] NULL,
	[YTB_Dropped_SD] [float] NULL,
	[YTB_B1_SD] [float] NULL,
	[YTB_B2_SD] [float] NULL,
	[Att_YTB_HD] [float] NULL,
	[YTB_Failed_HD] [float] NULL,
	[YTB_Dropped_HD] [float] NULL,
	[YTB_B1_HD] [float] NULL,
	[YTB_AVG_START_TIME] [float] NULL,
	[YTB_B2_HD] [float] NULL,
	[YTB_B2_HD_%] [float] NULL,
	[YTB_B3_HD] [float] NULL,
	[YTB_B5_HD] [float] NULL,
	[YTB_B4_HD] [float] NULL,
	[YTB_B6_HD] [float] NULL,
	[Zona_OSP] [nvarchar](5) NULL,
	[Zona_VDF] [nvarchar](7) NULL,
	[Provincia_comp] [nvarchar](255) NULL,
	[Population] [float] NULL,
	[MonthYear] [varchar](6) NOT NULL,
	[ReportWeek] [varchar](3) NOT NULL,
	[Percentil10_DL_CE] [float] NULL,
	[Percentil90_DL_CE] [float] NULL,
	[Percentil10_UL_CE] [float] NULL,
	[Percentil90_UL_CE] [float] NULL,
	[Percentil10_DL_NC] [float] NULL,
	[Percentil90_DL_NC] [float] NULL,
	[Percentil10_UL_NC] [float] NULL,
	[Percentil90_UL_NC] [float] NULL,
	[Percentil_PING] [float] NULL,
	[Percentil10_DL_CE_SCOPE] [float] NULL,
	[Percentil90_DL_CE_SCOPE] [float] NULL,
	[Percentil10_UL_CE_SCOPE] [float] NULL,
	[Percentil90_UL_CE_SCOPE] [float] NULL,
	[Percentil10_DL_NC_SCOPE] [float] NULL,
	[Percentil90_DL_NC_SCOPE] [float] NULL,
	[Percentil10_UL_NC_SCOPE] [float] NULL,
	[Percentil90_UL_NC_SCOPE] [float] NULL,
	[Percentil_PING_SCOPE] [float] NULL,
	[Percentil10_DL_CE_SCOPE_QLIK] [float] NULL,
	[Percentil90_DL_CE_SCOPE_QLIK] [float] NULL,
	[Percentil10_UL_CE_SCOPE_QLIK] [float] NULL,
	[Percentil90_UL_CE_SCOPE_QLIK] [float] NULL,
	[Percentil10_DL_NC_SCOPE_QLIK] [float] NULL,
	[Percentil90_DL_NC_SCOPE_QLIK] [float] NULL,
	[Percentil10_UL_NC_SCOPE_QLIK] [float] NULL,
	[Percentil90_UL_NC_SCOPE_QLIK] [float] NULL,
	[Percentil_PING_SCOPE_QLIK] [float] NULL,
	[SCOPE_QLIK] [varchar](255) NULL
) ON [PRIMARY]

END


--Comprobación lcc_data_final_dashboard
if (select name from DASHBOARD.sys.tables where name='lcc_data_final_dashboard') is not null
BEGIN
	If(Select MonthYear+ReportWeek+id from DASHBOARD.dbo.lcc_data_final_dashboard where MonthYear+ReportWeek+id = @monthYear+@ReportWeek+@id group by MonthYear+ReportWeek+id)<> ''
	BEGIN
	  delete from DASHBOARD.dbo.lcc_data_final_dashboard where MonthYear+ReportWeek+id = @monthYear+@ReportWeek+@id
	END
	If(Select MonthYear+ReportWeek from DASHBOARD.dbo.lcc_data_final_dashboard where MonthYear+ReportWeek <> @monthYear+@ReportWeek group by MonthYear+ReportWeek)<>''
	BEGIN
	  drop table DASHBOARD.dbo.lcc_data_final_dashboard
	END	
END


if (select name from DASHBOARD.sys.tables where name='lcc_data_final_dashboard') is null
begin
	CREATE TABLE DASHBOARD.[dbo].[lcc_data_final_dashboard](
	[SCOPE] [varchar](255) NULL,
	[TECHNOLOGY] [varchar](256) NULL,
	[CA_Y_N] [varchar](1) NOT NULL,
	[TARGET ON SCOPE] [varchar](255) NULL,
	[CITIES_ROUTE_LINES_PLACE] [varchar](255) NULL,
	[DL_CE NUMBER OF ATTEMPTS] [float] NULL,
	[DL_CE ERRORS IN ACCESIBILITY] [float] NULL,
	[DL_CE ERRORS IN RETAINABILITY] [float] NULL,
	[DL_CE D1.DOWNLOAD SPEED] [float] NULL,
	[DL_CE DESV] [float] NULL,
	[DL_CE D2] [float] NULL,
	[DL_CE NUMBER OF DL > 3 MBPS] [float] NULL,
	[DL_CE NUMBER OF DL > 1 MBPS] [float] NULL,
	[DL_CE PEAK DATA USER RATE] [float] NULL,
	[DL_CE 10TH PERCENTILE THR.] [float] NULL,
	[DL_CE 10TH PERCENTILE SCOPE] [float] NULL,
	[DL_CE 10TH PERCENTILE SCOPE_M_S] [float] NULL,
	[DL_CE 90TH PERCENTILE THR.] [float] NULL,
	[DL_CE 90TH PERCENTILE SCOPE] [float] NULL,
	[DL_CE 90TH PERCENTILE SCOPE_M_S] [float] NULL,
	[UL_CE NUMBER OF ATTEMPTS] [float] NULL,
	[UL_CE ERRORS IN ACCESIBILITY] [float] NULL,
	[UL_CE ERRORS IN RETAINABILITY] [float] NULL,
	[UL_CE D3.UPLOAD SPEED] [float] NULL,
	[UL_CE THROUGHPUT DESV] [float] NULL,
	[UL_CE PEAK DATA USER RATE] [float] NULL,
	[UL_CE 10TH PERCENTILE THR.] [float] NULL,
	[UL_CE 10TH PERCENTILE SCOPE] [float] NULL,
	[UL_CE 10TH PERCENTILE SCOPE_M_S] [float] NULL,
	[UL_CE 90TH PERCENTILE THR.] [float] NULL,
	[UL_CE 90TH PERCENTILE SCOPE] [float] NULL,
	[UL_CE 90TH PERCENTILE SCOPE_M_S] [float] NULL,
	[DL_NC NUMBER OF ATTEMPTS] [float] NULL,
	[DL_NC ERRORS IN ACCESIBILITY] [float] NULL,
	[DL_NC ERRORS IN RETAINABILITY] [float] NULL,
	[DL_NC SESSIONS THPUT EXCEDEED 384KBPS] [float] NULL,
	[DL_NC MEAN DATA USER RATE] [float] NULL,
	[DL_NC DESV] [float] NULL,
	[DL_NC PEAK DATA USER RATE] [float] NULL,
	[DL_NC 10TH PERCENTILE THR.] [float] NULL,
	[DL_NC 10TH PERCENTILE SCOPE] [float] NULL,
	[DL_NC 10TH PERCENTILE SCOPE_M_S] [float] NULL,
	[DL_NC 90TH PERCENTILE THR.] [float] NULL,
	[DL_NC 90TH PERCENTILE SCOPE] [float] NULL,
	[DL_NC 90TH PERCENTILE SCOPE_M_S] [float] NULL,
	[UL_NC NUMBER OF ATTEMPTS] [float] NULL,
	[UL_NC ERRORS IN ACCESIBILITY] [float] NULL,
	[UL_NC ERRORS IN RETAINABILITY] [float] NULL,
	[UL_NC SESSIONS THPUT EXCEDEED 384KBPS] [float] NULL,
	[UL_NC MEAN DATA USER RATE] [float] NULL,
	[UL_NC DESV] [float] NULL,
	[UL_NC PEAK DATA USER RATE] [float] NULL,
	[UL_NC 10TH PERCENTILE THR.] [float] NULL,
	[UL_NC 10TH PERCENTILE SCOPE] [float] NULL,
	[UL_NC 10TH PERCENTILE SCOPE_M_S] [float] NULL,
	[UL_NC 90TH PERCENTILE THR.] [float] NULL,
	[UL_NC 90TH PERCENTILE SCOPE] [float] NULL,
	[UL_NC 90TH PERCENTILE SCOPE_M_S] [float] NULL,
	[PING NUMBER OF ATTEMPTS] [float] NULL,
	[PING MEDIAN] [float] NULL,
	[PING AVG] [float] NULL,
	[PING MEDIAN SCOPE] [float] NULL,
	[PING MEDIAN SCOPE_M_S] [float] NULL,
	[WEB_HTTP ATTEMPTS] [float] NULL,
	[WEB_HTTP ACCESIBILITY] [float] NULL,
	[WEB_HTTP RETAINABILITY] [float] NULL,
	[WEB_HTTP SESS] [float] NULL,
	[WEB_HTTP IP ACC] [float] NULL,
	[WEB_HTTP TRANS] [float] NULL,
	[WEB_HTTPS ATTEMPTS] [float] NULL,
	[WEB_HTTPS ACCESIBILITY] [float] NULL,
	[WEB_HTTPS RETAINABILITY] [float] NULL,
	[WEB_HTTPS SESS] [float] NULL,
	[WEB_HTTPS IP ACC] [float] NULL,
	[WEB_HTTPS TRANS] [float] NULL,
	[YTB B5] [int] NULL,
	[YTB B4] [float] NULL,
	[YTB B6] [float] NULL,
	[YTB NUMBER OF VIDEO ACCESS ATTEMPTS] [float] NULL,
	[YTB VIDEO START TIME] [float] NULL,
	[YTB NUMBER OF VIDEO FAILURES] [float] NULL,
	[YTB B1] [float] NULL,
	[YTB B2] [float] NULL,
	[YTB VIDEOS START_TERM IN HD] [float] NULL,
	[YTB B2 %] [float] NULL,
	[YTB B3] [float] NULL,
	[YTB_V2 B5] [int] NULL,
	[YTB_V2 B4] [float] NULL,
	[YTB_V2 B6] [float] NULL,
	[YTB_V2 NUMBER OF VIDEO ACCESS ATTEMPTS] [float] NULL,
	[YTB_V2 VIDEO START TIME] [float] NULL,
	[YTB_V2 NUMBER OF VIDEO FAILURES] [float] NULL,
	[YTB_V2 B1] [float] NULL,
	[YTB_V2 B2] [float] NULL,
	[YTB_V2 VIDEOS START_TERM IN HD] [float] NULL,
	[YTB_V2 B2 %] [float] NULL,
	[YTB_V2 B3] [float] NULL,
	[YTB_V3 B5] [int] NULL,
	[YTB_V3 B4] [float] NULL,
	[YTB_V3 B6] [float] NULL,
	[YTB_V3 NUMBER OF VIDEO ACCESS ATTEMPTS] [float] NULL,
	[YTB_V3 VIDEO START TIME] [float] NULL,
	[YTB_V3 NUMBER OF VIDEO FAILURES] [float] NULL,
	[YTB_V3 B1] [float] NULL,
	[YTB_V3 B2] [float] NULL,
	[YTB_V3 VIDEOS START_TERM IN HD] [float] NULL,
	[YTB_V3 B2 %] [float] NULL,
	[YTB_V3 B3] [float] NULL,
	[YTB_V4 B5] [int] NULL,
	[YTB_V4 B4] [float] NULL,
	[YTB_V4 B6] [float] NULL,
	[YTB_V4 NUMBER OF VIDEO ACCESS ATTEMPTS] [float] NULL,
	[YTB_V4 VIDEO START TIME] [float] NULL,
	[YTB_V4 NUMBER OF VIDEO FAILURES] [float] NULL,
	[YTB_V4 B1] [float] NULL,
	[YTB_V4 B2] [float] NULL,
	[YTB_V4 VIDEOS START_TERM IN HD] [float] NULL,
	[YTB_V4 B2 %] [float] NULL,
	[YTB_V4 B3] [float] NULL,
	[URBAN_EXTENSION] [numeric](13, 2) NULL,
	[Population] [float] NULL,
	[SAMPLED_URBAN] [float] NULL,
	[NUMBER_TEST_KM] [float] NULL,
	[ROUTE] [varchar](1) NOT NULL,
	[PHONE_MODEL] [varchar](255) NULL,
	[FIRM_VERSION] [varchar](255) NULL,
	[HANDSET_CAPABILITY] [varchar](255) NULL,
	[TEST_MODALITY] [varchar](255) NULL,
	[LAST_ACQUISITION] [varchar](258) NULL,
	[Operador] [varchar](256) NULL,
	[MCC] [int] NULL,
	[MNC] [varchar](256) NULL,
	[OPCOS] [varchar](256) NULL,
	[RAN_VENDOR] [nvarchar](256) NULL,
	[SCENARIOS] [varchar](1000) NULL,
	[PROVINCIA] [nvarchar](255) NULL,
	[CCAA] [varchar](256) NULL,
	[ZONA] [varchar](256) NULL,
	[id] [varchar](256) NOT NULL,
	[reportweek] [varchar](256) NOT NULL,
	[monthyear] [varchar](256) NOT NULL

) ON [PRIMARY]

END



----------------
--truncate table [lcc_ActWeek_Data]

exec('

exec AddedValue.dbo.sp_lcc_dropifexists ''_All''
exec AddedValue.dbo.sp_lcc_dropifexists ''lcc_Data_final''
exec AddedValue.dbo.sp_lcc_dropifexists ''_base_entities_data''
exec AddedValue.dbo.sp_lcc_dropifexists ''_base_entities_data_road''

	

-- print(''1.Nos creamos una tabla con la suma de todos los attemps por operador, para la ponderación en los agregados, tipo carreteras y aves'')
----------------------------------------------------------------------------------------------------------------------------------------------


Select entities.operator,
	   entities.meas_Tech,
	  -- l.report_type,
	   entities.Test_type,
	   entities.entity as Entidad,
	   sum (l.Num_tests) as ''Att_All'',
	   sum (l.Failed) as ''Fails_All'',
	   sum (l.Throughput_Den) as ''Throughput_Den_All'',
	   sum (l.Session_time_Den) as ''SessionTime_Den_ALL'',
	   sum(l.Latency_Den) as ''Latency_All'',
	   sum(l.WEB_HTTP_TRANSFER_TIME_DEN) as ''WEB_HTTP_TRANSFER_TIME_All'',
	   sum(l.[WEB_IP_ACCESS_TIME_DEN]) as ''WEB_IP_ACCESS_TIME_All'',
	   sum(l.[WEB_IP_ACCESS_TIME_HTTPS_DEN]) as ''WEB_IP_ACCESS_TIME_HTTPS_All'',
	   sum(l.[WEB_TRANSFER_TIME_HTTPS_DEN]) as ''WEB_TRANSFER_TIME_HTTPS_All'',
	   sum(l.[WEB_IP_ACCESS_TIME_PUBLIC_DEN]) as ''WEB_IP_ACCESS_TIME_PUBLIC_All'',
	   sum(l.[WEB_TRANSFER_TIME_PUBLIC_DEN]) as ''WEB_TRANSFER_TIME_PUBLIC_All'',


	   sum(l.YTB_video_resolution_den) as ''YTB_video_resolution_All'',				
	   sum(l.YTB_video_mos_den) as ''YTB_video_mos_All'',
	   sum(l.avg_Video_startTime_Den) as ''avg_Video_startTime_Den_ALL'',
	   sum(l.Reproductions_WO_Interruptions_Den) as ''Reproductions_WO_Interruptions_ALL'',
	   sum(l.HD_reproduction_rate_den) AS ''HD_reproduction_rate_All'',

	   
	   sum (l.Reproducciones_Video1) as ''Att_All_Video1'',
	   sum (l.Fails_Video1) as ''Fails_All_Video1'',
	   sum(l.YTB_video_resolution_den_Video1) as ''YTB_video_resolution_All_Video1'',				
	   sum(l.YTB_video_mos_den_Video1) as ''YTB_video_mos_All_Video1'',
	   sum(l.avg_Video_startTime_Den_Video1) as ''avg_Video_startTime_Den_ALL_Video1'',
	   sum(l.Reproductions_WO_Interruptions_Den_Video1) as ''Reproductions_WO_Interruptions_ALL_Video1'',
	   sum(l.HD_reproduction_rate_den_Video1) AS ''HD_reproduction_rate_All_Video1'',

	   sum (l.Reproducciones_Video2) as ''Att_All_Video2'',
	   sum (l.Fails_Video2) as ''Fails_All_Video2'',
	   sum(l.YTB_video_resolution_den_Video2) as ''YTB_video_resolution_All_Video2'',				
	   sum(l.YTB_video_mos_den_Video2) as ''YTB_video_mos_All_Video2'',
	   sum(l.avg_Video_startTime_Den_Video2) as ''avg_Video_startTime_Den_ALL_Video2'',
	   sum(l.Reproductions_WO_Interruptions_Den_Video2) as ''Reproductions_WO_Interruptions_ALL_Video2'',
	   sum(l.HD_reproduction_rate_den_Video2) AS ''HD_reproduction_rate_All_Video2'',

	   sum (l.Reproducciones_Video3) as ''Att_All_Video3'',
	   sum (l.Fails_Video3) as ''Fails_All_Video3'',
	   sum(l.YTB_video_resolution_den_Video3) as ''YTB_video_resolution_All_Video3'',				
	   sum(l.YTB_video_mos_den_Video3) as ''YTB_video_mos_All_Video3'',
	   sum(l.avg_Video_startTime_Den_Video3) as ''avg_Video_startTime_Den_ALL_Video3'',
	   sum(l.Reproductions_WO_Interruptions_Den_Video3) as ''Reproductions_WO_Interruptions_ALL_Video3'',
	   sum(l.HD_reproduction_rate_den_Video3) AS ''HD_reproduction_rate_All_Video3'',

	   sum (l.Reproducciones_Video4) as ''Att_All_Video4'',
	   sum (l.Fails_Video4) as ''Fails_All_Video4'',
	   sum(l.YTB_video_resolution_den_Video4) as ''YTB_video_resolution_All_Video4'',				
	   sum(l.YTB_video_mos_den_Video4) as ''YTB_video_mos_All_Video4'',
	   sum(l.avg_Video_startTime_Den_Video4) as ''avg_Video_startTime_Den_ALL_Video4'',
	   sum(l.Reproductions_WO_Interruptions_Den_Video4) as ''Reproductions_WO_Interruptions_ALL_Video4'',
	   sum(l.HD_reproduction_rate_den_Video4) AS ''HD_reproduction_rate_All_Video4''



into _All


from 

-- Subquery para quedarnos con las entidades VDF y que todos los operadores tengan las mismas entidades.

	(Select entities_vdf.*, op.operator

	from (
		Select distinct(entity),test_type/*,report_type*/,meas_tech
		from [QLIK].dbo._RI_Data_Completed_Qlik 
		where  ' +@last_measurement+ ' <> 0 and operator = '''+@filtro_operador+''' and '+@condicion_dash+') entities_vdf,

		(select operator from [QLIK].dbo._RI_Data_Completed_Qlik group by operator) op
	) entities
	
	left outer join (Select * from [QLIK].dbo._RI_Data_Completed_Qlik where '+@last_measurement+' <> 0 and meas_LA=0) l on (entities.entity=l.entity and entities.test_type=l.test_type and entities.operator=l.operator /*and entities.report_type=l.report_type*/ and entities.meas_tech = l.meas_tech) /*and entities.round=l.round*/


group by entities.entity,entities.operator,entities.meas_Tech/*,l.report_type*/,entities.Test_type')




print('2. Nos creamos una tabla base con toda la información llave de cada entidad y todas las entidades') --------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
exec('


Select 	entities.operator,
		entities.meas_Tech,
		entities.entity,
		i.entities_dashboard as ENTITIES_DASHBOARD,
		Case when (entities.entity like ''AVE-%'' or entities.entity in (''MAD-VLC'',''MAD-BCN'',''MAD-SEV'') or entities.meas_Tech like ''%Road%'') then ''TRANSPORT'' else i.type_scope end as SCOPE,
		Case when (entities.entity =''AVE-Madrid-Barcelona'' or entities.entity =''MAD-BCN'' or entities.entity =''AVE-Madrid-Valencia'' or entities.entity =''MAD-VLC'' or entities.entity = ''AVE-Madrid-Sevilla'' OR entities.entity = ''MAD-SEV'') then ''RAILWAYS''
			 when (entities.meas_Tech like ''%Road%'' and (entities.entity <> ''A7-BARCELONA'' and entities.entity like ''A[1-9]-%'' or entities.entity in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''MAIN HIGHWAYS''
			 when (entities.meas_Tech like ''%Road%'' AND (entities.entity = ''A7-BARCELONA'' or entities.entity not like ''A[1-9]-%'' and entities.entity not in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''SECONDARY ROADS''
			 else i.scope end ''SCOPE_DASH'',
		Case when (entities.entity like ''AVE-%'' or entities.entity in (''MAD-VLC'',''MAD-BCN'',''MAD-SEV'')) then ''RAILWAYS''
			 when (entities.meas_Tech like ''%Road%'' and (entities.entity <> ''A7-BARCELONA'' and entities.entity like ''A[1-9]-%'' or entities.entity in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''MAIN HIGHWAYS''
			 when (entities.meas_Tech like ''%Road%'' AND (entities.entity = ''A7-BARCELONA'' or entities.entity not like ''A[1-9]-%'' and entities.entity not in (''A52-VIGO'',''A66-SEVILLA'',''A68-ZARAGOZA''))) then ''SECONDARY ROADS''
			 else v.scope end ''Scope_Qlik'',
		v.Provincia as Provincia_comp,
		case when entities.operator=''Vodafone'' then v.RAN_VENDOR_VDF 
			 when entities.operator=''Movistar'' then v.RAN_VENDOR_MOV 
			 when entities.operator=''Orange'' then v.RAN_VENDOR_OR 
			 when entities.operator=''Yoigo'' then v.RAN_VENDOR_YOI end as ''RAN_VENDOR'',
		v.CCAA as CCAA_Comp,
		v.Region_VF as Zona_VDF,
		v.Region_OSP as Zona_OSP,
		v.pob13 as population,
		t.SHEET,
		t.TECHNOLOGY,
		t.SMARTPHONE_MODEL,
		t.FIRMWARE_VERSION,
		t.HANDSET_CAPABILITY,
		t.TEST_MODALITY,
		t.OPCOS,
		t.MCC,
		t.SCENARIO


into _base_entities_data
from 

		(Select entities_vdf.*, op.operator

		from (

		    --Sacamos una tabla con todas las entidades que tiene vodafone (si una entidad no la tiene vodafone es que no se entrega) y las replicamos para cada uno de los operadores

			Select distinct(entity),meas_tech,scope,test_type
			from [QLIK].dbo._RI_Data_Completed_Qlik 
			where  '+@last_measurement+' > 0 
			and operator = '''+@filtro_operador+''' 
			and '+@condicion_dash+') entities_vdf,

			(select operator from [QLIK].dbo._RI_Data_Completed_Qlik group by operator) op

		) entities

left outer join 

	agrids.dbo.vlcc_dashboard_info_scopes_new i on (entities.entity = i.entities_BBDD and i.report = case when '''+@id+'''=''OSP'' then ''MUN'' else '''+@id+''' end)

left outer join 

	[AGRIDS_v2].dbo.lcc_ciudades_tipo_Project_V9 v on (entities.entity = v.entity_name)

left outer join		
    [AGRIDS].dbo.vlcc_dashboard_info_data t on (t.entities_bbdd=entities.entity and t.technology=entities.meas_tech and t.report = case when '''+@id+'''=''OSP'' then ''MUN'' else '''+@id+''' end)


group by entities.operator, entities.meas_Tech,i.type_scope,i.Scope,v.scope,
		 entities.entity,i.entities_dashboard,v.Region_OSP,v.Region_VF,v.Provincia,v.RAN_VENDOR_VDF, v.RAN_VENDOR_MOV,v.RAN_VENDOR_OR,v.RAN_VENDOR_YOI,v.CCAA,v.pob13,
		 t.SHEET,t.TECHNOLOGY,t.SMARTPHONE_MODEL,t.FIRMWARE_VERSION,t.OPCOS,t.MCC,t.SCENARIO,t.HANDSET_CAPABILITY,t.TEST_MODALITY

')

--select * from _base_entities_data
--where entity='a1-irun'

print('3. A nuestra tabla base le vamos uniendo todos los KPIs de los distintos Test_Type y le vamos dando formato Dashboard') -----------

exec(' 
insert into _All_Data
Select 
	entities.SCOPE,
	entities.meas_tech as TECHNOLOGY,
	Case when '''+@id+''' = ''VDF'' then entities.SCOPE_DASH else entities.Scope_QLIK end as SCOPE_DASH,
	entities.Scope_QLIK,
	entities.entity as ENTIDAD,
	entities.ENTITIES_DASHBOARD,
	
	dl_ce.Att_DL_CE,
	dl_ce.Fails_Acc_DL_CE,
	dl_ce.Fails_Ret_DL_CE,
	dl_ce.D1,
	dl_ce.D2,
	dl_ce.Num_Thput_3M,
	dl_ce.Num_Thput_1M,
	dl_ce.Peak_Data_DL_CE,
	dl_ce.SessionTime_DL_CE,
	null as final_date,

	ul_ce.Att_UL_CE,
	ul_ce.Fails_Acc_UL_CE,
	ul_ce.Fails_Ret_UL_CE,
	ul_ce.D3,
	ul_ce.Peak_Data_UL_CE,
	ul_ce.SessionTime_UL_CE,

	dl_nc.Att_DL_NC,
	dl_nc.Fails_Acc_DL_NC,
	dl_nc.Fails_Ret_DL_NC,
	dl_nc.Sessions_Thput_384K_DL_NC,
	dl_nc.[MEAN_DATA_USER_RATE_DL_NC],
	dl_nc.Peak_Data_DL_NC,

	ul_nc.Att_UL_NC,
	ul_nc.Fails_Acc_UL_NC,
	ul_nc.Fails_Ret_UL_NC,
	ul_nc.Sessions_Thput_384K_UL_NC,
	ul_nc.[MEAN_DATA_USER_RATE_UL_NC],
	ul_nc.Peak_Data_UL_NC,

	lat.Latency_Att,
	lat.LAT_AVG,

	web.Web_Att,
	web.Web_Failed,
	web.Web_Dropped,
	web.Web_SessionTime_D5,
	web.WEB_IP_ACCESS_TIME,
	web.WEB_HTTP_TRANSFER_TIME,

	whttps.Web_HTTPS_Att,
	whttps.Web_HTTPS_Failed,
	whttps.Web_HTTPS_Dropped,
	whttps.Web_SessionTime_HTTPS_D5,
	whttps.WEB_IP_ACCESS_TIME_HTTPS,
	whttps.WEB_HTTP_TRANSFER_TIME_HTTPS,

	wpublic.Web_Public_Att,
	wpublic.Web_Public_Failed,
	wpublic.Web_Public_Dropped,
	wpublic.Web_SessionTime_Public_D5,	
	wpublic.WEB_IP_ACCESS_TIME_Public,
	wpublic.WEB_HTTP_TRANSFER_TIME_Public,

	ytbsd.Att_YTB_SD,
	ytbsd.YTB_Fails_SD,
	ytbsd.YTB_Dropped_SD,
	ytbsd.YTB_B1_SD,
	ytbsd.YTB_B2_SD,

	ytbhd.Att_YTB_HD,
	ytbhd.YTB_Failed_HD,
	ytbhd.YTB_Dropped_HD,
	ytbhd.YTB_B1_HD,					--No olvidar restarle a 1 este valor en Qlik!! 							
	ytbhd.YTB_AVG_START_TIME,                                            
	ytbhd.YTB_B2_HD,
	ytbhd.[YTB_B2_HD_%],
	ytbhd.YTB_B3_HD,
	ytbhd.YTB_B5_HD,
	ytbhd.YTB_B4_HD,
	ytbhd.YTB_B6_HD,
	--Videos started/terminated in HD
	ytbhd.YTB_STARTED_TERMINATED_HD,

	-----YTB VERSION 11 O SUPERIOR
	ytbhdv11.Att_YTB_HD_vers11,
	ytbhdv11.YTB_Fails_HD_vers11,
	ytbhdv11.YTB_Dropped_HD_vers11,
	ytbhdv11.YTB_B1_HD_vers11,					 							
	ytbhdv11.YTB_AVG_START_TIME_vers11,                                            
	ytbhdv11.YTB_B2_HD_vers11,
	ytbhdv11.[YTB_B2_HD_%_vers11],
	ytbhdv11.YTB_B3_HD_vers11,
	ytbhdv11.YTB_B5_HD_vers11,
	ytbhdv11.YTB_B4_HD_vers11,
	ytbhdv11.YTB_B6_HD_vers11,
	ytbhdv11.YTB_STARTED_TERMINATED_HD_vers11,

	----VIDEO1
	ytbhdv.Att_YTB_HD_Video1,
	ytbhdv.YTB_Fails_HD_Video1,
	ytbhdv.YTB_B1_HD_Video1,								
	ytbhdv.YTB_AVG_START_TIME_Video1,                                            
	ytbhdv.YTB_B2_HD_Video1,
	ytbhdv.[YTB_B2_HD_%_Video1],
	ytbhdv.YTB_B3_HD_Video1,
	ytbhdv.YTB_B5_HD_Video1,
	ytbhdv.YTB_B4_HD_Video1,
	ytbhdv.YTB_B6_HD_Video1,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video1,

	----VIDEO2
	ytbhdv.Att_YTB_HD_Video2,
	ytbhdv.YTB_Fails_HD_Video2,
	ytbhdv.YTB_B1_HD_Video2,								
	ytbhdv.YTB_AVG_START_TIME_Video2,                                            
	ytbhdv.YTB_B2_HD_Video2,
	ytbhdv.[YTB_B2_HD_%_Video2],
	ytbhdv.YTB_B3_HD_Video2,
	ytbhdv.YTB_B5_HD_Video2,
	ytbhdv.YTB_B4_HD_Video2,
	ytbhdv.YTB_B6_HD_Video2,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video2,

	----VIDEO3
	ytbhdv.Att_YTB_HD_Video3,
	ytbhdv.YTB_Fails_HD_Video3,
	ytbhdv.YTB_B1_HD_Video3,								
	ytbhdv.YTB_AVG_START_TIME_Video3,                                            
	ytbhdv.YTB_B2_HD_Video3,
	ytbhdv.[YTB_B2_HD_%_Video3],
	ytbhdv.YTB_B3_HD_Video3,
	ytbhdv.YTB_B5_HD_Video3,
	ytbhdv.YTB_B4_HD_Video3,
	ytbhdv.YTB_B6_HD_Video3,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video3,

	----VIDEO4
	ytbhdv.Att_YTB_HD_Video4,
	ytbhdv.YTB_Fails_HD_Video4,
	ytbhdv.YTB_B1_HD_Video4,								
	ytbhdv.YTB_AVG_START_TIME_Video4,                                            
	ytbhdv.YTB_B2_HD_Video4,
	ytbhdv.[YTB_B2_HD_%_Video4],
	ytbhdv.YTB_B3_HD_Video4,
	ytbhdv.YTB_B5_HD_Video4,
	ytbhdv.YTB_B4_HD_Video4,
	ytbhdv.YTB_B6_HD_Video4,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video4,

	entities.population as [Population],

	--Prodedimiento km2 medidos
	'''''''' as URBAN_EXTENSION,
	'''''''' as SAMPLED_URBAN,
	'''''''' as NUMBER_TEST_KM,
	'''''''' as [ROUTE],

	entities.SMARTPHONE_MODEL as PHONE_MODEL,
	entities.FIRMWARE_VERSION as FIRM_VERSION,
	entities.HANDSET_CAPABILITY as HANDSET_CAPABILITY,
	entities.TEST_MODALITY as TEST_MODALITY,
	entities.MCC as MCC,
	entities.OPCOS as OPCOS, 
	entities.SCENARIO as SCENARIO,
	''20'' + max(dl_ce.max_date) as LAST_ACQUISITION,
	entities.operator as Operador,
	Case when entities.operator = ''Vodafone'' then 1
		 when entities.operator = ''Movistar'' then 7
		 when entities.operator = ''Orange'' then 3
		 when entities.operator = ''Yoigo'' then 4 end as MNC,
	entities.RAN_VENDOR as RAN_VENDOR,
	entities.Provincia_comp as PROVINCIA_DASH,
	--v.PROVINCIA_DASHBOARD as PROVINCIA_DASH,
	entities.CCAA_comp as CCAA_DASH,
	--v.CCAA_DASHBOARD as CCAA_DASH,                  --en qué se diferencian ambas provincias???
	entities.Zona_OSP as Zona_OSP,
	entities.Zona_VDF as Zona_VDF,
	'''+@id+''' as id,
	'''+@monthYear+''' as MonthYear,
	'''+@ReportWeek+''' as ReportWeek

from _base_entities_data entities
		

--left outer join
		
--	[AGRIDS].dbo.lcc_dashboard_info_data_FY1718 t on (t.scope= Case when '''+@id+''' = ''VDF'' then entities.SCOPE_DASH else entities.Scope_QLIK end 
--															and Case When ((t.scope = ''MAIN HIGHWAYS'' or t.scope = ''SECONDARY ROADS'') and t.technology = ''4G'') then ''Road 4G''
--																	 When ((t.scope = ''MAIN HIGHWAYS'' or t.scope = ''SECONDARY ROADS'') and t.technology = ''4G_ONLY'') then ''Road 4GOnly''
--																	 when t.technology = ''4G_ONLY'' then ''4GOnly'' else t.technology end = entities.meas_tech)


------------------------------------------------KPIs DL CE---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

  left join 
       ( Select q.operator,q.meas_tech,
				max(meas_date) as max_date,
				q.entity as entity,
				sum(Num_tests) as ''Att_DL_CE'',
				sum(Failed) as ''Fails_Acc_DL_CE'',
				sum(Dropped)as ''Fails_Ret_DL_CE'',
				case when (a.Throughput_Den_All >0) then sum(Throughput_Num)/(a.Throughput_Den_All) end as ''D1'',
				case when a.Throughput_Den_All>0 then 1.0*sum(Throughput_3M_Num)/a.Throughput_Den_All end as ''D2'',
				sum(Throughput_3M_Num) as ''Num_Thput_3M'',
				sum(Throughput_1M_Num) as ''Num_Thput_1M'',
				max(Throughput_Max) as ''Peak_Data_DL_CE'',
				case when SessionTime_Den_ALL >0 then sum(Session_time_Num)/a.SessionTime_Den_ALL end as ''SessionTime_DL_CE''				
		
			from  [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.test_type=a.test_type and
				 q.entity = a.entidad and q.' +@last_measurement+' <> 0  and q.meas_LA=0 and q.Test_type = ''CE_DL'' 
				 
			group by q.operator,q.meas_tech,/*,q.report_type*/a.Att_All,a.Throughput_Den_All,q.entity,a.SessionTime_Den_ALL
						) dl_ce on (entities.operator= dl_ce.operator and entities.meas_tech=dl_ce.meas_tech and entities.entity=dl_ce.entity /*and q.report_type=dl_ce.report_type*/)


------------------------------------------------KPIs UL CE---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
																												 
  left join 
       (Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_UL_CE'',
				sum(Failed) as ''Fails_Acc_UL_CE'',
				sum(Dropped)as ''Fails_Ret_UL_CE'',
				case when a.Throughput_Den_All>0 then sum(Throughput_Num)/a.Throughput_Den_All end as ''D3'',
				max(Throughput_Max) as ''Peak_Data_UL_CE'',
				case when a.SessionTime_Den_ALL >0 then sum(Session_time_Num)/(a.SessionTime_Den_ALL) end as ''SessionTime_UL_CE''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q,_All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+' <> 0 and q.meas_tech not like ''%cover%'' and q.meas_LA=0 and q.Test_type = ''CE_UL'' 
			group by q.operator,q.meas_tech,/*q.report_type,*/a.Att_All,a.Throughput_Den_All,q.entity,a.SessionTime_Den_ALL
				 ) ul_ce  on (entities.operator= ul_ce.operator and entities.meas_tech=ul_ce.meas_tech and entities.entity = ul_ce.entity /*and q.report_type=ul_ce.report_type*/)


------------------------------------------------KPIs DL NC---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------			


	left join 
		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_DL_NC'',
				sum(Failed) as ''Fails_Acc_DL_NC'',
				sum(Dropped)as ''Fails_Ret_DL_NC'',
				sum(Throughput_384K_Num) as ''Sessions_Thput_384K_DL_NC'',
				case when a.Throughput_Den_All>0 then sum(Throughput_Num)/a.Throughput_Den_All end as ''MEAN_DATA_USER_RATE_DL_NC'',
				max(Throughput_Max) as ''Peak_Data_DL_NC''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.'+@last_measurement+' <> 0 and q.meas_tech not like ''%cover%'' and q.meas_LA=0 and q.Test_type = ''NC_DL'' 
			group by q.operator,q.meas_tech/*,q.report_type*/,a.Throughput_Den_All,q.entity
				 ) dl_nc on (entities.operator= dl_nc.operator and entities.meas_tech=dl_nc.meas_tech and entities.entity =dl_nc.entity /*and q.report_type=dl_nc.report_type*/)


------------------------------------------------KPIs UL NC---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_UL_NC'',
				sum(Failed) as ''Fails_Acc_UL_NC'',
				sum(Dropped)as ''Fails_Ret_UL_NC'',
				sum(Throughput_384K_Num) as ''Sessions_Thput_384K_UL_NC'',
				case when a.Throughput_Den_All>0 then sum(Throughput_Num)/a.Throughput_Den_All end as ''MEAN_DATA_USER_RATE_UL_NC'',
				max(Throughput_Max) as ''Peak_Data_UL_NC''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.'+@last_measurement+' <> 0 and q.meas_LA=0 and q.Test_type = ''NC_UL'' 
			group by q.operator,q.meas_tech,a.Throughput_Den_All,q.entity/*,q.report_type*/
				 ) ul_nc on (entities.operator= ul_nc.operator and entities.meas_tech=ul_nc.meas_tech and entities.entity=ul_nc.entity /*and q.report_type=ul_nc.report_type*/)


------------------------------------------------KPIs LATENCIA---------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Latency_Den) as ''Latency_att'',
				case when a.Latency_All> 0  then round((1.0*Sum(Latency_Num)/a.Latency_All),0) end as ''LAT_AVG''
					
		 from [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

	     where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				  q.entity = a.entidad  and
				  (q.Methodology =''D16'' or (q.Methodology=''D15'' and q.scope not in (''MAIN CITIES'',''SMALLER CITIES'') AND q.meas_tech =''4G'')
				   or (q.Methodology=''D15''and q.meas_tech <>''4G''))
				  and q.' +@last_measurement+ ' <> 0 and q.meas_tech not like ''%cover%'' and q.meas_LA=0 and q.Test_type = ''Ping'' 
		 group by q.operator,q.meas_tech,q.entity,a.Latency_All/*,q.report_type*/,SCOPE
				) lat on (entities.operator= lat.operator and entities.meas_tech=lat.meas_tech and entities.entity=lat.entity /*and q.report_type=lat.report_type*/)

----------------------------------------------------WEB---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_Att'',
				sum(Failed) as ''Web_Failed'',
				sum(Dropped)as ''Web_Dropped'',
				case when a.SessionTime_Den_ALL >0 then sum(Session_time_Num)/a.SessionTime_Den_ALL end as ''Web_SessionTime_D5'',
				case when a.WEB_IP_ACCESS_TIME_All >0 then sum(WEB_IP_ACCESS_TIME_NUM)/a.WEB_IP_ACCESS_TIME_All end as ''WEB_IP_ACCESS_TIME'',
				case when a.WEB_HTTP_TRANSFER_TIME_All>0 then sum(WEB_HTTP_TRANSFER_TIME_NUM)/a.WEB_HTTP_TRANSFER_TIME_All end as ''WEB_HTTP_TRANSFER_TIME''
	
			from [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				  q.entity = a.entidad  
				  and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''WEB HTTP'' 
			group by q.operator,q.meas_tech,a.SessionTime_Den_ALL,a.WEB_IP_ACCESS_TIME_All,a.WEB_HTTP_TRANSFER_TIME_All,q.entity/*,q.report_type*/
				 ) web on (entities.operator= web.operator and entities.meas_tech=web.meas_tech and entities.entity=web.entity /*and q.report_type=web.report_type*/)


----------------------------------------------------WEB HTTPS---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_HTTPS_Att'',
				sum(Failed) as ''Web_HTTPS_Failed'',
				sum(Dropped)as ''Web_HTTPS_Dropped'',
				case when a.SessionTime_Den_ALL >0 then sum(Session_time_Num)/a.SessionTime_Den_ALL end as ''Web_SessionTime_HTTPS_D5'',
				case when a.WEB_IP_ACCESS_TIME_HTTPS_All>0 then 1.00*sum([WEB_IP_ACCESS_TIME_HTTPS_NUM])/WEB_IP_ACCESS_TIME_HTTPS_All end as ''WEB_IP_ACCESS_TIME_HTTPS'',
				case when WEB_TRANSFER_TIME_HTTPS_All>0 then sum([WEB_TRANSFER_TIME_HTTPS_NUM])/WEB_TRANSFER_TIME_HTTPS_All end as ''WEB_HTTP_TRANSFER_TIME_HTTPS''
				
			from 
				 [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''WEB HTTPS'' 
			group by q.operator,q.meas_tech,SessionTime_Den_ALL,WEB_IP_ACCESS_TIME_HTTPS_All,WEB_TRANSFER_TIME_HTTPS_All, q.entity/*,q.report_type*/
				) whttps on (entities.operator= whttps.operator and entities.meas_tech=whttps.meas_tech and entities.entity=whttps.entity /*and q.report_type=whttps.report_type*/)

----------------------------------------------------WEB Public---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_Public_Att'',
				sum(Failed) as ''Web_Public_Failed'',
				sum(Dropped)as ''Web_Public_Dropped'',
				case when a.SessionTime_Den_ALL >0 then sum(Session_time_Num)/a.SessionTime_Den_ALL end as ''Web_SessionTime_Public_D5'',
				case when a.WEB_IP_ACCESS_TIME_PUBLIC_ALL >0 then sum(WEB_IP_ACCESS_TIME_PUBLIC_NUM)/a.WEB_IP_ACCESS_TIME_PUBLIC_ALL end as ''WEB_IP_ACCESS_TIME_Public'',
				case when a.WEB_TRANSFER_TIME_PUBLIC_All>0 then sum(WEB_TRANSFER_TIME_PUBLIC_NUM)/ a.WEB_TRANSFER_TIME_PUBLIC_All end as ''WEB_HTTP_TRANSFER_TIME_Public''
				
			from 
				 [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''WEB PUBLIC'' 
			group by q.operator,q.meas_tech,SessionTime_Den_ALL,WEB_IP_ACCESS_TIME_PUBLIC_ALL,WEB_TRANSFER_TIME_PUBLIC_All, q.entity/*,q.report_type*/
				) wpublic on (entities.operator= wpublic.operator and entities.meas_tech=wpublic.meas_tech and entities.entity=wpublic.entity /*and q.report_type=wpublic.report_type*/)




----------------------------------------------------YOUTUBE SD---------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------	

	left join 

			(Select q.operator,q.meas_tech,
					q.entity as entity,
					sum(Num_tests) as ''Att_YTB_SD'',
					sum(Failed) as ''YTB_Fails_SD'',
					sum(Dropped)as ''YTB_Dropped_SD'',
					case when a.Att_All>0 then 1.0*sum(Failed)/a.Att_All end as ''YTB_B1_SD'',
					case when a.Reproductions_WO_Interruptions_ALL>0 then 1.00*sum(Reproductions_WO_Interruptions)/a.Reproductions_WO_Interruptions_ALL end as ''YTB_B2_SD''
				
				from  [QLIK].dbo._RI_Data_Completed_Qlik q, _All a

				where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''Youtube SD'' 
				    
				group by q.operator,q.meas_tech,a.Fails_All,a.Att_All,a.Reproductions_WO_Interruptions_ALL,q.entity/*,q.report_type*/
					 ) ytbsd on (entities.operator= ytbsd.operator and entities.meas_tech=ytbsd.meas_tech and entities.entity=ytbsd.entity /*and q.report_type=ytbsd.report_type*/)

----------------------------------------------------YOUTUBE HD GLOBAL_EXTRAEMOS EL GLOBAL Y V11 PARA DASHBOARD DE VDF--------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------


	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_YTB_HD'',
				sum(Failed) as ''YTB_Failed_HD'',
				sum(Dropped)as ''YTB_Dropped_HD'',
				case when a.Att_All >0 then 1.0*sum(Failed)/a.Att_All end as ''YTB_B1_HD'',             
				sum(Reproductions_WO_Interruptions) as ''YTB_B2_HD'',
				case when a.Reproductions_WO_Interruptions_ALL>0 then 1.00*sum(Reproductions_WO_Interruptions)/a.Reproductions_WO_Interruptions_ALL end as ''YTB_B2_HD_%'',
				Sum([Successful video download]) as ''YTB_B3_HD'',
				case when a.avg_Video_startTime_Den_ALL>0 then sum(Avg_Video_StarTime_Num)/a.avg_Video_startTime_Den_ALL end as ''YTB_AVG_START_TIME'',
				case when a.YTB_video_resolution_All>0 then cast(round(SUM(YTB_video_resolution_num)/a.YTB_video_resolution_All,0) as integer) end as ''YTB_B5_HD'',
				SUM(HD_reproduction_rate_num) as ''YTB_B4_HD'',
				case when a.YTB_video_mos_All>0 then sum(YTB_video_mos_num)/a.YTB_video_mos_All end as ''YTB_B6_HD'',
				sum(q.[ReproduccionesHD]) as ''YTB_STARTED_TERMINATED_HD''

				from [QLIK].dbo._RI_Data_Completed_Qlik q,_All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''Youtube HD'' 

			group by q.operator,q.meas_tech,q.entity,
			a.Fails_All,a.Att_All,Reproductions_WO_Interruptions_ALL,a.YTB_video_resolution_All,HD_reproduction_rate_ALL,a.YTB_video_mos_All,avg_Video_startTime_Den_ALL
			) ytbhd on (entities.operator= ytbhd.operator and entities.meas_tech=ytbhd.meas_tech and entities.entity=ytbhd.entity /*and q.report_type=ytbhd.report_type*/)

----------------------------------------------------YOUTUBE HD_V11 PARA DASHBOARD DE VDF-------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_YTB_HD_vers11'',
				sum(Failed) as ''YTB_Fails_HD_vers11'',
				sum(Dropped)as ''YTB_Dropped_HD_vers11'',
				case when a.Att_All >0 then 1.0*sum(Failed)/a.Att_All end as ''YTB_B1_HD_vers11'',             
				sum(Reproductions_WO_Interruptions) as ''YTB_B2_HD_vers11'',
				case when a.Reproductions_WO_Interruptions_ALL>0 then 1.00*sum(Reproductions_WO_Interruptions)/a.Reproductions_WO_Interruptions_ALL end as ''YTB_B2_HD_%_vers11'',
				Sum([Successful video download]) as ''YTB_B3_HD_vers11'',
				case when a.avg_Video_startTime_Den_ALL>0 then sum(Avg_Video_StarTime_Num)/a.avg_Video_startTime_Den_ALL end as ''YTB_AVG_START_TIME_vers11'',
				case when a.YTB_video_resolution_All>0 then cast(round(SUM(YTB_video_resolution_num)/a.YTB_video_resolution_All,0) as integer) end as ''YTB_B5_HD_vers11'',
				SUM(HD_reproduction_rate_num) as ''YTB_B4_HD_vers11'',
				case when a.YTB_video_mos_All>0 then sum(YTB_video_mos_num)/a.YTB_video_mos_All end as ''YTB_B6_HD_vers11'',
				sum(q.[ReproduccionesHD]) as ''YTB_STARTED_TERMINATED_HD_vers11''

				from [QLIK].dbo._RI_Data_Completed_Qlik q,_All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''Youtube HD'' ' +@filtro_youtube+ '

			group by q.operator,q.meas_tech,q.entity,
			a.Fails_All,a.Att_All,Reproductions_WO_Interruptions_ALL,a.YTB_video_resolution_All,HD_reproduction_rate_ALL,a.YTB_video_mos_All,avg_Video_startTime_Den_ALL
			) ytbhdv11 on (entities.operator= ytbhdv11.operator and entities.meas_tech=ytbhdv11.meas_tech and entities.entity=ytbhdv11.entity /*and q.report_type=ytbhdv11.report_type*/)

----------------------------------------------------YOUTUBE HD_DESGLOSADO POR 4 URLs (METOLODOGÍA FY1718)-------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Reproducciones_Video1) as ''Att_YTB_HD_Video1'',
				sum(Fails_Video1) as ''YTB_Fails_HD_Video1'',
				case when a.Att_All_Video1 >0 then 1.0*sum(Fails_Video1)/a.Att_All_Video1 end as ''YTB_B1_HD_Video1'',            
				sum(Reproductions_WO_Interruptions_Video1) as ''YTB_B2_HD_Video1'',
				case when a.Reproductions_WO_Interruptions_ALL_Video1>0 then 1.00*sum(Reproductions_WO_Interruptions_Video1)/a.Reproductions_WO_Interruptions_ALL_Video1 end as ''YTB_B2_HD_%_Video1'',
				Sum([Successful video download_Video1]) as ''YTB_B3_HD_Video1'',
				case when a.avg_Video_startTime_Den_ALL_Video1>0 then sum(Avg_Video_StarTime_Num_Video1)/a.avg_Video_startTime_Den_ALL_Video1 end as ''YTB_AVG_START_TIME_Video1'',
				case when a.YTB_video_resolution_All_Video1>0 then cast(round(SUM(YTB_video_resolution_num_Video1)/a.YTB_video_resolution_All_Video1,0) as integer) end as ''YTB_B5_HD_Video1'',
				SUM(HD_reproduction_rate_num_Video1) as ''YTB_B4_HD_Video1'',
				case when a.YTB_video_mos_All_Video1>0 then sum(YTB_video_mos_num_Video1)/a.YTB_video_mos_All_Video1 end as ''YTB_B6_HD_Video1'',
				sum(q.[ReproduccionesHD_Video1]) as ''YTB_STARTED_TERMINATED_HD_Video1'',

				sum(Reproducciones_Video2) as ''Att_YTB_HD_Video2'',
				sum(Fails_Video2) as ''YTB_Fails_HD_Video2'',
				case when a.Att_All_Video2 >0 then 1.0*sum(Fails_Video2)/a.Att_All_Video2 end as ''YTB_B1_HD_Video2'',             
				sum(Reproductions_WO_Interruptions_Video2) as ''YTB_B2_HD_Video2'',
				case when a.Reproductions_WO_Interruptions_ALL_Video2>0 then 1.00*sum(Reproductions_WO_Interruptions_Video2)/a.Reproductions_WO_Interruptions_ALL_Video2 end as ''YTB_B2_HD_%_Video2'',
				Sum([Successful video download_Video2]) as ''YTB_B3_HD_Video2'',
				case when a.avg_Video_startTime_Den_ALL_Video2>0 then sum(Avg_Video_StarTime_Num_Video2)/a.avg_Video_startTime_Den_ALL_Video2 end as ''YTB_AVG_START_TIME_Video2'',
				case when a.YTB_video_resolution_All_Video2>0 then cast(round(SUM(YTB_video_resolution_num_Video2)/a.YTB_video_resolution_All_Video2,0) as integer) end as ''YTB_B5_HD_Video2'',
				SUM(HD_reproduction_rate_num_Video2) as ''YTB_B4_HD_Video2'',
				case when a.YTB_video_mos_All_Video2>0 then sum(YTB_video_mos_num_Video2)/a.YTB_video_mos_All_Video2 end as ''YTB_B6_HD_Video2'',
				sum(q.[ReproduccionesHD_Video2]) as ''YTB_STARTED_TERMINATED_HD_Video2'',

				sum(Reproducciones_Video3) as ''Att_YTB_HD_Video3'',
				sum(Fails_Video3) as ''YTB_Fails_HD_Video3'',
				case when a.Att_All_Video3 >0 then 1.0*sum(Fails_Video3)/a.Att_All_Video3 end as ''YTB_B1_HD_Video3'',             
				sum(Reproductions_WO_Interruptions_Video3) as ''YTB_B2_HD_Video3'',
				case when a.Reproductions_WO_Interruptions_ALL_Video3>0 then 1.00*sum(Reproductions_WO_Interruptions_Video3)/a.Reproductions_WO_Interruptions_ALL_Video3 end as ''YTB_B2_HD_%_Video3'',
				Sum([Successful video download_Video3]) as ''YTB_B3_HD_Video3'',
				case when a.avg_Video_startTime_Den_ALL_Video3>0 then sum(Avg_Video_StarTime_Num_Video3)/a.avg_Video_startTime_Den_ALL_Video3 end as ''YTB_AVG_START_TIME_Video3'',
				case when a.YTB_video_resolution_All_Video3>0 then cast(round(SUM(YTB_video_resolution_num_Video3)/a.YTB_video_resolution_All_Video3,0) as integer) end as ''YTB_B5_HD_Video3'',
				SUM(HD_reproduction_rate_num_Video3) as ''YTB_B4_HD_Video3'',
				case when a.YTB_video_mos_All_Video3>0 then sum(YTB_video_mos_num_Video3)/a.YTB_video_mos_All_Video3 end as ''YTB_B6_HD_Video3'',
				sum(q.[ReproduccionesHD_Video3]) as ''YTB_STARTED_TERMINATED_HD_Video3'',



				sum(Reproducciones_Video4) as ''Att_YTB_HD_Video4'',
				sum(Fails_Video4) as ''YTB_Fails_HD_Video4'',
				case when a.Att_All_Video4 >0 then 1.0*sum(Fails_Video4)/a.Att_All_Video4 end as ''YTB_B1_HD_Video4'',             
				sum(Reproductions_WO_Interruptions_Video4) as ''YTB_B2_HD_Video4'',
				case when a.Reproductions_WO_Interruptions_ALL_Video4>0 then 1.00*sum(Reproductions_WO_Interruptions_Video4)/a.Reproductions_WO_Interruptions_ALL_Video4 end as ''YTB_B2_HD_%_Video4'',
				Sum([Successful video download_Video4]) as ''YTB_B3_HD_Video4'',
				case when a.avg_Video_startTime_Den_ALL_Video4>0 then sum(Avg_Video_StarTime_Num_Video4)/a.avg_Video_startTime_Den_ALL_Video4 end as ''YTB_AVG_START_TIME_Video4'',
				case when a.YTB_video_resolution_All_Video4>0 then cast(round(SUM(YTB_video_resolution_num_Video4)/a.YTB_video_resolution_All_Video4,0) as integer) end as ''YTB_B5_HD_Video4'',
				SUM(HD_reproduction_rate_num_Video4) as ''YTB_B4_HD_Video4'',
				case when a.YTB_video_mos_All_Video4>0 then sum(YTB_video_mos_num_Video4)/a.YTB_video_mos_All_Video4 end as ''YTB_B6_HD_Video4'',
				sum(q.[ReproduccionesHD_Video4]) as ''YTB_STARTED_TERMINATED_HD_Video4''

			from [QLIK].dbo._RI_Data_Completed_Qlik q,_All a

			where q.operator = a.operator and q.meas_Tech=a.meas_Tech /*and q.report_type=a.report_type*/ and q.Test_type=a.Test_type and
				q.entity = a.entidad and q.' +@last_measurement+ ' <> 0 and q.meas_LA=0 and q.Test_type = ''Youtube HD'' 

			group by q.operator,q.meas_tech,q.entity,
			a.Fails_All_Video1,a.Att_All_Video1,Reproductions_WO_Interruptions_ALL_Video1,a.YTB_video_resolution_All_Video1,HD_reproduction_rate_ALL_Video1,a.YTB_video_mos_All_Video1,avg_Video_startTime_Den_ALL_Video1,
			a.Fails_All_Video2,a.Att_All_Video2,Reproductions_WO_Interruptions_ALL_Video2,a.YTB_video_resolution_All_Video2,HD_reproduction_rate_ALL_Video2,a.YTB_video_mos_All_Video2,avg_Video_startTime_Den_ALL_Video2,
			a.Fails_All_Video3,a.Att_All_Video3,Reproductions_WO_Interruptions_ALL_Video3,a.YTB_video_resolution_All_Video3,HD_reproduction_rate_ALL_Video3,a.YTB_video_mos_All_Video3,avg_Video_startTime_Den_ALL_Video3,
			a.Fails_All_Video4,a.Att_All_Video4,Reproductions_WO_Interruptions_ALL_Video4,a.YTB_video_resolution_All_Video4,HD_reproduction_rate_ALL_Video4,a.YTB_video_mos_All_Video4,avg_Video_startTime_Den_ALL_Video4
					) ytbhdv on (entities.operator= ytbhdv.operator and entities.meas_tech=ytbhdv.meas_tech and entities.entity=ytbhdv.entity /*and q.report_type=ytbhdv.report_type*/)


					
group by entities.SCOPE,entities.meas_tech,entities.Scope_QLIK,entities.entity,entities.ENTITIES_DASHBOARD,dl_ce.Att_DL_CE,dl_ce.Fails_Acc_DL_CE,dl_ce.Fails_Ret_DL_CE,
	dl_ce.D1,dl_ce.D2,dl_ce.Num_Thput_3M,dl_ce.Num_Thput_1M,dl_ce.Peak_Data_DL_CE,dl_ce.SessionTime_DL_CE,ul_ce.Att_UL_CE,ul_ce.Fails_Acc_UL_CE,ul_ce.Fails_Ret_UL_CE,
	ul_ce.D3,ul_ce.Peak_Data_UL_CE,ul_ce.SessionTime_UL_CE,dl_nc.Att_DL_NC,dl_nc.Fails_Acc_DL_NC,dl_nc.Fails_Ret_DL_NC,dl_nc.Sessions_Thput_384K_DL_NC,
	dl_nc.[MEAN_DATA_USER_RATE_DL_NC],dl_nc.Peak_Data_DL_NC,ul_nc.Att_UL_NC,ul_nc.Fails_Acc_UL_NC,ul_nc.Fails_Ret_UL_NC,ul_nc.Sessions_Thput_384K_UL_NC,
	ul_nc.[MEAN_DATA_USER_RATE_UL_NC],ul_nc.Peak_Data_UL_NC,lat.Latency_Att,lat.LAT_AVG,web.Web_Att,web.Web_Failed,web.Web_Dropped,web.Web_SessionTime_D5,
	web.WEB_IP_ACCESS_TIME,web.WEB_HTTP_TRANSFER_TIME,whttps.Web_HTTPS_Att,whttps.Web_HTTPS_Failed,whttps.Web_HTTPS_Dropped,whttps.Web_SessionTime_HTTPS_D5,whttps.WEB_IP_ACCESS_TIME_HTTPS,
	whttps.WEB_HTTP_TRANSFER_TIME_HTTPS,wpublic.Web_Public_Att,wpublic.Web_Public_Failed,wpublic.Web_Public_Dropped,wpublic.Web_SessionTime_Public_D5,wpublic.WEB_IP_ACCESS_TIME_Public,
	wpublic.WEB_HTTP_TRANSFER_TIME_Public,ytbsd.Att_YTB_SD,ytbsd.YTB_Fails_SD,ytbsd.YTB_Dropped_SD,ytbsd.YTB_B1_SD,ytbsd.YTB_B2_SD,ytbhd.Att_YTB_HD,ytbhd.YTB_Failed_HD,
	ytbhd.YTB_Dropped_HD,ytbhd.YTB_B1_HD,ytbhd.YTB_AVG_START_TIME,ytbhd.YTB_B2_HD,ytbhd.[YTB_B2_HD_%],ytbhd.YTB_B3_HD,ytbhd.YTB_B5_HD,ytbhd.YTB_B4_HD,ytbhd.YTB_B6_HD,
	ytbhd.YTB_STARTED_TERMINATED_HD,ytbhdv11.Att_YTB_HD_vers11,ytbhdv11.YTB_Fails_HD_vers11,ytbhdv11.YTB_Dropped_HD_vers11,ytbhdv11.YTB_B1_HD_vers11,ytbhdv11.YTB_AVG_START_TIME_vers11,ytbhdv11.YTB_B2_HD_vers11,ytbhdv11.[YTB_B2_HD_%_vers11],ytbhdv11.YTB_B3_HD_vers11,ytbhdv11.YTB_B5_HD_vers11,ytbhdv11.YTB_B4_HD_vers11,ytbhdv11.YTB_B6_HD_vers11,
	ytbhdv11.YTB_STARTED_TERMINATED_HD_vers11,ytbhdv.Att_YTB_HD_Video1,ytbhdv.YTB_Fails_HD_Video1,ytbhdv.YTB_B1_HD_Video1,ytbhdv.YTB_AVG_START_TIME_Video1,                                            
	ytbhdv.YTB_B2_HD_Video1,ytbhdv.[YTB_B2_HD_%_Video1],ytbhdv.YTB_B3_HD_Video1,ytbhdv.YTB_B5_HD_Video1,ytbhdv.YTB_B4_HD_Video1,ytbhdv.YTB_B6_HD_Video1,ytbhdv.YTB_STARTED_TERMINATED_HD_Video1,
	ytbhdv.Att_YTB_HD_Video2,ytbhdv.YTB_Fails_HD_Video2,ytbhdv.YTB_B1_HD_Video2,ytbhdv.YTB_AVG_START_TIME_Video2,ytbhdv.YTB_B2_HD_Video2,ytbhdv.[YTB_B2_HD_%_Video2],
	ytbhdv.YTB_B3_HD_Video2,ytbhdv.YTB_B5_HD_Video2,ytbhdv.YTB_B4_HD_Video2,ytbhdv.YTB_B6_HD_Video2,ytbhdv.YTB_STARTED_TERMINATED_HD_Video2,ytbhdv.Att_YTB_HD_Video3,ytbhdv.YTB_Fails_HD_Video3,
	ytbhdv.YTB_B1_HD_Video3,ytbhdv.YTB_AVG_START_TIME_Video3,ytbhdv.YTB_B2_HD_Video3,ytbhdv.[YTB_B2_HD_%_Video3],ytbhdv.YTB_B3_HD_Video3,ytbhdv.YTB_B5_HD_Video3,
	ytbhdv.YTB_B4_HD_Video3,ytbhdv.YTB_B6_HD_Video3,ytbhdv.YTB_STARTED_TERMINATED_HD_Video3,ytbhdv.Att_YTB_HD_Video4,ytbhdv.YTB_Fails_HD_Video4,
	ytbhdv.YTB_B1_HD_Video4,ytbhdv.YTB_AVG_START_TIME_Video4,ytbhdv.YTB_B2_HD_Video4,ytbhdv.[YTB_B2_HD_%_Video4],ytbhdv.YTB_B3_HD_Video4,ytbhdv.YTB_B5_HD_Video4,ytbhdv.YTB_B4_HD_Video4,
	ytbhdv.YTB_B6_HD_Video4,ytbhdv.YTB_STARTED_TERMINATED_HD_Video4,entities.population,entities.SMARTPHONE_MODEL,entities.FIRMWARE_VERSION,entities.HANDSET_CAPABILITY,entities.TEST_MODALITY,
	entities.OPCOS,entities.operator,entities.RAN_VENDOR,entities.SCENARIO,entities.Provincia_comp,entities.SCOPE_DASH,
	entities.CCAA_comp,entities.Zona_OSP,entities.Zona_VDF--,v.ORDER_DASHBOARD,entities.report_type,entities.CCAA_comp,,entities.Provincia_comp,convert(varchar,right(q.mnc,1))
	,entities.MCC
')

print('4. Hacemos lo mismo pero sólo para la última vuelta de cada carretera') ----------------------------------------------------------------

exec('
insert into _All_DAta

Select 
	entities.SCOPE,
	entities.meas_tech+''_1'' as TECHNOLOGY,
	''MAIN HIGHWAYS LAST ROUND'' as SCOPE_DASH,
	entities.Scope_QLIK,
	entities.entity as ENTIDAD,
	entities.ENTITIES_DASHBOARD,
	
	dl_ce.Att_DL_CE,
	dl_ce.Fails_Acc_DL_CE,
	dl_ce.Fails_Ret_DL_CE,
	dl_ce.D1,
	dl_ce.D2,
	dl_ce.Num_Thput_3M,
	dl_ce.Num_Thput_1M,
	dl_ce.Peak_Data_DL_CE,
	dl_ce.SessionTime_DL_CE,
	dl_ce.final_date,

	ul_ce.Att_UL_CE,
	ul_ce.Fails_Acc_UL_CE,
	ul_ce.Fails_Ret_UL_CE,
	ul_ce.D3,
	ul_ce.Peak_Data_UL_CE,
	ul_ce.SessionTime_UL_CE,

	dl_nc.Att_DL_NC,
	dl_nc.Fails_Acc_DL_NC,
	dl_nc.Fails_Ret_DL_NC,
	dl_nc.Sessions_Thput_384K_DL_NC,
	dl_nc.[MEAN_DATA_USER_RATE_DL_NC],
	dl_nc.Peak_Data_DL_NC,

	ul_nc.Att_UL_NC,
	ul_nc.Fails_Acc_UL_NC,
	ul_nc.Fails_Ret_UL_NC,
	ul_nc.Sessions_Thput_384K_UL_NC,
	ul_nc.[MEAN_DATA_USER_RATE_UL_NC],
	ul_nc.Peak_Data_UL_NC,

	lat.Latency_Att,
	lat.LAT_AVG,

	web.Web_Att,
	web.Web_Failed,
	web.Web_Dropped,
	web.Web_SessionTime_D5,
	web.WEB_IP_ACCESS_TIME,
	web.WEB_HTTP_TRANSFER_TIME,

	whttps.Web_HTTPS_Att,
	whttps.Web_HTTPS_Failed,
	whttps.Web_HTTPS_Dropped,
	whttps.Web_SessionTime_HTTPS_D5,
	whttps.WEB_IP_ACCESS_TIME_HTTPS,
	whttps.WEB_HTTP_TRANSFER_TIME_HTTPS,

	wpublic.Web_Public_Att,
	wpublic.Web_Public_Failed,
	wpublic.Web_Public_Dropped,
	wpublic.Web_SessionTime_Public_D5,	
	wpublic.WEB_IP_ACCESS_TIME_Public,
	wpublic.WEB_HTTP_TRANSFER_TIME_Public,

	ytbsd.Att_YTB_SD,
	ytbsd.YTB_Fails_SD,
	ytbsd.YTB_Dropped_SD,
	ytbsd.YTB_B1_SD,
	ytbsd.YTB_B2_SD,

	ytbhd.Att_YTB_HD,
	ytbhd.YTB_Failed_HD,
	ytbhd.YTB_Dropped_HD,
	ytbhd.YTB_B1_HD,					--No olvidar restarle a 1 este valor en Qlik!! 							
	ytbhd.YTB_AVG_START_TIME,                                            
	ytbhd.YTB_B2_HD,
	ytbhd.[YTB_B2_HD_%],
	ytbhd.YTB_B3_HD,
	ytbhd.YTB_B5_HD,
	ytbhd.YTB_B4_HD,
	ytbhd.YTB_B6_HD,
	--Videos started/terminated in HD
	ytbhd.YTB_STARTED_TERMINATED_HD,

	-----YTB VERSION 11 O SUPERIOR
	ytbhdv11.Att_YTB_HD_vers11,
	ytbhdv11.YTB_Fails_HD_vers11,
	ytbhdv11.YTB_Dropped_HD_vers11,
	ytbhdv11.YTB_B1_HD_vers11,					 							
	ytbhdv11.YTB_AVG_START_TIME_vers11,                                            
	ytbhdv11.YTB_B2_HD_vers11,
	ytbhdv11.[YTB_B2_HD_%_vers11],
	ytbhdv11.YTB_B3_HD_vers11,
	ytbhdv11.YTB_B5_HD_vers11,
	ytbhdv11.YTB_B4_HD_vers11,
	ytbhdv11.YTB_B6_HD_vers11,
	ytbhdv11.YTB_STARTED_TERMINATED_HD_vers11,

	----VIDEO1
	ytbhdv.Att_YTB_HD_Video1,
	ytbhdv.YTB_Fails_HD_Video1,
	ytbhdv.YTB_B1_HD_Video1,								
	ytbhdv.YTB_AVG_START_TIME_Video1,                                            
	ytbhdv.YTB_B2_HD_Video1,
	ytbhdv.[YTB_B2_HD_%_Video1],
	ytbhdv.YTB_B3_HD_Video1,
	ytbhdv.YTB_B5_HD_Video1,
	ytbhdv.YTB_B4_HD_Video1,
	ytbhdv.YTB_B6_HD_Video1,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video1,

	----VIDEO2
	ytbhdv.Att_YTB_HD_Video2,
	ytbhdv.YTB_Fails_HD_Video2,
	ytbhdv.YTB_B1_HD_Video2,								
	ytbhdv.YTB_AVG_START_TIME_Video2,                                            
	ytbhdv.YTB_B2_HD_Video2,
	ytbhdv.[YTB_B2_HD_%_Video2],
	ytbhdv.YTB_B3_HD_Video2,
	ytbhdv.YTB_B5_HD_Video2,
	ytbhdv.YTB_B4_HD_Video2,
	ytbhdv.YTB_B6_HD_Video2,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video2,

	----VIDEO3
	ytbhdv.Att_YTB_HD_Video3,
	ytbhdv.YTB_Fails_HD_Video3,
	ytbhdv.YTB_B1_HD_Video3,								
	ytbhdv.YTB_AVG_START_TIME_Video3,                                            
	ytbhdv.YTB_B2_HD_Video3,
	ytbhdv.[YTB_B2_HD_%_Video3],
	ytbhdv.YTB_B3_HD_Video3,
	ytbhdv.YTB_B5_HD_Video3,
	ytbhdv.YTB_B4_HD_Video3,
	ytbhdv.YTB_B6_HD_Video3,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video3,

	----VIDEO4
	ytbhdv.Att_YTB_HD_Video4,
	ytbhdv.YTB_Fails_HD_Video4,
	ytbhdv.YTB_B1_HD_Video4,								
	ytbhdv.YTB_AVG_START_TIME_Video4,                                            
	ytbhdv.YTB_B2_HD_Video4,
	ytbhdv.[YTB_B2_HD_%_Video4],
	ytbhdv.YTB_B3_HD_Video4,
	ytbhdv.YTB_B5_HD_Video4,
	ytbhdv.YTB_B4_HD_Video4,
	ytbhdv.YTB_B6_HD_Video4,
	ytbhdv.YTB_STARTED_TERMINATED_HD_Video4,

	entities.population as [Population],

	--Prodedimiento km2 medidos
	'''''''' as URBAN_EXTENSION,
	'''''''' as SAMPLED_URBAN,
	'''''''' as NUMBER_TEST_KM,
	'''''''' as [ROUTE],

	entities.SMARTPHONE_MODEL as PHONE_MODEL,
	entities.FIRMWARE_VERSION as FIRM_VERSION,
	entities.HANDSET_CAPABILITY as HANDSET_CAPABILITY,
	entities.TEST_MODALITY as TEST_MODALITY,
	entities.MCC as MCC,
	entities.OPCOS, 
	entities.SCENARIO,
	''20'' + max(dl_ce.max_date) as LAST_ACQUISITION,
	entities.operator as Operador,
	Case when entities.operator = ''Vodafone'' then 1
		 when entities.operator = ''Movistar'' then 7
		 when entities.operator = ''Orange'' then 3
		 when entities.operator = ''Yoigo'' then 4 end as MNC,
	entities.RAN_VENDOR,
	entities.Provincia_comp as PROVINCIA_DASH,
	--v.PROVINCIA_DASHBOARD as PROVINCIA_DASH,
	entities.CCAA_comp as CCAA_DASH,
	--v.CCAA_DASHBOARD as CCAA_DASH,                  --en qué se diferencian ambas provincias???
	entities.Zona_OSP,
	entities.Zona_VDF,
	'''+@id+''' as id,
	'''+@monthYear+''' as MonthYear,
	'''+@ReportWeek+''' as ReportWeek

from _base_entities_data entities
		

--left outer join
		
--	[AGRIDS].dbo.lcc_dashboard_info_data_FY1718 t on (t.scope= Case when '''+@id+''' = ''VDF'' then entities.SCOPE_DASH else entities.Scope_QLIK end
--															and Case When ((t.scope = ''MAIN HIGHWAYS'' or t.scope = ''SECONDARY ROADS'') and t.technology = ''4G'') then ''Road 4G''
--																	 When ((t.scope = ''MAIN HIGHWAYS'' or t.scope = ''SECONDARY ROADS'') and t.technology = ''4G_ONLY'') then ''Road 4GOnly''
--																	 when t.technology = ''4G_ONLY'' then ''4GOnly'' else t.technology end = entities.meas_tech)


------------------------------------------------KPIs DL CE---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

  left join 
       ( Select q.operator,q.meas_tech,
				max(meas_date) as max_date,
				max(meas_week) as final_date,
				q.entity as entity,
				sum(Num_tests) as ''Att_DL_CE'',
				sum(Failed) as ''Fails_Acc_DL_CE'',
				sum(Dropped)as ''Fails_Ret_DL_CE'',
				case when (sum (Throughput_Den) >0) then sum(Throughput_Num)/sum (Throughput_Den) end as ''D1'',
				case when( sum (Throughput_Den)>0) then 1.0*sum(Throughput_3M_Num)/sum (Throughput_Den) end as ''D2'',
				sum(Throughput_3M_Num) as ''Num_Thput_3M'',
				sum(Throughput_1M_Num) as ''Num_Thput_1M'',
				max(Throughput_Max) as ''Peak_Data_DL_CE'',
				case when (sum (Session_time_Den) >0) then sum(Session_time_Num)/sum (Session_time_Den) end as ''SessionTime_DL_CE''				
		
			from  [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1  and q.meas_LA=0 and q.Test_type = ''CE_DL'' 
				 
			group by q.operator,q.meas_tech,q.[round],q.entity
						) dl_ce on (entities.operator= dl_ce.operator and entities.meas_tech=dl_ce.meas_tech and entities.entity=dl_ce.entity)



------------------------------------------------KPIs UL CE---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
																												 
  left join 
       (Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_UL_CE'',
				sum(Failed) as ''Fails_Acc_UL_CE'',
				sum(Dropped)as ''Fails_Ret_UL_CE'',
				case when (sum (Throughput_Den) >0) then sum(Throughput_Num)/sum (Throughput_Den) end as ''D3'',
				max(Throughput_Max) as ''Peak_Data_UL_CE'',
				case when sum (Session_time_Den) >0 then sum(Session_time_Num)/sum (Session_time_Den) end as ''SessionTime_UL_CE''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_tech not like ''%cover%'' and q.meas_LA=0 and q.Test_type = ''CE_UL'' 
			group by q.operator,q.meas_tech,q.entity
				 ) ul_ce  on (entities.operator= ul_ce.operator and entities.meas_tech=ul_ce.meas_tech and entities.entity = ul_ce.entity)


------------------------------------------------KPIs DL NC---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------			


	left join 
		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_DL_NC'',
				sum(Failed) as ''Fails_Acc_DL_NC'',
				sum(Dropped)as ''Fails_Ret_DL_NC'',
				sum(Throughput_384K_Num) as ''Sessions_Thput_384K_DL_NC'',
				case when (sum (Throughput_Den) >0) then sum(Throughput_Num)/sum (Throughput_Den) end as ''MEAN_DATA_USER_RATE_DL_NC'',
				max(Throughput_Max) as ''Peak_Data_DL_NC''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+'=1 and q.meas_LA=0 and q.Test_type = ''NC_DL'' 
			group by q.operator,q.meas_tech/*,q.report_type*/,q.entity
				 ) dl_nc on (entities.operator= dl_nc.operator and entities.meas_tech=dl_nc.meas_tech and entities.entity =dl_nc.entity)


------------------------------------------------KPIs UL NC---------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_UL_NC'',
				sum(Failed) as ''Fails_Acc_UL_NC'',
				sum(Dropped)as ''Fails_Ret_UL_NC'',
				sum(Throughput_384K_Num) as ''Sessions_Thput_384K_UL_NC'',
				case when (sum (Throughput_Den) >0) then sum(Throughput_Num)/sum (Throughput_Den) end as ''MEAN_DATA_USER_RATE_UL_NC'',
				max(Throughput_Max) as ''Peak_Data_UL_NC''

				
			from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''NC_UL'' 
			group by q.operator,q.meas_tech,q.entity/*,q.report_type*/
				 ) ul_nc on (entities.operator= ul_nc.operator and entities.meas_tech=ul_nc.meas_tech and entities.entity=ul_nc.entity)


------------------------------------------------KPIs LATENCIA---------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Latency_Den) as ''Latency_att'',
				case when sum(Latency_Den)>0  then round(1.0*Sum(Latency_Num)/sum(Latency_Den),0) end as ''LAT_AVG''
					
		 from [QLIK].dbo._RI_Data_Completed_Qlik q

	     where q.meas_Tech like ''%Road 4G%'' and
				  (q.Methodology =''D16'' or (q.Methodology=''D15'' and q.scope not in (''MAIN CITIES'',''SMALLER CITIES'') AND q.meas_tech =''4G'')
				   or (q.Methodology=''D15''and q.meas_tech <>''4G'')) and q.Scope = ''MAIN HIGHWAYS'' 
				  and q.'+@last_measurement+' = 1 and q.meas_LA=0 and q.Test_type = ''Ping'' 
		 group by q.operator,q.meas_tech,q.entity/*,q.report_type*/,SCOPE
				) lat on (entities.operator= lat.operator and entities.meas_tech=lat.meas_tech and entities.entity=lat.entity)

----------------------------------------------------WEB---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_Att'',
				sum(Failed) as ''Web_Failed'',
				sum(Dropped)as ''Web_Dropped'',
				case when sum (Session_time_Den) >0 then sum(Session_time_Num)/sum (Session_time_Den) end as ''Web_SessionTime_D5'',
				case when sum(WEB_IP_ACCESS_TIME_DEN) >0 then sum(WEB_IP_ACCESS_TIME_NUM)/sum(WEB_IP_ACCESS_TIME_DEN) end as ''WEB_IP_ACCESS_TIME'',
				case when sum(WEB_HTTP_TRANSFER_TIME_DEN)>0 then sum(WEB_HTTP_TRANSFER_TIME_NUM)/sum(WEB_HTTP_TRANSFER_TIME_DEN) end as ''WEB_HTTP_TRANSFER_TIME''
	
			from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''WEB HTTP'' 
			group by q.operator,q.meas_tech,q.entity
				 ) web on (entities.operator= web.operator and entities.meas_tech=web.meas_tech and entities.entity=web.entity)


----------------------------------------------------WEB HTTPS---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_HTTPS_Att'',
				sum(Failed) as ''Web_HTTPS_Failed'',
				sum(Dropped)as ''Web_HTTPS_Dropped'',
				case when sum (Session_time_Den) >0 then sum(Session_time_Num)/sum (Session_time_Den) end as ''Web_SessionTime_HTTPS_D5'',
				case when sum(WEB_IP_ACCESS_TIME_HTTPS_DEN) >0 then 1.00*sum([WEB_IP_ACCESS_TIME_HTTPS_NUM])/sum(WEB_IP_ACCESS_TIME_HTTPS_DEN) end as ''WEB_IP_ACCESS_TIME_HTTPS'',
				case when sum([WEB_TRANSFER_TIME_HTTPS_DEN])>0 then sum([WEB_TRANSFER_TIME_HTTPS_NUM])/sum([WEB_TRANSFER_TIME_HTTPS_DEN]) end as ''WEB_HTTP_TRANSFER_TIME_HTTPS''
				
			from 
				 [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''WEB HTTPS'' 
			group by q.operator,q.meas_tech, q.entity
				) whttps on (entities.operator= whttps.operator and entities.meas_tech=whttps.meas_tech and entities.entity=whttps.entity)

----------------------------------------------------WEB Public---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------	
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Web_Public_Att'',
				sum(Failed) as ''Web_Public_Failed'',
				sum(Dropped)as ''Web_Public_Dropped'',
				case when sum (Session_time_Den) >0 then sum(Session_time_Num)/sum (Session_time_Den) end as ''Web_SessionTime_Public_D5'',
				case when sum([WEB_IP_ACCESS_TIME_PUBLIC_DEN]) >0 then sum(WEB_IP_ACCESS_TIME_PUBLIC_NUM)/sum([WEB_IP_ACCESS_TIME_PUBLIC_DEN]) end as ''WEB_IP_ACCESS_TIME_Public'',
				case when sum([WEB_TRANSFER_TIME_PUBLIC_DEN])>0 then sum(WEB_TRANSFER_TIME_PUBLIC_NUM)/sum([WEB_TRANSFER_TIME_PUBLIC_DEN]) end as ''WEB_HTTP_TRANSFER_TIME_Public''
				
			from 
				 [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''WEB PUBLIC'' 
			group by q.operator,q.meas_tech, q.entity/*,q.report_type*/
				) wpublic on (entities.operator= wpublic.operator and entities.meas_tech=wpublic.meas_tech and entities.entity=wpublic.entity)




----------------------------------------------------YOUTUBE SD---------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------	

	left join 

			(Select q.operator,q.meas_tech,
					q.entity as entity,
					sum(Num_tests) as ''Att_YTB_SD'',
					sum(Failed) as ''YTB_Fails_SD'',
					sum(Dropped)as ''YTB_Dropped_SD'',
					case when sum (Num_tests)>0 then 1.0*sum(Failed)/sum (Num_tests) end as ''YTB_B1_SD'',
					case when sum(Reproductions_WO_Interruptions_Den)>0 then 1.00*sum(Reproductions_WO_Interruptions)/sum(Reproductions_WO_Interruptions_Den) end as ''YTB_B2_SD''
				
				from  [QLIK].dbo._RI_Data_Completed_Qlik q

				where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''Youtube SD'' 
				    
				group by q.operator,q.meas_tech,q.entity/*,q.report_type*/
					 ) ytbsd on (entities.operator= ytbsd.operator and entities.meas_tech=ytbsd.meas_tech and entities.entity=ytbsd.entity)

----------------------------------------------------YOUTUBE HD GLOBAL_EXTRAEMOS EL GLOBAL Y V11 PARA DASHBOARD DE VDF--------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------


	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_YTB_HD'',
				sum(Failed) as ''YTB_Failed_HD'',
				sum(Dropped)as ''YTB_Dropped_HD'',
				case when sum (Num_tests)>0 then 1.0*sum(Failed)/sum (Num_tests) end as ''YTB_B1_HD'',             
				sum(Reproductions_WO_Interruptions) as ''YTB_B2_HD'',
				case when sum(Reproductions_WO_Interruptions_Den)>0 then 1.00*sum(Reproductions_WO_Interruptions)/sum(Reproductions_WO_Interruptions_Den) end as ''YTB_B2_HD_%'',
				Sum([Successful video download]) as ''YTB_B3_HD'',
				case when sum(avg_Video_startTime_Den)>0 then sum(Avg_Video_StarTime_Num)/sum(avg_Video_startTime_Den) end as ''YTB_AVG_START_TIME'',
				case when sum(YTB_video_resolution_den)>0 then cast(round(SUM(YTB_video_resolution_num)/sum(YTB_video_resolution_den),0) as integer) end as ''YTB_B5_HD'',
				SUM(HD_reproduction_rate_num) as ''YTB_B4_HD'',
				case when sum(YTB_video_mos_den)>0 then sum(YTB_video_mos_num)/sum(YTB_video_mos_den) end as ''YTB_B6_HD'',
				sum(q.[ReproduccionesHD]) as ''YTB_STARTED_TERMINATED_HD''

				from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''Youtube HD'' 

			group by q.operator,q.meas_tech,q.entity)
			 ytbhd on (entities.operator= ytbhd.operator and entities.meas_tech=ytbhd.meas_tech and entities.entity=ytbhd.entity)

----------------------------------------------------YOUTUBE HD_V11 PARA DASHBOARD DE VDF-------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
	

	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Num_tests) as ''Att_YTB_HD_vers11'',
				sum(Failed) as ''YTB_Fails_HD_vers11'',
				sum(Dropped)as ''YTB_Dropped_HD_vers11'',
				case when sum (Num_tests)>0 then 1.0*sum(Failed)/sum (Num_tests) end as ''YTB_B1_HD_vers11'',             
				sum(Reproductions_WO_Interruptions) as ''YTB_B2_HD_vers11'',
				case when sum(Reproductions_WO_Interruptions_Den)>0 then 1.00*sum(Reproductions_WO_Interruptions)/sum(Reproductions_WO_Interruptions_Den) end as ''YTB_B2_HD_%_vers11'',
				Sum([Successful video download]) as ''YTB_B3_HD_vers11'',
				case when sum(avg_Video_startTime_Den)>0 then sum(Avg_Video_StarTime_Num)/sum(avg_Video_startTime_Den) end as ''YTB_AVG_START_TIME_vers11'',
				case when sum(YTB_video_resolution_den)>0 then cast(round(SUM(YTB_video_resolution_num)/sum(YTB_video_resolution_den),0) as integer) end as ''YTB_B5_HD_vers11'',
				SUM(HD_reproduction_rate_num) as ''YTB_B4_HD_vers11'',
				case when sum(YTB_video_mos_den)>0 then sum(YTB_video_mos_num)/sum(YTB_video_mos_den) end as ''YTB_B6_HD_vers11'',
				sum(q.[ReproduccionesHD]) as ''YTB_STARTED_TERMINATED_HD_vers11''

				from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''Youtube HD'' '+@filtro_youtube+'

			group by q.operator,q.meas_tech,q.entity)
			 ytbhdv11 on (entities.operator= ytbhdv11.operator and entities.meas_tech=ytbhdv11.meas_tech and entities.entity=ytbhdv11.entity)

----------------------------------------------------YOUTUBE HD_DESGLOSADO POR 4 URLs (METOLODOGÍA FY1718)-------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
	left join 

		(Select q.operator,q.meas_tech,
				q.entity as entity,
				sum(Reproducciones_Video1) as ''Att_YTB_HD_Video1'',
				sum(Fails_Video1) as ''YTB_Fails_HD_Video1'',
				case when sum (Reproducciones_Video1) >0 then 1.0*sum(Fails_Video1)/sum (Reproducciones_Video1) end as ''YTB_B1_HD_Video1'',            
				sum(Reproductions_WO_Interruptions_Video1) as ''YTB_B2_HD_Video1'',
				case when sum(Reproductions_WO_Interruptions_Den_Video1)>0 then 1.00*sum(Reproductions_WO_Interruptions_Video1)/sum(Reproductions_WO_Interruptions_Den_Video1) end as ''YTB_B2_HD_%_Video1'',
				Sum([Successful video download_Video1]) as ''YTB_B3_HD_Video1'',
				case when sum(avg_Video_startTime_Den_Video1)>0 then sum(Avg_Video_StarTime_Num_Video1)/sum(avg_Video_startTime_Den_Video1) end as ''YTB_AVG_START_TIME_Video1'',
				case when sum(YTB_video_resolution_den_Video1)>0 then cast(round(SUM(YTB_video_resolution_num_Video1)/sum(YTB_video_resolution_den_Video1),0) as integer) end as ''YTB_B5_HD_Video1'',
				SUM(HD_reproduction_rate_num_Video1) as ''YTB_B4_HD_Video1'',
				case when sum(YTB_video_mos_den_Video1)>0 then sum(YTB_video_mos_num_Video1)/sum(YTB_video_mos_den_Video1) end as ''YTB_B6_HD_Video1'',
				sum(q.[ReproduccionesHD_Video1]) as ''YTB_STARTED_TERMINATED_HD_Video1'',

				sum(Reproducciones_Video2) as ''Att_YTB_HD_Video2'',
				sum(Fails_Video2) as ''YTB_Fails_HD_Video2'',
				case when sum (Reproducciones_Video2) >0 then 1.0*sum(Fails_Video2)/sum (Reproducciones_Video2) end as ''YTB_B1_HD_Video2'',            
				sum(Reproductions_WO_Interruptions_Video2) as ''YTB_B2_HD_Video2'',
				case when sum(Reproductions_WO_Interruptions_Den_Video2)>0 then 1.00*sum(Reproductions_WO_Interruptions_Video2)/sum(Reproductions_WO_Interruptions_Den_Video2) end as ''YTB_B2_HD_%_Video2'',
				Sum([Successful video download_Video2]) as ''YTB_B3_HD_Video2'',
				case when sum(avg_Video_startTime_Den_Video2)>0 then sum(Avg_Video_StarTime_Num_Video2)/sum(avg_Video_startTime_Den_Video2) end as ''YTB_AVG_START_TIME_Video2'',
				case when sum(YTB_video_resolution_den_Video2)>0 then cast(round(SUM(YTB_video_resolution_num_Video2)/sum(YTB_video_resolution_den_Video2),0) as integer) end as ''YTB_B5_HD_Video2'',
				SUM(HD_reproduction_rate_num_Video2) as ''YTB_B4_HD_Video2'',
				case when sum(YTB_video_mos_den_Video2)>0 then sum(YTB_video_mos_num_Video2)/sum(YTB_video_mos_den_Video2) end as ''YTB_B6_HD_Video2'',
				sum(q.[ReproduccionesHD_Video2]) as ''YTB_STARTED_TERMINATED_HD_Video2'',

				sum(Reproducciones_Video3) as ''Att_YTB_HD_Video3'',
				sum(Fails_Video3) as ''YTB_Fails_HD_Video3'',
				case when sum (Reproducciones_Video3) >0 then 1.0*sum(Fails_Video3)/sum (Reproducciones_Video3) end as ''YTB_B1_HD_Video3'',            
				sum(Reproductions_WO_Interruptions_Video3) as ''YTB_B2_HD_Video3'',
				case when sum(Reproductions_WO_Interruptions_Den_Video3)>0 then 1.00*sum(Reproductions_WO_Interruptions_Video3)/sum(Reproductions_WO_Interruptions_Den_Video3) end as ''YTB_B2_HD_%_Video3'',
				Sum([Successful video download_Video3]) as ''YTB_B3_HD_Video3'',
				case when sum(avg_Video_startTime_Den_Video3)>0 then sum(Avg_Video_StarTime_Num_Video3)/sum(avg_Video_startTime_Den_Video3) end as ''YTB_AVG_START_TIME_Video3'',
				case when sum(YTB_video_resolution_den_Video3)>0 then cast(round(SUM(YTB_video_resolution_num_Video3)/sum(YTB_video_resolution_den_Video3),0) as integer) end as ''YTB_B5_HD_Video3'',
				SUM(HD_reproduction_rate_num_Video3) as ''YTB_B4_HD_Video3'',
				case when sum(YTB_video_mos_den_Video3)>0 then sum(YTB_video_mos_num_Video3)/sum(YTB_video_mos_den_Video3) end as ''YTB_B6_HD_Video3'',
				sum(q.[ReproduccionesHD_Video3]) as ''YTB_STARTED_TERMINATED_HD_Video3'',

				sum(Reproducciones_Video4) as ''Att_YTB_HD_Video4'',
				sum(Fails_Video4) as ''YTB_Fails_HD_Video4'',
				case when sum (Reproducciones_Video4) >0 then 1.0*sum(Fails_Video4)/sum (Reproducciones_Video4) end as ''YTB_B1_HD_Video4'',            
				sum(Reproductions_WO_Interruptions_Video4) as ''YTB_B2_HD_Video4'',
				case when sum(Reproductions_WO_Interruptions_Den_Video4)>0 then 1.00*sum(Reproductions_WO_Interruptions_Video4)/sum(Reproductions_WO_Interruptions_Den_Video4) end as ''YTB_B2_HD_%_Video4'',
				Sum([Successful video download_Video4]) as ''YTB_B3_HD_Video4'',
				case when sum(avg_Video_startTime_Den_Video4)>0 then sum(Avg_Video_StarTime_Num_Video4)/sum(avg_Video_startTime_Den_Video4) end as ''YTB_AVG_START_TIME_Video4'',
				case when sum(YTB_video_resolution_den_Video4)>0 then cast(round(SUM(YTB_video_resolution_num_Video4)/sum(YTB_video_resolution_den_Video4),0) as integer) end as ''YTB_B5_HD_Video4'',
				SUM(HD_reproduction_rate_num_Video4) as ''YTB_B4_HD_Video4'',
				case when sum(YTB_video_mos_den_Video4)>0 then sum(YTB_video_mos_num_Video4)/sum(YTB_video_mos_den_Video4) end as ''YTB_B6_HD_Video4'',
				sum(q.[ReproduccionesHD_Video4]) as ''YTB_STARTED_TERMINATED_HD_Video4''

			from [QLIK].dbo._RI_Data_Completed_Qlik q

			where q.meas_Tech like ''%Road 4G%'' and q.Scope = ''MAIN HIGHWAYS'' and q.'+@last_measurement+' =1 and q.meas_LA=0 and q.Test_type = ''Youtube HD''

			group by q.operator,q.meas_tech,q.entity
			) ytbhdv on (entities.operator= ytbhdv.operator and entities.meas_tech=ytbhdv.meas_tech and entities.entity=ytbhdv.entity)


where entities.meas_tech like ''%Road 4G%'' and entities.Scope_QLIK = ''MAIN HIGHWAYS'' 

group by entities.SCOPE,entities.meas_tech,entities.Scope_QLIK,entities.entity,entities.entities_dashboard,dl_ce.Att_DL_CE,dl_ce.Fails_Acc_DL_CE,dl_ce.Fails_Ret_DL_CE,
	dl_ce.D1,dl_ce.D2,dl_ce.Num_Thput_3M,dl_ce.Num_Thput_1M,dl_ce.Peak_Data_DL_CE,dl_ce.SessionTime_DL_CE,dl_ce.final_date,ul_ce.Att_UL_CE,ul_ce.Fails_Acc_UL_CE,ul_ce.Fails_Ret_UL_CE,
	ul_ce.D3,ul_ce.Peak_Data_UL_CE,ul_ce.SessionTime_UL_CE,dl_nc.Att_DL_NC,dl_nc.Fails_Acc_DL_NC,dl_nc.Fails_Ret_DL_NC,dl_nc.Sessions_Thput_384K_DL_NC,
	dl_nc.[MEAN_DATA_USER_RATE_DL_NC],dl_nc.Peak_Data_DL_NC,ul_nc.Att_UL_NC,ul_nc.Fails_Acc_UL_NC,ul_nc.Fails_Ret_UL_NC,ul_nc.Sessions_Thput_384K_UL_NC,
	ul_nc.[MEAN_DATA_USER_RATE_UL_NC],ul_nc.Peak_Data_UL_NC,lat.Latency_Att,lat.LAT_AVG,web.Web_Att,web.Web_Failed,web.Web_Dropped,web.Web_SessionTime_D5,
	web.WEB_IP_ACCESS_TIME,web.WEB_HTTP_TRANSFER_TIME,whttps.Web_HTTPS_Att,whttps.Web_HTTPS_Failed,whttps.Web_HTTPS_Dropped,whttps.Web_SessionTime_HTTPS_D5,whttps.WEB_IP_ACCESS_TIME_HTTPS,
	whttps.WEB_HTTP_TRANSFER_TIME_HTTPS,wpublic.Web_Public_Att,wpublic.Web_Public_Failed,wpublic.Web_Public_Dropped,wpublic.Web_SessionTime_Public_D5,wpublic.WEB_IP_ACCESS_TIME_Public,
	wpublic.WEB_HTTP_TRANSFER_TIME_Public,ytbsd.Att_YTB_SD,ytbsd.YTB_Fails_SD,ytbsd.YTB_Dropped_SD,ytbsd.YTB_B1_SD,ytbsd.YTB_B2_SD,ytbhd.Att_YTB_HD,ytbhd.YTB_Failed_HD,
	ytbhd.YTB_Dropped_HD,ytbhd.YTB_B1_HD,ytbhd.YTB_AVG_START_TIME,ytbhd.YTB_B2_HD,ytbhd.[YTB_B2_HD_%],ytbhd.YTB_B3_HD,ytbhd.YTB_B5_HD,ytbhd.YTB_B4_HD,ytbhd.YTB_B6_HD,
	ytbhd.YTB_STARTED_TERMINATED_HD,ytbhdv11.Att_YTB_HD_vers11,ytbhdv11.YTB_Fails_HD_vers11,ytbhdv11.YTB_Dropped_HD_vers11,ytbhdv11.YTB_B1_HD_vers11,ytbhdv11.YTB_AVG_START_TIME_vers11,ytbhdv11.YTB_B2_HD_vers11,ytbhdv11.[YTB_B2_HD_%_vers11],ytbhdv11.YTB_B3_HD_vers11,ytbhdv11.YTB_B5_HD_vers11,ytbhdv11.YTB_B4_HD_vers11,ytbhdv11.YTB_B6_HD_vers11,
	ytbhdv11.YTB_STARTED_TERMINATED_HD_vers11,ytbhdv.Att_YTB_HD_Video1,ytbhdv.YTB_Fails_HD_Video1,ytbhdv.YTB_B1_HD_Video1,ytbhdv.YTB_AVG_START_TIME_Video1,                                            
	ytbhdv.YTB_B2_HD_Video1,ytbhdv.[YTB_B2_HD_%_Video1],ytbhdv.YTB_B3_HD_Video1,ytbhdv.YTB_B5_HD_Video1,ytbhdv.YTB_B4_HD_Video1,ytbhdv.YTB_B6_HD_Video1,ytbhdv.YTB_STARTED_TERMINATED_HD_Video1,
	ytbhdv.Att_YTB_HD_Video2,ytbhdv.YTB_Fails_HD_Video2,ytbhdv.YTB_B1_HD_Video2,ytbhdv.YTB_AVG_START_TIME_Video2,ytbhdv.YTB_B2_HD_Video2,ytbhdv.[YTB_B2_HD_%_Video2],
	ytbhdv.YTB_B3_HD_Video2,ytbhdv.YTB_B5_HD_Video2,ytbhdv.YTB_B4_HD_Video2,ytbhdv.YTB_B6_HD_Video2,ytbhdv.YTB_STARTED_TERMINATED_HD_Video2,ytbhdv.Att_YTB_HD_Video3,ytbhdv.YTB_Fails_HD_Video3,
	ytbhdv.YTB_B1_HD_Video3,ytbhdv.YTB_AVG_START_TIME_Video3,ytbhdv.YTB_B2_HD_Video3,ytbhdv.[YTB_B2_HD_%_Video3],ytbhdv.YTB_B3_HD_Video3,ytbhdv.YTB_B5_HD_Video3,
	ytbhdv.YTB_B4_HD_Video3,ytbhdv.YTB_B6_HD_Video3,ytbhdv.YTB_STARTED_TERMINATED_HD_Video3,ytbhdv.Att_YTB_HD_Video4,ytbhdv.YTB_Fails_HD_Video4,
	ytbhdv.YTB_B1_HD_Video4,ytbhdv.YTB_AVG_START_TIME_Video4,ytbhdv.YTB_B2_HD_Video4,ytbhdv.[YTB_B2_HD_%_Video4],ytbhdv.YTB_B3_HD_Video4,ytbhdv.YTB_B5_HD_Video4,ytbhdv.YTB_B4_HD_Video4,
	ytbhdv.YTB_B6_HD_Video4,ytbhdv.YTB_STARTED_TERMINATED_HD_Video4,entities.population,entities.SMARTPHONE_MODEL,entities.FIRMWARE_VERSION,entities.HANDSET_CAPABILITY,entities.TEST_MODALITY,
	entities.OPCOS,entities.operator,entities.RAN_VENDOR,entities.SCENARIO,entities.Provincia_comp,entities.SCOPE_DASH,entities.CCAA_comp,entities.Zona_OSP,entities.Zona_VDF
	--,v.ORDER_DASHBOARD,entities.report_type,entities.CCAA_comp,,entities.Provincia_comp,convert(varchar,right(q.mnc,1))
	,entities.MCC
')

--select * from _Percentiles_Data where entidad = 'barcelona' and mnc = 01 and meas_tech = '4g'

print('5.Añadimos la información de percentiles') -------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------


exec('
insert into [dbo].[_Actualizacion_QLIK_DASH]
select ''Fin 2.2 Inicio Percentiles ''''' + @id+ ''''' Datos'', getdate()

exec [AddedValue].[dbo].[plcc_data_statistics_new] '+@last_measurement+'
exec [AddedValue].[dbo].[plcc_data_statistics_Columns_new] '''+@monthYear+''' ,'''+@ReportWeek+'''

insert into [dbo].[_Actualizacion_QLIK_DASH]
select ''Fin 2.3 Percentiles Ejecutados'', getdate()')



exec(' 
	Select q.*,[Percentil10_DL_CE]*1000 as Percentil10_DL_CE,[Percentil90_DL_CE]*1000 as Percentil90_DL_CE,[Percentil10_UL_CE]*1000 as Percentil10_UL_CE,[Percentil90_UL_CE]*1000 as Percentil90_UL_CE,[Percentil10_DL_NC]*1000 as Percentil10_DL_NC,
	[Percentil90_DL_NC]*1000 as Percentil90_DL_NC,[Percentil10_UL_NC]*1000 as Percentil10_UL_NC,[Percentil90_UL_NC]*1000 as Percentil90_UL_NC,round([Percentil_PING],0) as PercentilPING,[Percentil10_DL_CE_SCOPE]*1000 as Percentil10_DL_CE_SCOPE,[Percentil90_DL_CE_SCOPE]*1000 as Percentil90_DL_CE_SCOPE,
	[Percentil10_UL_CE_SCOPE]*1000 as Percentil10_UL_CE_SCOPE,[Percentil90_UL_CE_SCOPE]*1000 as Percentil90_UL_CE_SCOPE,[Percentil10_DL_NC_SCOPE]*1000 as Percentil10_DL_NC_SCOPE,[Percentil90_DL_NC_SCOPE]*1000 as Percentil90_DL_NC_SCOPE,
	[Percentil10_UL_NC_SCOPE]*1000 as Percentil10_UL_NC_SCOPE,[Percentil90_UL_NC_SCOPE]*1000 as Percentil90_UL_NC_SCOPE,round([Percentil_PING_SCOPE],0) as Percentil_PING_SCOPE,[Percentil10_DL_CE_SCOPE_QLIK]*1000 as Percentil10_DL_CE_SCOPE_QLIK,[Percentil90_DL_CE_SCOPE_QLIK]*1000 as Percentil90_DL_CE_SCOPE_QLIK,
	[Percentil10_UL_CE_SCOPE_QLIK]*1000 as Percentil10_UL_CE_SCOPE_QLIK,[Percentil90_UL_CE_SCOPE_QLIK]*1000 as Percentil90_UL_CE_SCOPE_QLIK,[Percentil10_DL_NC_SCOPE_QLIK]*1000 as Percentil10_DL_NC_SCOPE_QLIK,[Percentil90_DL_NC_SCOPE_QLIK]*1000 as Percentil90_DL_NC_SCOPE_QLIK,[Percentil10_UL_NC_SCOPE_QLIK]*1000 as Percentil10_UL_NC_SCOPE_QLIK,
	[Percentil90_UL_NC_SCOPE_QLIK]*1000 as Percentil90_UL_NC_SCOPE_QLIK,round([Percentil_PING_SCOPE_QLIK],0) as Percentil_PING_SCOPE_QLIK,
	[Desviacion_DL_CE]*1000 as Desviacion_DL_CE,[Desviacion_DL_NC]*1000 as Desviacion_DL_NC,[Desviacion_UL_CE]*1000 as Desviacion_UL_CE,[Desviacion_UL_NC]*1000 as Desviacion_UL_NC,[Desviacion_DL_CE_SCOPE]*1000 as Desviacion_DL_CE_SCOPE,[Desviacion_DL_NC_SCOPE]*1000 as Desviacion_DL_NC_SCOPE,
	[Desviacion_UL_CE_SCOPE]*1000 as Desviacion_UL_CE_SCOPE,[Desviacion_UL_NC_SCOPE]*1000 as Desviacion_UL_NC_SCOPE,[Desviacion_DL_CE_SCOPE_QLIK]*1000 as Desviacion_DL_CE_SCOPE_QLIK,[Desviacion_DL_NC_SCOPE_QLIK]*1000 as Desviacion_DL_NC_SCOPE_QLIK,
	[Desviacion_UL_CE_SCOPE_QLIK]*1000 as Desviacion_UL_CE_SCOPE_QLIK,[Desviacion_UL_NC_SCOPE_QLIK]*1000 as Desviacion_UL_NC_SCOPE_QLIK
into lcc_Data_final
from _All_Data q 
		        left join _Percentiles_Data p on (q.entidad=p.entidad and q.operador = case when p.mnc=01 then ''Vodafone'' when p.mnc=03 then ''Orange'' when p.mnc=07 then ''Movistar'' when p.mnc=04 then ''Yoigo'' end
											 and q.id= Case when p.Report_QLIK=''MUN'' then ''OSP'' else p.Report_QLIK end and q.technology=p.meas_tech
											 and q.monthyear = p.monthyear and q.ReportWeek=p.ReportWeek)
				left join _Desviaciones_Data r on (q.entidad=r.entidad and q.operador = case when r.mnc=01 then ''Vodafone'' when r.mnc=03 then ''Orange'' when r.mnc=07 then ''Movistar'' when r.mnc=04 then ''Yoigo'' end
											 and q.id= Case when r.Report_QLIK=''MUN'' then ''OSP'' else r.Report_QLIK end and q.technology=r.meas_tech 
											 and q.monthyear = r.monthyear and q.ReportWeek=r.ReportWeek)
where q.monthyear = '''+@monthYear+''' and q.ReportWeek = '''+@ReportWeek+'''

')

--select * from _Percentiles_Data where meas_tech = '4g'
-----------------------------------------------------------------------------------------------------------------------
print('6. Contruimos la tabla especifica para QLIK o para el DASHBOARD en funcion de la entrada') ------------------------------
-----------------------------------------------------------------------------------------------------------------------


declare @tabla_youtube as varchar(4000)


--Declaramos la variable en la que introducimos el primer video de youtube. 
--En metología FY1617:Si el dashboard es VDF veremos solo la versión 11 o superior de Youtube. Si es OSP veremos todo el Youtube
--En metología FY1717:En las mismas columnas veremos los KPIs del Video1 (en las sucesivas columnas veremos Video2/3/4)
--Cambiar!! en caso de que queramos sacar en columnas diferentes el desglose por videos y el acumulado

 if @id='VDF'
	begin

		set @tabla_youtube='case when p.Att_YTB_HD_Video1 is null then p.YTB_B5_HD_vers11 else p.YTB_B5_HD_Video1 end as [YTB B5],
				   case when p.Att_YTB_HD_Video1 is null then p.YTB_B4_HD_vers11 else p.YTB_B4_HD_Video1 end as [YTB B4],
				   case when p.Att_YTB_HD_Video1 is null then p.YTB_B6_HD_vers11 else p.YTB_B6_HD_Video1 end as [YTB B6],
				   case when p.Att_YTB_HD_Video1 is null then p.Att_YTB_HD_vers11 else p.Att_YTB_HD_Video1 end as [YTB NUMBER OF VIDEO ACCESS ATTEMPTS],
				   case when p.Att_YTB_HD_Video1 is null then P.YTB_AVG_START_TIME_vers11 else P.YTB_AVG_START_TIME_Video1 end AS [YTB VIDEO START TIME],
				   case when p.Att_YTB_HD_Video1 is null then P.YTB_Fails_HD_vers11 else P.YTB_Fails_HD_Video1 end as [YTB NUMBER OF VIDEO FAILURES],
				   case when p.Att_YTB_HD_Video1 is null then 1-p.YTB_B1_HD_vers11 else 1-p.YTB_B1_HD_Video1 end as [YTB B1],
				   case when p.Att_YTB_HD_Video1 is null then p.YTB_B2_HD_vers11 else p.YTB_B2_HD_Video1 end as [YTB B2],
				   case when p.Att_YTB_HD_Video1 is null then p.YTB_STARTED_TERMINATED_HD_vers11 else p.YTB_STARTED_TERMINATED_HD_Video1 end as [YTB VIDEOS START_TERM IN HD],
				   case when p.Att_YTB_HD_Video1 is null then p.[YTB_B2_HD_%_vers11] else p.[YTB_B2_HD_%_Video1] end as [YTB B2 %],
				   case when p.Att_YTB_HD_Video1 is null then p.YTB_B3_HD_vers11 else p.YTB_B3_HD_Video1 end as [YTB B3]'
	
		--set @tabla_youtube='sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_B5_HD_vers11 else p.YTB_B5_HD_Video1 end) as [YTB B5],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_B4_HD_vers11 else p.YTB_B4_HD_Video1 end) as [YTB B4],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_B6_HD_vers11 else p.YTB_B6_HD_Video1 end) as [YTB B6],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.Att_YTB_HD_vers11 else p.Att_YTB_HD_Video1 end) as [YTB NUMBER OF VIDEO ACCESS ATTEMPTS],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then P.YTB_AVG_START_TIME_vers11 else P.YTB_AVG_START_TIME_Video1 end) AS [YTB VIDEO START TIME],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then P.YTB_Fails_HD_vers11 else P.YTB_Fails_HD_Video1 end) as [YTB NUMBER OF VIDEO FAILURES],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then 1-p.YTB_B1_HD_vers11 else 1-p.YTB_B1_HD_Video1 end) as [YTB B1],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_B2_HD_vers11 else p.YTB_B2_HD_Video1 end) as [YTB B2],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_STARTED_TERMINATED_HD_vers11 else p.YTB_STARTED_TERMINATED_HD_Video1 end) as [YTB VIDEOS START_TERM IN HD],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.[YTB_B2_HD_%_vers11] else p.[YTB_B2_HD_%_Video1] end) as [YTB B2 %],
		--		   sum(case when (isnull(p.Att_YTB_HD_Video1,0)+isnull(p.Att_YTB_HD_Video2,0)+isnull(p.Att_YTB_HD_Video3,0)+isnull(p.Att_YTB_HD_Video4,0)) =0 then p.YTB_B3_HD_vers11 else p.YTB_B3_HD_Video1 end) as [YTB B3]'
	
	end
else
	begin

	-- Para OSP no sacamos los 4 vídeos.

		set @tabla_youtube='p.YTB_B5_HD as [YTB B5],
				   p.YTB_B4_HD as [YTB B4],
				   p.YTB_B6_HD as [YTB B6],
				   p.Att_YTB_HD as [YTB NUMBER OF VIDEO ACCESS ATTEMPTS],
				   P.YTB_AVG_START_TIME as [YTB VIDEO START TIME],
				   P.YTB_Fails_HD as [YTB NUMBER OF VIDEO FAILURES],
				   1-p.YTB_B1_HD as [YTB B1],
				   p.YTB_B2_HD as [YTB B2],
				   p.YTB_STARTED_TERMINATED_HD as [YTB VIDEOS START_TERM IN HD],
				   p.[YTB_B2_HD_%] as [YTB B2 %],
				   p.YTB_B3_HD as [YTB B3]'
	
	-- Como ya hemos sacado todo el Youtube en las primeras columnas el resto lo ponemos a Null

		update lcc_Data_final
		set 
		YTB_B5_HD_Video2 =null,		YTB_B4_HD_Video2=null,		YTB_B6_HD_Video2=null,		Att_YTB_HD_Video2=null,		YTB_AVG_START_TIME_Video2=null,		YTB_Fails_HD_Video2=null,		YTB_B1_HD_Video2=null,		YTB_B2_HD_Video2=null,		YTB_STARTED_TERMINATED_HD_Video2=null,		[YTB_B2_HD_%_Video2]=null,  YTB_B3_HD_Video2=null,
		YTB_B5_HD_Video3 =null,		YTB_B4_HD_Video3=null,		YTB_B6_HD_Video3=null,		Att_YTB_HD_Video3=null,		YTB_AVG_START_TIME_Video3=null,		YTB_Fails_HD_Video3=null,		YTB_B1_HD_Video3=null,		YTB_B2_HD_Video3=null,		YTB_STARTED_TERMINATED_HD_Video3=null,		[YTB_B2_HD_%_Video3]=null,  YTB_B3_HD_Video3=null,
		YTB_B5_HD_Video4 =null,		YTB_B4_HD_Video4=null,		YTB_B6_HD_Video4=null,		Att_YTB_HD_Video4=null,		YTB_AVG_START_TIME_Video4=null,		YTB_Fails_HD_Video4=null,		YTB_B1_HD_Video4=null,		YTB_B2_HD_Video4=null,		YTB_STARTED_TERMINATED_HD_Video4=null,		[YTB_B2_HD_%_Video4]=null,  YTB_B3_HD_Video4=null
		
		from lcc_Data_final

	end

exec('
exec AddedValue.dbo.sp_lcc_dropifexists ''lcc_km2_chequeo_mallado''
exec sp_lcc_km2_medidos ''4G'','''+@id+'''
exec sp_lcc_km2_medidos ''3G'','''+@id+'''')

if @id='OSP'
begin
	exec('
	exec sp_lcc_km2_medidos ''4G'',''VDF''
	exec sp_lcc_km2_medidos ''3G'',''VDF''')

	set @selectKM='case when kmMUN.[AreaTotal(km2)] is not null then kmMUN.[AreaTotal(km2)] else kmVDF.[AreaTotal(km2)] end as URBAN_EXTENSION,
		p.[Population],
		case when kmMUN.Porcentaje_medido is not null then convert(float,kmMUN.Porcentaje_medido)/100 else convert(float,kmVDF.Porcentaje_medido)/100 end as SAMPLED_URBAN,
		case when kmMUN.[AreaTotal(km2)] is not null then convert(float,p.att_dl_ce)/convert(float,kmMUN.[AreaTotal(km2)])/(convert(float,kmMUN.Porcentaje_medido)/100) else convert(float,p.att_dl_ce)/convert(float,kmVDF.[AreaTotal(km2)])/(convert(float,kmVDF.Porcentaje_medido)/100) end as NUMBER_TEST_KM,'
	set @cruceKM ='left join lcc_km2_chequeo_mallado kmMUN
		on (p.entidad=kmMUN.entidad
			and p.technology=kmMUN.tech and p.LAST_ACQUISITION=''20'' + kmMUN.date_reporting and kmMUN.Report_Type =''MUN'')
	left join lcc_km2_chequeo_mallado kmVDF
		on (p.entidad=kmVDF.entidad
			and p.technology=kmVDF.tech and p.LAST_ACQUISITION=''20'' + kmVDF.date_reporting and kmVDF.Report_Type =''VDF'')'
	set @cruceKM_4GOnly ='left join lcc_km2_chequeo_mallado kmMUN
		on (p.entidad=kmMUN.entidad
			and replace(p.technology,''4GOnly'',''4G'')=kmMUN.tech and p.LAST_ACQUISITION=''20'' + kmMUN.date_reporting and kmMUN.Report_Type =''MUN'')
	left join lcc_km2_chequeo_mallado kmVDF
		on (p.entidad=kmVDF.entidad
			and replace(p.technology,''4GOnly'',''4G'')=kmVDF.tech and p.LAST_ACQUISITION=''20'' + kmVDF.date_reporting and kmVDF.Report_Type =''VDF'')'
	set @cruceKM_CAOnly ='left join lcc_km2_chequeo_mallado kmMUN
		on (p.entidad=kmMUN.entidad
			and replace(p.technology,''4G_CA_Only'',''4G'')=kmMUN.tech and p.LAST_ACQUISITION=''20'' + kmMUN.date_reporting and kmMUN.Report_Type =''MUN'')
	left join lcc_km2_chequeo_mallado kmVDF
		on (p.entidad=kmVDF.entidad
			and replace(p.technology,''4G_CA_Only'',''4G'')=kmVDF.tech and p.LAST_ACQUISITION=''20'' + kmVDF.date_reporting and kmVDF.Report_Type =''VDF'')'
end
else
begin 
	set @selectKM='km.[AreaTotal(km2)] as URBAN_EXTENSION,
		p.[Population],
		convert(float,km.Porcentaje_medido)/100 as SAMPLED_URBAN,
		convert(float,p.att_dl_ce)/convert(float,km.[AreaTotal(km2)])/(convert(float,km.Porcentaje_medido)/100) as NUMBER_TEST_KM,'
	set @cruceKM ='left join lcc_km2_chequeo_mallado km
		on (p.entidad=km.entidad
			and p.technology=km.tech and p.LAST_ACQUISITION=''20'' + km.date_reporting)'
	set @cruceKM_4GOnly ='left join lcc_km2_chequeo_mallado km
		on (p.entidad=km.entidad
			and replace(p.technology,''4GOnly'',''4G'')=km.tech and p.LAST_ACQUISITION=''20'' + km.date_reporting)'
	set @cruceKM_CAOnly ='left join lcc_km2_chequeo_mallado km
		on (p.entidad=km.entidad
			and replace(p.technology,''4G_CA_Only'',''4G'')=km.tech and p.LAST_ACQUISITION=''20'' + km.date_reporting)'
end


-- Rellenamos la tabla del Dashboard
------------------------------------

print('Rellenamos la tabla del Dashboard')

exec('
	insert into DASHBOARD.dbo.lcc_data_final_dashboard
	select *
	from (
	select

		p.scope as SCOPE,
		case when p.technology like ''%Road 4G%'' then ''4G'' else p.technology end as TECHNOLOGY,
		case when p.technology like ''%4G%'' then ''Y'' else ''N'' end as CA_Y_N,
		p.SCOPE_DASH as [TARGET ON SCOPE],
		p.ENTITIES_DASHBOARD as [CITIES_ROUTE_LINES_PLACE],

		p.att_dl_ce as [DL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_ce as [DL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_ce as [DL_CE ERRORS IN RETAINABILITY],
		p.D1 as [DL_CE D1.DOWNLOAD SPEED],
		p.Desviacion_DL_CE as [DL_CE DESV],
		p.D2 as [DL_CE D2],
		p.Num_Thput_3M as [DL_CE NUMBER OF DL > 3 MBPS],
		p.Num_Thput_1M as [DL_CE NUMBER OF DL > 1 MBPS],
		p.Peak_Data_DL_CE as [DL_CE PEAK DATA USER RATE],
		p.Percentil10_DL_CE as [DL_CE 10TH PERCENTILE THR.],
		p.Percentil10_DL_CE_SCOPE as [DL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_CE_SCOPE_QLIK else null end as [DL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_CE as [DL_CE 90TH PERCENTILE THR.],
		p.Percentil90_DL_CE_SCOPE as [DL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_CE_SCOPE_QLIK else null end as [DL_CE 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_ce as [UL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_ce as [UL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_ce as [UL_CE ERRORS IN RETAINABILITY],
		p.D3 as [UL_CE D3.UPLOAD SPEED],
		p.Desviacion_UL_CE as [UL_CE THROUGHPUT DESV],
		p.Peak_Data_UL_CE as [UL_CE PEAK DATA USER RATE],
		p.Percentil10_UL_CE as [UL_CE 10TH PERCENTILE THR.],
		p.Percentil10_UL_CE_SCOPE as [UL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_CE_SCOPE_QLIK else null end as [UL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_CE as [UL_CE 90TH PERCENTILE THR.],
		p.Percentil90_UL_CE_SCOPE as [UL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_CE_SCOPE_QLIK else null end as [UL_CE 90TH PERCENTILE SCOPE_M_S],

		
		p.att_dl_nc as [DL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_nc as [DL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_nc as [DL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_DL_NC as [DL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_DL_NC as [DL_NC MEAN DATA USER RATE],
		p.Desviacion_DL_NC as [DL_NC DESV],
		p.Peak_Data_DL_NC as [DL_NC PEAK DATA USER RATE],
		p.Percentil10_DL_NC as [DL_NC 10TH PERCENTILE THR.],
		p.Percentil10_DL_NC_SCOPE as [DL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_NC_SCOPE_QLIK else null end as [DL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_NC as [DL_NC 90TH PERCENTILE THR.],
		p.Percentil90_DL_NC_SCOPE as [DL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_NC_SCOPE_QLIK else null end as [DL_NC 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_nc as [UL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_nc as [UL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_nc as [UL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_UL_NC as [UL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_UL_NC as [UL_NC MEAN DATA USER RATE],
		p.Desviacion_UL_NC as [UL_NC DESV],
		p.Peak_Data_UL_NC as [UL_NC PEAK DATA USER RATE],
		p.Percentil10_UL_NC as [UL_NC 10TH PERCENTILE THR.],
		p.Percentil10_UL_NC_SCOPE as [UL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_NC_SCOPE_QLIK else null end as [UL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_NC as [UL_NC 90TH PERCENTILE THR.],
		p.Percentil90_UL_NC_SCOPE as [UL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_NC_SCOPE_QLIK else null end as [UL_NC 90TH PERCENTILE SCOPE_M_S],

		p.Latency_Att as [PING NUMBER OF ATTEMPTS],
		p.PercentilPING as [PING MEDIAN],
		p.LAT_AVG as [PING AVG],
		p.Percentil_PING_SCOPE as [PING MEDIAN SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil_PING_SCOPE_QLIK else null end as [PING MEDIAN SCOPE_M_S],

		p.Web_Att as [WEB_HTTP ATTEMPTS],
		p.Web_Failed as [WEB_HTTP ACCESIBILITY],
		p.Web_Dropped as [WEB_HTTP RETAINABILITY],
		p.Web_SessionTime_D5 as [WEB_HTTP SESS],
		p.WEB_IP_ACCESS_TIME as [WEB_HTTP IP ACC],
		p.WEB_HTTP_TRANSFER_TIME as [WEB_HTTP TRANS],
		
		p.Web_https_Att as [WEB_HTTPS ATTEMPTS],
		p.Web_https_Failed as [WEB_HTTPS ACCESIBILITY],
		p.Web_https_Dropped as [WEB_HTTPS RETAINABILITY],
		p.[Web_SessionTime_HTTPS_D5] as [WEB_HTTPS SESS],
		p.WEB_IP_ACCESS_TIME_https as [WEB_HTTPS IP ACC],
		p.[WEB_HTTP_TRANSFER_TIME_HTTPS] as [WEB_HTTPS TRANS],
		
		'+@tabla_youtube+',
		
		p.YTB_B5_HD_Video2 as [YTB_V2 B5],
		p.YTB_B4_HD_Video2 as [YTB_V2 B4],
		p.YTB_B6_HD_Video2 as [YTB_V2 B6],
		p.Att_YTB_HD_Video2 as [YTB_V2 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video2 AS [YTB_V2 VIDEO START TIME],
		P.YTB_Fails_HD_Video2 as [YTB_V2 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video2 as [YTB_V2 B1],
		p.YTB_B2_HD_Video2 as [YTB_V2 B2],
		p.YTB_STARTED_TERMINATED_HD_Video2 as [YTB_V2 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video2] as [YTB_V2 B2 %],
		p.YTB_B3_HD_Video2 as [YTB_V2 B3],

		p.YTB_B5_HD_Video3 as [YTB_V3 B5],
		p.YTB_B4_HD_Video3 as [YTB_V3 B4],
		p.YTB_B6_HD_Video3 as [YTB_V3 B6],
		p.Att_YTB_HD_Video3 as [YTB_V3 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video3 AS [YTB_V3 VIDEO START TIME],
		P.YTB_Fails_HD_Video3 as [YTB_V3 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video3 as [YTB_V3 B1],
		p.YTB_B2_HD_Video3 as [YTB_V3 B2],
		p.YTB_STARTED_TERMINATED_HD_Video3 as [YTB_V3 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video3] as [YTB_V3 B2 %],
		p.YTB_B3_HD_Video3 as [YTB_V3 B3],

		p.YTB_B5_HD_Video4 as [YTB_V4 B5],
		p.YTB_B4_HD_Video4 as [YTB_V4 B4],
		p.YTB_B6_HD_Video4 as [YTB_V4 B6],
		p.Att_YTB_HD_Video4 as [YTB_V4 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video4 AS [YTB_V4 VIDEO START TIME],
		P.YTB_Fails_HD_Video4 as [YTB_V4 NUMBER OF VIDEO FAILURES],	
		1-p.YTB_B1_HD_Video4 as [YTB_V4 B1],
		p.YTB_B2_HD_Video4 as [YTB_V4 B2],
		p.YTB_STARTED_TERMINATED_HD_Video4 as [YTB_V4 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video4] as [YTB_V4 B2 %],
		p.YTB_B3_HD_Video4 as [YTB_V4 B3],

		'+@selectKM+'

		p.[ROUTE],
		p.PHONE_MODEL,
		p.FIRM_VERSION,
		p.HANDSET_CAPABILITY,
		p.TEST_MODALITY,
		p.LAST_ACQUISITION,
		p.Operador,
		P.MCC,
		p.MNC,
		p.OPCOS,
		p.RAN_VENDOR,
		p.SCENARIOS,
		p.PROVINCIA_DASH as PROVINCIA,
		p.CCAA_DASH as CCAA,
		case when p.id=''VDF'' then p.Zona_VDF else p.Zona_OSP end as ZONA,
		id,
		reportweek,
		monthyear

		
	from lcc_data_final p
	'+@cruceKM+'
	where p.SCOPE_DASH not like ''%ROUND%''
	and p.technology in (''4G'',''Road 4G'',''3G'')
		  and scope is not null

UNION ALL
	
	select 
		p.scope as SCOPE,
		''4G_CA_ONLY'' as TECHNOLOGY,
		''Y'' as CA_Y_N,
		p.SCOPE_DASH as [TARGET ON SCOPE],
		p.ENTITIES_DASHBOARD as [CITIES_ROUTE_LINES_PLACE],

		p.att_dl_ce as [DL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_ce as [DL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_ce as [DL_CE ERRORS IN RETAINABILITY],
		p.D1 as [DL_CE D1.DOWNLOAD SPEED],
		p.Desviacion_DL_CE as [DL_CE DESV],
		p.D2 as [DL_CE D2],
		p.Num_Thput_3M as [DL_CE NUMBER OF DL > 3 MBPS],
		p.Num_Thput_1M as [DL_CE NUMBER OF DL > 1 MBPS],
		p.Peak_Data_DL_CE as [DL_CE PEAK DATA USER RATE],
		p.Percentil10_DL_CE as [DL_CE 10TH PERCENTILE THR.],
		p.Percentil10_DL_CE_SCOPE as [DL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_CE_SCOPE_QLIK else null end as [DL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_CE as [DL_CE 90TH PERCENTILE THR.],
		p.Percentil90_DL_CE_SCOPE as [DL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_CE_SCOPE_QLIK else null end as [DL_CE 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_ce as [UL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_ce as [UL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_ce as [UL_CE ERRORS IN RETAINABILITY],
		p.D3 as [UL_CE D3.UPLOAD SPEED],
		p.Desviacion_UL_CE as [UL_CE THROUGHPUT DESV],
		p.Peak_Data_UL_CE as [UL_CE PEAK DATA USER RATE],
		p.Percentil10_UL_CE as [UL_CE 10TH PERCENTILE THR.],
		p.Percentil10_UL_CE_SCOPE as [UL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_CE_SCOPE_QLIK else null end as [UL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_CE as [UL_CE 90TH PERCENTILE THR.],
		p.Percentil90_UL_CE_SCOPE as [UL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_CE_SCOPE_QLIK else null end as [UL_CE 90TH PERCENTILE SCOPE_M_S],

		
		p.att_dl_nc as [DL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_nc as [DL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_nc as [DL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_DL_NC as [DL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_DL_NC as [DL_NC MEAN DATA USER RATE],
		p.Desviacion_DL_NC as [DL_NC DESV],
		p.Peak_Data_DL_NC as [DL_NC PEAK DATA USER RATE],
		p.Percentil10_DL_NC as [DL_NC 10TH PERCENTILE THR.],
		p.Percentil10_DL_NC_SCOPE as [DL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_NC_SCOPE_QLIK else null end as [DL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_NC as [DL_NC 90TH PERCENTILE THR.],
		p.Percentil90_DL_NC_SCOPE as [DL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_NC_SCOPE_QLIK else null end as [DL_NC 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_nc as [UL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_nc as [UL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_nc as [UL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_UL_NC as [UL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_UL_NC as [UL_NC MEAN DATA USER RATE],
		p.Desviacion_UL_NC as [UL_NC DESV],
		p.Peak_Data_UL_NC as [UL_NC PEAK DATA USER RATE],
		p.Percentil10_UL_NC as [UL_NC 10TH PERCENTILE THR.],
		p.Percentil10_UL_NC_SCOPE as [UL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_NC_SCOPE_QLIK else null end as [UL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_NC as [UL_NC 90TH PERCENTILE THR.],
		p.Percentil90_UL_NC_SCOPE as [UL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_NC_SCOPE_QLIK else null end as [UL_NC 90TH PERCENTILE SCOPE_M_S],

		p.Latency_Att as [PING NUMBER OF ATTEMPTS],
		p.PercentilPING as [PING MEDIAN],
		p.LAT_AVG as [PING AVG],
		p.Percentil_PING_SCOPE as [PING MEDIAN SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil_PING_SCOPE_QLIK else null end as [PING MEDIAN SCOPE_M_S],

		p.Web_Att as [WEB_HTTP ATTEMPTS],
		p.Web_Failed as [WEB_HTTP ACCESIBILITY],
		p.Web_Dropped as [WEB_HTTP RETAINABILITY],
		p.Web_SessionTime_D5 as [WEB_HTTP SESS],
		p.WEB_IP_ACCESS_TIME as [WEB_HTTP IP ACC],
		p.WEB_HTTP_TRANSFER_TIME as [WEB_HTTP TRANS],
		
		p.Web_https_Att as [WEB_HTTPS ATTEMPTS],
		p.Web_https_Failed as [WEB_HTTPS ACCESIBILITY],
		p.Web_https_Dropped as [WEB_HTTPS RETAINABILITY],
		p.[Web_SessionTime_HTTPS_D5] as [WEB_HTTPS SESS],
		p.WEB_IP_ACCESS_TIME_https as [WEB_HTTPS IP ACC],
		p.[WEB_HTTP_TRANSFER_TIME_HTTPS] as [WEB_HTTPS TRANS],
		
		'+@tabla_youtube+',
		
		p.YTB_B5_HD_Video2 as [YTB_V2 B5],
		p.YTB_B4_HD_Video2 as [YTB_V2 B4],
		p.YTB_B6_HD_Video2 as [YTB_V2 B6],
		p.Att_YTB_HD_Video2 as [YTB_V2 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video2 AS [YTB_V2 VIDEO START TIME],
		P.YTB_Fails_HD_Video2 as [YTB_V2 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video2 as [YTB_V2 B1],
		p.YTB_B2_HD_Video2 as [YTB_V2 B2],
		p.YTB_STARTED_TERMINATED_HD_Video2 as [YTB_V2 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video2] as [YTB_V2 B2 %],
		p.YTB_B3_HD_Video2 as [YTB_V2 B3],

		p.YTB_B5_HD_Video3 as [YTB_V3 B5],
		p.YTB_B4_HD_Video3 as [YTB_V3 B4],
		p.YTB_B6_HD_Video3 as [YTB_V3 B6],
		p.Att_YTB_HD_Video3 as [YTB_V3 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video3 AS [YTB_V3 VIDEO START TIME],
		P.YTB_Fails_HD_Video3 as [YTB_V3 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video3 as [YTB_V3 B1],
		p.YTB_B2_HD_Video3 as [YTB_V3 B2],
		p.YTB_STARTED_TERMINATED_HD_Video3 as [YTB_V3 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video3] as [YTB_V3 B2 %],
		p.YTB_B3_HD_Video3 as [YTB_V3 B3],

		p.YTB_B5_HD_Video4 as [YTB_V4 B5],
		p.YTB_B4_HD_Video4 as [YTB_V4 B4],
		p.YTB_B6_HD_Video4 as [YTB_V4 B6],
		p.Att_YTB_HD_Video4 as [YTB_V4 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video4 AS [YTB_V4 VIDEO START TIME],
		P.YTB_Fails_HD_Video4 as [YTB_V4 NUMBER OF VIDEO FAILURES],	
		1-p.YTB_B1_HD_Video4 as [YTB_V4 B1],
		p.YTB_B2_HD_Video4 as [YTB_V4 B2],
		p.YTB_STARTED_TERMINATED_HD_Video4 as [YTB_V4 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video4] as [YTB_V4 B2 %],
		p.YTB_B3_HD_Video4 as [YTB_V4 B3],

		'+@selectKM+'

		p.[ROUTE],
		p.PHONE_MODEL,
		p.FIRM_VERSION,
		p.HANDSET_CAPABILITY,
		p.TEST_MODALITY,
		p.LAST_ACQUISITION,
		p.Operador,
		P.MCC,
		p.MNC,
		p.OPCOS,
		p.RAN_VENDOR,
		p.SCENARIOS,
		p.PROVINCIA_DASH as PROVINCIA,
		p.CCAA_DASH as CCAA,
		case when p.id=''VDF'' then p.Zona_VDF else p.Zona_OSP end as ZONA,
		id,
		reportweek,
		monthyear
	
	
	from lcc_data_final p
	'+@cruceKM_CAOnly+'
	where p.SCOPE_DASH in (''MAIN CITIES'',''SMALLER CITIES'')
	and p.technology = (''4G_CA_Only'')

UNION ALL

select 
		p.scope as SCOPE,
		''4G_ONLY'' as TECHNOLOGY,
		''Y'' as CA_Y_N,
		p.SCOPE_DASH as [TARGET ON SCOPE],
		p.ENTITIES_DASHBOARD as [CITIES_ROUTE_LINES_PLACE],

		p.att_dl_ce as [DL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_ce as [DL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_ce as [DL_CE ERRORS IN RETAINABILITY],
		p.D1 as [DL_CE D1.DOWNLOAD SPEED],
		p.Desviacion_DL_CE as [DL_CE DESV],
		p.D2 as [DL_CE D2],
		p.Num_Thput_3M as [DL_CE NUMBER OF DL > 3 MBPS],
		p.Num_Thput_1M as [DL_CE NUMBER OF DL > 1 MBPS],
		p.Peak_Data_DL_CE as [DL_CE PEAK DATA USER RATE],
		p.Percentil10_DL_CE as [DL_CE 10TH PERCENTILE THR.],
		p.Percentil10_DL_CE_SCOPE as [DL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_CE_SCOPE_QLIK else null end as [DL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_CE as [DL_CE 90TH PERCENTILE THR.],
		p.Percentil90_DL_CE_SCOPE as [DL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_CE_SCOPE_QLIK else null end as [DL_CE 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_ce as [UL_CE NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_ce as [UL_CE ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_ce as [UL_CE ERRORS IN RETAINABILITY],
		p.D3 as [UL_CE D3.UPLOAD SPEED],
		p.Desviacion_UL_CE as [UL_CE THROUGHPUT DESV],
		p.Peak_Data_UL_CE as [UL_CE PEAK DATA USER RATE],
		p.Percentil10_UL_CE as [UL_CE 10TH PERCENTILE THR.],
		p.Percentil10_UL_CE_SCOPE as [UL_CE 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_CE_SCOPE_QLIK else null end as [UL_CE 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_CE as [UL_CE 90TH PERCENTILE THR.],
		p.Percentil90_UL_CE_SCOPE as [UL_CE 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_CE_SCOPE_QLIK else null end as [UL_CE 90TH PERCENTILE SCOPE_M_S],

		
		p.att_dl_nc as [DL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_dl_nc as [DL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_dl_nc as [DL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_DL_NC as [DL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_DL_NC as [DL_NC MEAN DATA USER RATE],
		p.Desviacion_DL_NC as [DL_NC DESV],
		p.Peak_Data_DL_NC as [DL_NC PEAK DATA USER RATE],
		p.Percentil10_DL_NC as [DL_NC 10TH PERCENTILE THR.],
		p.Percentil10_DL_NC_SCOPE as [DL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_DL_NC_SCOPE_QLIK else null end as [DL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_DL_NC as [DL_NC 90TH PERCENTILE THR.],
		p.Percentil90_DL_NC_SCOPE as [DL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_DL_NC_SCOPE_QLIK else null end as [DL_NC 90TH PERCENTILE SCOPE_M_S],

		p.att_ul_nc as [UL_NC NUMBER OF ATTEMPTS],
		p.Fails_acc_ul_nc as [UL_NC ERRORS IN ACCESIBILITY],
		p.Fails_ret_ul_nc as [UL_NC ERRORS IN RETAINABILITY],
		p.Sessions_Thput_384K_UL_NC as [UL_NC SESSIONS THPUT EXCEDEED 384KBPS],
		p.MEAN_DATA_USER_RATE_UL_NC as [UL_NC MEAN DATA USER RATE],
		p.Desviacion_UL_NC as [UL_NC DESV],
		p.Peak_Data_UL_NC as [UL_NC PEAK DATA USER RATE],
		p.Percentil10_UL_NC as [UL_NC 10TH PERCENTILE THR.],
		p.Percentil10_UL_NC_SCOPE as [UL_NC 10TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil10_UL_NC_SCOPE_QLIK else null end as [UL_NC 10TH PERCENTILE SCOPE_M_S],
		p.Percentil90_UL_NC as [UL_NC 90TH PERCENTILE THR.],
		p.Percentil90_UL_NC_SCOPE as [UL_NC 90TH PERCENTILE SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil90_UL_NC_SCOPE_QLIK else null end as [UL_NC 90TH PERCENTILE SCOPE_M_S],

		p.Latency_Att as [PING NUMBER OF ATTEMPTS],
		p.PercentilPING as [PING MEDIAN],
		p.LAT_AVG as [PING AVG],
		p.Percentil_PING_SCOPE as [PING MEDIAN SCOPE],
		CASE WHEN p.scope_DASH in (''MAIN CITIES'',''SMALLER CITIES'') then p.Percentil_PING_SCOPE_QLIK else null end as [PING MEDIAN SCOPE_M_S],

		p.Web_Att as [WEB_HTTP ATTEMPTS],
		p.Web_Failed as [WEB_HTTP ACCESIBILITY],
		p.Web_Dropped as [WEB_HTTP RETAINABILITY],
		p.Web_SessionTime_D5 as [WEB_HTTP SESS],
		p.WEB_IP_ACCESS_TIME as [WEB_HTTP IP ACC],
		p.WEB_HTTP_TRANSFER_TIME as [WEB_HTTP TRANS],
		
		p.Web_https_Att as [WEB_HTTPS ATTEMPTS],
		p.Web_https_Failed as [WEB_HTTPS ACCESIBILITY],
		p.Web_https_Dropped as [WEB_HTTPS RETAINABILITY],
		p.[Web_SessionTime_HTTPS_D5] as [WEB_HTTPS SESS],
		p.WEB_IP_ACCESS_TIME_https as [WEB_HTTPS IP ACC],
		p.[WEB_HTTP_TRANSFER_TIME_HTTPS] as [WEB_HTTPS TRANS],
		
		'+@tabla_youtube+',
		
		p.YTB_B5_HD_Video2 as [YTB_V2 B5],
		p.YTB_B4_HD_Video2 as [YTB_V2 B4],
		p.YTB_B6_HD_Video2 as [YTB_V2 B6],
		p.Att_YTB_HD_Video2 as [YTB_V2 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video2 AS [YTB_V2 VIDEO START TIME],
		P.YTB_Fails_HD_Video2 as [YTB_V2 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video2 as [YTB_V2 B1],
		p.YTB_B2_HD_Video2 as [YTB_V2 B2],
		p.YTB_STARTED_TERMINATED_HD_Video2 as [YTB_V2 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video2] as [YTB_V2 B2 %],
		p.YTB_B3_HD_Video2 as [YTB_V2 B3],

		p.YTB_B5_HD_Video3 as [YTB_V3 B5],
		p.YTB_B4_HD_Video3 as [YTB_V3 B4],
		p.YTB_B6_HD_Video3 as [YTB_V3 B6],
		p.Att_YTB_HD_Video3 as [YTB_V3 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video3 AS [YTB_V3 VIDEO START TIME],
		P.YTB_Fails_HD_Video3 as [YTB_V3 NUMBER OF VIDEO FAILURES],
		1-p.YTB_B1_HD_Video3 as [YTB_V3 B1],
		p.YTB_B2_HD_Video3 as [YTB_V3 B2],
		p.YTB_STARTED_TERMINATED_HD_Video3 as [YTB_V3 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video3] as [YTB_V3 B2 %],
		p.YTB_B3_HD_Video3 as [YTB_V3 B3],

		p.YTB_B5_HD_Video4 as [YTB_V4 B5],
		p.YTB_B4_HD_Video4 as [YTB_V4 B4],
		p.YTB_B6_HD_Video4 as [YTB_V4 B6],
		p.Att_YTB_HD_Video4 as [YTB_V4 NUMBER OF VIDEO ACCESS ATTEMPTS],
		P.YTB_AVG_START_TIME_Video4 AS [YTB_V4 VIDEO START TIME],
		P.YTB_Fails_HD_Video4 as [YTB_V4 NUMBER OF VIDEO FAILURES],	
		1-p.YTB_B1_HD_Video4 as [YTB_V4 B1],
		p.YTB_B2_HD_Video4 as [YTB_V4 B2],
		p.YTB_STARTED_TERMINATED_HD_Video4 as [YTB_V4 VIDEOS START_TERM IN HD],
		p.[YTB_B2_HD_%_Video4] as [YTB_V4 B2 %],
		p.YTB_B3_HD_Video4 as [YTB_V4 B3],

		'+@selectKM+'

		p.[ROUTE],
		p.PHONE_MODEL,
		p.FIRM_VERSION,
		p.HANDSET_CAPABILITY,
		p.TEST_MODALITY,
		p.LAST_ACQUISITION,
		p.Operador,
		P.MCC,
		p.MNC,
		p.OPCOS,
		p.RAN_VENDOR,
		p.SCENARIOS,
		p.PROVINCIA_DASH as PROVINCIA,
		p.CCAA_DASH as CCAA,
		case when p.id=''VDF'' then p.Zona_VDF else p.Zona_OSP end as ZONA,
		id,
		reportweek,
		monthyear
	
	from lcc_data_final p
	'+@cruceKM_4GOnly+'
	where p.SCOPE_DASH not in (''MAIN CITIES'',''SMALLER CITIES'')
	and p.technology IN (''4GOnly'',''Road 4GOnly'')
		  and scope is not null ) dash
	
')


-- Rellenamos la tabla de Qlik
------------------------------

print ('Rellenamos la tabla de Qlik')


exec('

if (select name from qlik.sys.tables where name=''lcc_data_final_qlik'') is not null
 BEGIN
	If(Select MonthYear+ReportWeek+id from [QLIK].[dbo].lcc_data_final_qlik where MonthYear+ReportWeek+id = '''+@monthYear+''' + '''+@ReportWeek+''' + '''+@id+''' group by MonthYear+ReportWeek+id)<> ''''
	BEGIN

	   delete from [QLIK].[dbo].lcc_data_final_qlik where MonthYear = '''+@monthYear+''' and ReportWeek = '''+@ReportWeek+''' and id = '''+@id+'''
	END
 
 END 

	insert into [QLIK].[dbo].lcc_data_final_qlik
	Select  SCOPE_QLIK as Scope_Rest,
			Operador as Operator,
			Technology as meas_tech,
			ENTIDAD as entity,
			final_date,
			id,
			Att_DL_CE,
			Fails_Acc_DL_CE,
			Fails_Ret_DL_CE,
			D1,
			D2,
			Num_Thput_3M,
			Num_Thput_1M,
			SessionTime_DL_CE,
			Att_UL_CE,
			Fails_Acc_UL_CE,
			Fails_Ret_UL_CE,
			D3,
			SessionTime_UL_CE,
			Att_DL_NC,
			Fails_Acc_DL_NC,
			Fails_Ret_DL_NC,
			MEAN_DATA_USER_RATE_DL_NC,
			Att_UL_NC,
			Fails_Acc_UL_NC,
			Fails_Ret_UL_NC,
			MEAN_DATA_USER_RATE_UL_NC,
			Latency_Att,
			LAT_AVG,
			0 as LAT_MED,
			0 as LAT_D4,
			0 as LAT_MEDIAN,
			Web_Att,
			Web_Failed,
			Web_Dropped,
			Web_SessionTime_D5,
			WEB_IP_ACCESS_TIME,
			WEB_HTTP_TRANSFER_TIME,
			Web_HTTPS_Att,
			Web_HTTPS_Failed,
			Web_HTTPS_Dropped,
			Web_SessionTime_HTTPS_D5,
			WEB_IP_ACCESS_TIME_HTTPS,
			WEB_HTTP_TRANSFER_TIME_HTTPS,
			Web_Public_Att,
			Web_Public_Failed,
			Web_Public_Dropped,
			Web_SessionTime_Public_D5,
			WEB_IP_ACCESS_TIME_Public,
			WEB_HTTP_TRANSFER_TIME_Public,
			Att_YTB_SD,
			YTB_Fails_SD,
			YTB_Dropped_SD,
			YTB_B1_SD,
			YTB_B2_SD,
			Att_YTB_HD,
			YTB_Fails_HD,
			YTB_Dropped_HD,
			YTB_B1_HD,
			YTB_AVG_START_TIME,
			YTB_B2_HD,
			[YTB_B2_HD_%],
			YTB_B3_HD,
			YTB_B5_HD,
			YTB_B4_HD,
			YTB_B6_HD,
			Zona_OSP,
			Zona_VDF,
			PROVINCIA_DASH as Provincia_comp,
			Population,
			MonthYear,
			ReportWeek,
			Percentil10_DL_CE,
			Percentil90_DL_CE,
			Percentil10_UL_CE,
			Percentil90_UL_CE,
			Percentil10_DL_NC,
			Percentil90_DL_NC,
			Percentil10_UL_NC,
			Percentil90_UL_NC,
			PercentilPING,
			Percentil10_DL_CE_SCOPE,
			Percentil90_DL_CE_SCOPE,
			Percentil10_UL_CE_SCOPE,
			Percentil90_UL_CE_SCOPE,
			Percentil10_DL_NC_SCOPE,
			Percentil90_DL_NC_SCOPE,
			Percentil10_UL_NC_SCOPE,
			Percentil90_UL_NC_SCOPE,
			Percentil_PING_SCOPE,
			Percentil10_DL_CE_SCOPE_QLIK,
			Percentil90_DL_CE_SCOPE_QLIK,
			Percentil10_UL_CE_SCOPE_QLIK,
			Percentil90_UL_CE_SCOPE_QLIK,
			Percentil10_DL_NC_SCOPE_QLIK,
			Percentil90_DL_NC_SCOPE_QLIK,
			Percentil10_UL_NC_SCOPE_QLIK,
			Percentil90_UL_NC_SCOPE_QLIK,
			Percentil_PING_SCOPE_QLIK,
			Case When SCOPE_QLIK in (''Main Cities'', ''Smaller Cities'') then ''BIG CITIES''
				 When SCOPE_QLIK in (''ADD-ON CITIES'', ''TOURISTIC AREA'') then ''SMALL CITIES''
				 When SCOPE_QLIK = ''MAIN HIGHWAYS'' and Technology = ''Road 4G_1'' then ''ROADS'' end as SCOPE_QLIK

	from lcc_data_final

')
--------------------

insert into [dbo].[_Actualizacion_QLIK_DASH]
select 'Fin ejecución procedimiento Dashboard QLIK Datos', getdate()

--select 'Acabado con éxito'

--print('FIN')

						
--SELECT * FROM lcc_data_final_dashboard

--select * from lcc_data_final_dashboard where [Target on scope] = 'Railways'
--select *from addedValue.[dbo].[lcc_entities_completed_Report]  where entity_name like '%ave%'

--SELECT * FROM lcc_Data_final_Q

