USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_MAIN_DATA]    Script Date: 29/05/2017 14:10:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_DashBoard_MAIN_DATA] 
	@la bit -- Si se desean eliminar las parcelas pertenicentes a las LA del agregado -->> @la=1 (DASHBOARD MAIN&SMALLER SOLO)
							--	 si no @la=0 (DASHBOARD COMPLETO)
	,@RW_Road int		-- RW para las carreteras = número de rondas a tener en cuenta para el acumulado
	,@RW_Railway int	-- RW para los AVE = número de rondas a tener en cuenta para el acumulado
	,@database as varchar(256)  -- BBDD con la información agregada
	,@UpdateMeasur as bit	-- Si se desea hacer el update de las medidas invalidadas --> @UpdateMeasur=1 si no, la correspondiente medida saldrá a null
	,@Methodology as varchar(50)
as

--declare @la bit = 1
--declare @RW_Road int = 5		
--declare @RW_Railway int	= 3
--declare @database as varchar(256)  ='[AGGRDATA4G]'
--declare @UpdateMeasur as bit = 1
-------------------------------------------------------------------------------
-- 1.- Declaración de variables
declare @nameSheet as varchar(256)
declare @database_table as varchar(256)
declare @sheetTech as varchar(256)
declare @typeMeasur as varchar(256)
declare @scope as varchar(256)
declare @table as varchar(256)
declare @statistics as bit 
declare @it bigint
declare @nameS as varchar (256)
declare @SQLString as varchar (4000)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 2.- Ejecución de los procedimientos para datos
-- 2.1.- Bucle para generar todas las tablas con toda la información de datos
set @it = 1
while (@it <= (SELECT max(convert(int,[order])) FROM [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where [TYPE_TABLE]='DATA'))
begin
	set @database_Table = (select [DATABASE] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='DATA')
	set @nameSheet =(select [SHEET] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='DATA')
	
	if @database = @database_Table
	begin
		---------------------------------------------------------------------------
		-- Creación del campo entidad (por ahora del collectionName, a posteriori por geolocalización con lcc_parcelas)
		-- Se generan primero todas las tablas y después se hacen las modificaciones oportunas para carreteras, AVE y update de medidas invalidadas
		print 'BUCLE1: '+ @database+' '+@nameSheet
		exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR] @database,@nameSheet
	end
	set @it=@it+1
end

-- 2.2.- Bucle para realizar las modificaciones necesarias sobre las tablas como adaptaciones de rondas. 
-- Además se generan las tablas calculadas por entidad y medida agrupadas por parcela
set @it = 1
while (@it <= (SELECT max(convert(int,[order])) FROM [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where [TYPE_TABLE]='DATA'))
begin
	set @database_Table = (select [DATABASE] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='DATA')
	set @nameSheet =(select [SHEET] from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES where convert(int,[order]) = @it and [TYPE_TABLE]='DATA')
	
	if @database = @database_Table
	begin
		---------------------------------------------------------------------------
		-- Las entidades del tipo ROAD necesitan de un pretrado ya que se agregan varias rondas para obtener el resultado final
		-- se encuentran en la bbdd de carreteras
		if @database like '%ROAD%' and @LA=0
			begin
				exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE] @database,@RW_Road,'ROAD',@nameSheet,@UpdateMeasur
				exec [dbo].[sp_lcc_create_DashBoard_DATA_TABLES] @database,@nameSheet,1,@LA,@Methodology
			end
	
		else if @database not like '%ROAD%'
			begin
				-- El resto de entidades no necesita ese pretratado
					print 'BUCLE2 A: '+ @database+' '+@nameSheet+' '+convert(varchar,@LA)+' '+@Methodology
					exec [dbo].[sp_lcc_create_DashBoard_DATA_TABLES] @database,@nameSheet,1,@LA,@Methodology
				-- Las entidades del tipo RAILWAY también necesitan de un pretrado ya que se agregan varias rondas para obtener el resultado final
				-- pero se encuentran en la bbdd normal
				if @nameSheet in ('4G','4G_ONLY') and @LA=0
					begin
						print 'BUCLE2 B: '+ @database+' '+convert(varchar,@RW_Railway)+' '+@nameSheet+' '+convert(varchar,@UpdateMeasur)
						exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE] @database,@RW_Railway,'RAILWAY',@nameSheet,@UpdateMeasur
						set @nameS= @nameSheet + '_RAILWAY'
						print 'BUCLE2 C: '+ @database+' '+@nameS+' '+convert(varchar,@LA)+' '+@Methodology	
						exec [dbo].[sp_lcc_create_DashBoard_DATA_TABLES] @database,@nameS,1,@LA,@Methodology
					end
			end
		---------------------------------------------------------------------------
	end
	set @it=@it+1
end
---------------------------------------------------------------------------
select 'Acabado con éxito'
