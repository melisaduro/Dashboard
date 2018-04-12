USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_MAIN_VOLTE]    Script Date: 29/05/2017 14:11:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_DashBoard_MAIN_VOLTE] 
	@la bit -- Si se desean eliminar las parcelas pertenicentes a las LA del agregado -->> @la=1 (DASHBOARD MAIN&SMALLER SOLO)
							--	 si no @la=0 (DASHBOARD COMPLETO)
	,@RW_Road int		-- RW para las carreteras = número de rondas a tener en cuenta para el acumulado
	,@RW_Railway int	-- RW para los AVE = número de rondas a tener en cuenta para el acumulado
	,@database as varchar(256)  -- BBDD con la información agregada
	,@UpdateMeasur as bit	-- Si se desea hacer el update de las medidas invalidadas --> @UpdateMeasur=1
							-- si no, la correspondiente medida saldrá a null
	,@report as varchar(256)
as

--declare @la bit = 1
--declare @RW_Road int = 5		
--declare @RW_Railway int	= 3
--declare @database as varchar(256)  ='[AGGRvoice3G]'

-------------------------------------------------------------------------------
-- 1.- Declaración de variables

declare @sheetTech as varchar(256)
declare @typeMeasur as varchar(256)
declare @scope as varchar(256)
declare @table as varchar(256)
declare @statistics as bit 
declare @it bigint
declare @nameS as varchar (256)
declare @SQLString as varchar (4000)
declare @database_Table as varchar(256)
declare @nameSheet as varchar(256)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 2.- Ejecución de los procedimientos para voz
-- 2.1.- Bucle para generar todas las tablas con toda la información de voz
set @it = 1
while (@it <= (SELECT max(convert(int,[order])) FROM [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where [TYPE_TABLE]='VOLTE'))
begin
	set @database_Table = (select [DATABASE] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='VOLTE')
	set @nameSheet =(select [SHEET] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='VOLTE')
	
	if @database = @database_Table
	begin
		---------------------------------------------------------------------------
		-- Creación del campo entidad (por ahora del collectionName, a posteriori por geolocalización con lcc_parcelas)
		-- Se generan primero todas las tablas y después se hacen las modificaciones oportunas para carreteras, AVE y update de medidas invalidadas
		exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR_NEW_Report] @database,@nameSheet,@report
	end
	set @it=@it+1
end

-- 2.2.- Bucle para realizar las modificaciones necesarias sobre las tablas como adaptaciones de rondas. 
-- Además se generan las tablas calculadas por entidad y medida agrupadas por parcela
set @it = 1
while (@it <= (SELECT max(convert(int,[order])) FROM [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where [TYPE_TABLE]='VOLTE'))
begin
	set @database_Table = (select [DATABASE] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='VOLTE')
	set @nameSheet =(select [SHEET] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='VOLTE')
	
	if @database = @database_Table
	begin		
	
			
		-- El resto de entidades no necesita ese pretratado
		exec [dbo].[sp_lcc_create_DashBoard_VOICE_TABLES] @database,@nameSheet,@LA
		-- Las entidades del tipo ROAD también necesitan de un pretrado ya que se agregan varias rondas para obtener el resultado final
		-- pero se encuentran en la bbdd normal
			if @nameSheet in ('4G','VOLTE') and @LA = 0
				begin	
					exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_NEW_Report] @database,@RW_Road,'ROAD',@nameSheet,@UpdateMeasur,@report
					set @nameS = @nameSheet + '_ROAD'
					exec [dbo].[sp_lcc_create_DashBoard_VOICE_TABLES] @database,@nameS,@LA
				end
			
		---------------------------------------------------------------------------
	end
	set @it=@it+1
end

-------------------------------------------------------------------------------
select 'Acabado con éxito'