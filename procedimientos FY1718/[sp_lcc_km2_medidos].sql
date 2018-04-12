USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_km2_medidos]    Script Date: 12/04/2018 10:21:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************************

+++ Procedimiento que calcula la cantidad de parcelas que medimos, el área cubierta +++
+++ y el porcentaje medido con respecto al total de la entidad						+++

****************************************************************************************/


ALTER procedure [dbo].[sp_lcc_km2_medidos] (
	@sheetTech as varchar (256),
	@report as varchar(256)
)
as

-- --Definición de variables
--declare @sheetTech as varchar (256)='4G'
--declare @report as varchar(256)='VDF'


DECLARE @SQLString nvarchar(4000)
declare @tabla_reporte as varchar (500)
declare @database as varchar (500)
declare @databaseVoice as varchar (500)
declare @databaseVoiceFY1718 as varchar (500)
declare @tech as varchar (500)

if @sheetTech in ('4GOnly')
begin 
	set @database='AGGRData4G'
	set @databaseVoice='AGGRVoice4G' 
	set @databaseVoiceFY1718='AGGRVOLTE' 
	set @tech='4G_ONLY'
end
if @sheetTech in ('4G')
begin 
	set @database='AGGRData4G'
	set @databaseVoice='AGGRVoice4G' 
	set @databaseVoiceFY1718='AGGRVOLTE' 
	set @tech='4G'
end
if @sheetTech in ('4G_CA_Only')
begin 
	set @database='AGGRData4G'
	set @databaseVoice='AGGRVoice4G' 
	set @databaseVoiceFY1718='AGGRVOLTE' 
	set @tech='4G_CA_ONLY'
end
if @sheetTech ='3G'
begin 
	set @database='AGGRData3G'
	set @databaseVoice='AGGRVoice3G' 
	set @databaseVoiceFY1718='AGGRVoice4G' 
	set @tech='3G'
end


-- Para introducir el procedimiento el todas las BBDD del sistema
--exec sp_ms_marksystemobject sp_lcc_km2_medidos

-- Borra la tabla donde almacenamos los datos en el caso de que exista
--exec FY1617_TEST_CECI.dbo.sp_lcc_dropifexists 'lcc_km2_chequeo_mallado'
exec AddedValue.dbo.sp_lcc_dropifexists 'lcc_km2_medidos'
exec AddedValue.dbo.sp_lcc_dropifexists 'lcc_km2_totales'

if (select name from sys.tables where name='lcc_km2_chequeo_mallado') is null
begin
CREATE TABLE [dbo].[lcc_km2_chequeo_mallado](
	[Entidad] [varchar](256) NULL,
	[date_reporting] [varchar](256) NULL,
	[Parcelas] [int] NULL,
	[Area(km2)] [numeric](13, 2) NULL,
	[tech] [varchar](10) NOT NULL,
	[techVoice] [varchar](10) NOT NULL,
	[Porcentaje_medido] [numeric](28, 12) NULL,
	[total_parcelas] [int] NULL,
	[AreaTotal(km2)] [numeric](13, 2) NULL,
	[Report_Type] [varchar](256) NULL
)
end

-- Sacamos el total de las parcelas para cada entidad
if @report='VDF'
	begin
		SET @SQLString =N'
						select  a.Entidad_contenedora,
						count(a.nombre) as total_parcelas,
						count(a.Entidad_contenedora)*0.25 as [AreaTotal(km2)]
						into lcc_km2_totales
						from  Dashboard.dbo.lcc_parcelas_VDF_NEW a
						group by a.entidad_contenedora'
		--PRINT @SQLString
		EXECUTE sp_executesql @SQLString
		
		set @tabla_reporte='Dashboard.dbo.lcc_parcelas_VDF_NEW'
	end

if @report='OSP'
	begin
		SET @SQLString =N'
						select  a.Entidad_contenedora,
						count(a.nombre) as total_parcelas,
						count(a.Entidad_contenedora)*0.25 as [AreaTotal(km2)]
						into lcc_km2_totales
						from  Dashboard.dbo.lcc_parcelas_OSP_NEW a
						group by a.entidad_contenedora'
		--PRINT @SQLString
		EXECUTE sp_executesql @SQLString
		set @tabla_reporte='Dashboard.dbo.lcc_parcelas_OSP_NEW'
	end

-- Calculamos las parcelas y el area que medimos de cada entidad

if @report='OSP'
begin
	set @report='MUN'
end


SET @SQLString =N'
select
	a.entidad,
	count(a.entidad) as Parcelas,
	count(a.entidad)*0.25 as [Area(km2)],
	a.date_reporting	
	,'''+@tech+''' as tech	
	, case when meas_round like ''FY1718%'' and '''+@tech+''' =''3G'' then ''4G'' 
		when meas_round like ''FY1718%'' and '''+@tech+''' =''4G'' then ''VOLTE''
		else '''+@tech+''' end as techVoice	
into lcc_km2_medidos
from(
	select a.parcel, a.date_reporting, a.entidad,meas_round
	from 
		(select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_DL_Thput_CE
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		Union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_DL_Thput_NC
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		Union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_Ping
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		Union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_UL_Thput_CE
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_UL_Thput_NC
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_Web
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_Youtube
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@database+'.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD
			where Report_Type = '''+@report+'''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@databaseVoice+'.dbo.lcc_aggr_sp_MDD_Voice_Llamadas
			where Report_Type = '''+@report+'''
				and meas_round not like ''FY1718%''
			group by parcel,date_reporting,entidad,meas_round
		union all
			select parcel,date_reporting,entidad,meas_round
			from '+@databaseVoiceFY1718+'.dbo.lcc_aggr_sp_MDD_Voice_Llamadas
			where Report_Type = '''+@report+'''
				and meas_round like ''FY1718%''
			group by parcel,date_reporting,entidad,meas_round

		) a
		, '+@tabla_reporte+' p
	where a.parcel=p.nombre and a.entidad=p.entidad_contenedora
	group by parcel,date_reporting,entidad,meas_round
	) a
group by a.entidad,a.date_reporting,a.meas_round'


--PRINT @SQLString
EXECUTE sp_executesql @SQLString

----Cruzamos las tablas de las parcelas que medimos con las totales para sacar los porcentajes
insert into lcc_km2_chequeo_mallado
select m.Entidad,
	m.date_reporting,
	m.Parcelas,
	m.[Area(km2)],
	m.tech,
	m.techVoice,
	(m.Parcelas*1.0/t.total_parcelas)*100 as [Porcentaje_medido],
	t.total_parcelas,
	t.[AreaTotal(km2)],
	@report
from
lcc_km2_medidos m, lcc_km2_totales t
where m.Entidad = t.Entidad_contenedora

-- Borramos las tablas temporales
drop table lcc_km2_medidos,lcc_km2_totales




