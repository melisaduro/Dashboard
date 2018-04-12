USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_MAIN_CLEAN]    Script Date: 29/05/2017 14:10:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_DashBoard_MAIN_CLEAN] (
	@LA as integer,
	@tech as varchar(256)
)as

-------------------------------------------------------------------------------
if @LA= 0 and (@tech = 'DATA' or @tech = 'BOTH')
begin
	exec [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_road','ROAD'
	exec [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_ONLY_road','ROAD'
	exec [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE] '[DASHBOARD]','4G','RAILWAY'
	exec [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_ONLY','RAILWAY'
end

if @LA=0 and (@tech = 'VOICE' or @tech = 'BOTH')
begin
	exec [dbo].[sp_lcc_create_DashBoard_VOICE_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_road','ROAD'
	exec [dbo].[sp_lcc_create_DashBoard_VOICE_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_ONLY_road','ROAD'
	exec [dbo].[sp_lcc_create_DashBoard_VOICE_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_road','RAILWAY'
	exec [dbo].[sp_lcc_create_DashBoard_VOICE_CLEAN_TABLES_PRE] '[DASHBOARD]','4G_ONLY_road','RAILWAY'
end

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales 
-------------------------------------------------------------------------------
declare @it int
declare @table as varchar (256)
declare @SQLString as nvarchar (4000)

-------------------------------------------------------------------------------
-- Selección de las tablas a borrar --> Tablas intermedias para incluir correctamente el nombre de la entidad

exec sp_lcc_dropifexists '_tmp_Tablas'
select IDENTITY(int,1,1) id,name
into _tmp_Tablas 
from [DASHBOARD].sys.tables
where name like 'UPDATE_AGGR%'
order by name

-------------------------------------------------------------------------------
-- Borrado de las tablas anteriores

set @it=1
while (@it <= (SELECT max(convert(int,id)) FROM _tmp_Tablas))
begin
	set @table = (select name FROM _tmp_Tablas where convert(int,id)=@it)
	SET @SQLString=	N' 	exec dashboard.dbo.sp_lcc_dropifexists '''+@table+''' '
	EXECUTE sp_executesql @SQLString

	set @it=@it+1
end

-------------------------------------------------------------------------------
-- Selección de las tablas a borrar --> Tablas temporales para obtener las distintas pestañas del dashboard
--  y tablas temporales de cálculo de estadísticos

exec sp_lcc_dropifexists '_tmp_Tablas'
select IDENTITY(int,1,1) id,name
into _tmp_Tablas 
from [DASHBOARD].sys.tables
where (name like '%_temp' or name like '%statistics%' or name like '%STDV%' or name like '%PERCENTIL%' 
		or name like '%KPIs_noValid%') and name not like '%result%'
order by name

-------------------------------------------------------------------------------
-- Borrado de las tablas anteriores

set @it=1
while (@it <= (SELECT max(convert(int,id)) FROM _tmp_Tablas))
begin
	set @table = (select name FROM _tmp_Tablas where convert(int,id)=@it)
	SET @SQLString=	N' 	exec dashboard.dbo.sp_lcc_dropifexists '''+@table+''' '
	EXECUTE sp_executesql @SQLString

	set @it=@it+1
end

drop table _tmp_Tablas
-------------------------------------------------------------------------------

select 'Acabado con éxito'